import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({Key? key, required this.date}) : super(key: key);
  final DateTime date;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  static const Color greenColor = Color(0xFF58B40B);
  static const Color coinColor = Color(0xFFFF9800);
  static const double goalCalories = 1851;
  static const double goalCarbs = 231;
  static const double goalProtein = 93;
  static const double goalFat = 62;
  static const double goalWater = 2000;

  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _weekData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData().then((_) => _autoClaimRewards());
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _loadData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        _data = Map<String, dynamic>.from(userDoc.data()!);
      }
      
      if (!_data.containsKey('coins') && !_data.containsKey('challengeCoins')) {
        _data['coins'] = 0;
      }
      
      final diaryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('diary');
      final dateStr = DateFormat('d-M-y').format(widget.date);
      final todayDoc = await diaryRef.doc(dateStr).get();
      if (todayDoc.exists) {
        final todayData = Map<String, dynamic>.from(todayDoc.data()!);
        _data.addAll(todayData);
      }
      
      final startOfWeek = widget.date.subtract(Duration(days: widget.date.weekday - DateTime.monday));
      final weekDocs = await Future.wait(
        List.generate(7, (index) {
          final day = startOfWeek.add(Duration(days: index));
          final dayStr = DateFormat('d-M-y').format(day);
          return diaryRef.doc(dayStr).get();
        }),
      );
      _weekData = weekDocs.where((doc) => doc.exists).map((doc) => Map<String, dynamic>.from(doc.data()!)).toList();
    } catch (e) {
      debugPrint('Error loading challenge data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _autoClaimRewards() async {
    if (_isLoading) return;
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final completedTasks = _data['completedTasks'] is List ? List<String>.from(_data['completedTasks']) : <String>[];
      final completedWeeklyTasks = _data['completedWeeklyTasks'] is List ? List<String>.from(_data['completedWeeklyTasks']) : <String>[];
      final updates = <String, dynamic>{};

      final dailyTasks = _dailyTasks();
      final weeklyTasks = _weeklyTasks();

      for (final task in [...dailyTasks, ...weeklyTasks]) {
        if (task.taskKey == null || task.reward == null) continue;
        if (task.completed && !completedTasks.contains(task.taskKey) && !completedWeeklyTasks.contains(task.taskKey)) {
          final isWeekly = task.taskKey!.startsWith('weekly_');
          updates[isWeekly ? 'completedWeeklyTasks' : 'completedTasks'] = FieldValue.arrayUnion([task.taskKey!]);
          updates['coins'] = FieldValue.increment(task.reward!);
          debugPrint('Auto claiming ${task.reward} coin for ${task.title}');
        }
      }

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(updates, SetOptions(merge: true));
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error auto claiming rewards: $e');
    }
  }

  int get _coinBalance => _toDouble(_data['coins'] ?? _data['challengeCoins'] ?? 0).toInt();

  double _numFrom(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _toDouble(data[key]);
      if (value > 0) return value;
    }
    return 0;
  }

  bool _hasFoods(dynamic mealData) {
    if (mealData == null) return false;
    if (mealData is List) return mealData.isNotEmpty;
    if (mealData is Map) {
      final foods = mealData['foods'];
      final items = mealData['items'];
      if (foods is List && foods.isNotEmpty) return true;
      if (items is List && items.isNotEmpty) return true;
      final calories = _toDouble(mealData['totalCalories'] ?? mealData['calories'] ?? mealData['kcal']);
      return calories > 0;
    }
    return false;
  }

  dynamic _firstMealData(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) return data[key];
    }
    return null;
  }

  int _mealCount(Map<String, dynamic> data) {
    final mealGroups = [
      ['breakfast', 'Breakfast', 'buaSang'],
      ['lunch', 'Lunch', 'buaTrua'],
      ['dinner', 'Dinner', 'buaToi'],
    ];
    int count = 0;
    for (final group in mealGroups) {
      final mealData = _firstMealData(data, group);
      if (_hasFoods(mealData)) count++;
    }
    return count;
  }

  bool _isCalorieTargetDay(Map<String, dynamic> data) {
    final cal = _numFrom(data, ['totalCalories', 'calories', 'kcal']);
    return cal >= goalCalories * 0.9 && cal <= goalCalories * 1.2;
  }

  bool _isWaterTargetDay(Map<String, dynamic> data) {
    final water = _numFrom(data, ['totalWater', 'water']);
    return water >= goalWater;
  }

  bool _isProteinTargetDay(Map<String, dynamic> data) {
    final protein = _numFrom(data, ['totalProtein', 'protein']);
    return protein >= goalProtein * 0.7;
  }

  bool _isTrackedDay(Map<String, dynamic> data) => _mealCount(data) > 0;

  int _hoursLeftToday() {
    final now = DateTime.now();
    final isToday = now.year == widget.date.year && now.month == widget.date.month && now.day == widget.date.day;
    if (!isToday) return 0;
    final endOfDay = DateTime(now.year, now.month, now.day + 1);
    return endOfDay.difference(now).inHours.clamp(0, 24);
  }

  int _daysLeftInWeek() => (DateTime.sunday - widget.date.weekday).clamp(0, 6);

  List<_ChallengeTask> _dailyTasks() {
    final totalCal = _numFrom(_data, ['totalCalories', 'calories', 'kcal']);
    final meals = _mealCount(_data);
    final mealsGrouped = _calculateMindfulMeals();
    final calorieTarget90 = goalCalories * 0.9;
    final completedTasks = _data['completedTasks'] is List ? List<String>.from(_data['completedTasks']) : <String>[];

    return [
      _ChallengeTask(title: 'Bắt đầu mới', subtitle: 'Ghi nhận bữa ăn đầu tiên', icon: Icons.wb_sunny_rounded, current: meals > 0 ? 1 : 0, target: 1, reward: null, showProgress: false, taskKey: 'start_day'),
      _ChallengeTask(title: 'Duy trì đều đặn', subtitle: 'Ghi nhận 3 bữa ăn', icon: Icons.restaurant_rounded, current: meals.toDouble(), target: 3, reward: completedTasks.contains('daily_meals') ? null : 5, showProgress: true, taskKey: 'daily_meals'),
      _ChallengeTask(title: 'Cân bằng calo', subtitle: 'Đạt 90% mục tiêu calo', icon: Icons.bolt_rounded, current: totalCal, target: calorieTarget90, reward: completedTasks.contains('daily_calories') ? null : 10, showProgress: true, taskKey: 'daily_calories'),
      _ChallengeTask(title: 'Ăn uống chánh niệm', subtitle: 'Bữa ăn chánh niệm', icon: Icons.spa_rounded, current: mealsGrouped.toDouble(), target: 3, reward: completedTasks.contains('daily_mindful') ? null : 10, showProgress: true, taskKey: 'daily_mindful'),
    ];
  }

  int _calculateMindfulMeals() {
    final mealGroups = [['breakfast', 'Breakfast', 'buaSang'], ['lunch', 'Lunch', 'buaTrua'], ['dinner', 'Dinner', 'buaToi']];
    int count = 0;
    for (final group in mealGroups) {
      final mealData = _firstMealData(_data, group);
      if (_hasFoods(mealData)) count++;
    }
    return count;
  }

  List<_ChallengeTask> _weeklyTasks() {
    final calorieDays = _weekData.where(_isCalorieTargetDay).length;
    final waterDays = _weekData.where(_isWaterTargetDay).length;
    final trackedDays = _weekData.where(_isTrackedDay).length;
    final proteinDays = _weekData.where(_isProteinTargetDay).length;
    final completedTasks = _data['completedWeeklyTasks'] is List ? List<String>.from(_data['completedWeeklyTasks']) : <String>[];

    return [
      _ChallengeTask(title: 'Kiểm soát calo', subtitle: '5 ngày đạt calo', icon: Icons.bolt_rounded, current: calorieDays.toDouble(), target: 5, reward: completedTasks.contains('weekly_calories') ? null : 50, showProgress: true, taskKey: 'weekly_calories'),
      _ChallengeTask(title: 'Anh hùng hydrat hóa', subtitle: '5 ngày uống nước', icon: Icons.water_drop_rounded, current: waterDays.toDouble(), target: 5, reward: completedTasks.contains('weekly_water') ? null : 25, showProgress: true, taskKey: 'weekly_water'),
      _ChallengeTask(title: 'Theo dõi liên tục', subtitle: '5 ngày ghi nhận', icon: Icons.track_changes_rounded, current: trackedDays.toDouble(), target: 5, reward: completedTasks.contains('weekly_tracked') ? null : 25, showProgress: true, taskKey: 'weekly_tracked'),
      _ChallengeTask(title: 'Đủ chất đạm', subtitle: '5 ngày đạt protein', icon: Icons.fitness_center_rounded, current: proteinDays.toDouble(), target: 5, reward: completedTasks.contains('weekly_protein') ? null : 30, showProgress: true, taskKey: 'weekly_protein'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subTextColor = textColor.withOpacity(0.55);
    final iconBgColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEDEDED);
    final progressBgColor = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFE4E4E4);
    final dividerColor = textColor.withOpacity(0.10);

    final dailyTasks = _dailyTasks();
    final weeklyTasks = _weeklyTasks();
    final dailyDone = dailyTasks.where((task) => task.completed).length;
    final weeklyDone = weeklyTasks.where((task) => task.completed).length;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _buildTopBar(textColor),
                  const SizedBox(height: 24),
                  _buildSectionHeader(title: 'Hàng ngày', progress: '$dailyDone/${dailyTasks.length}', timeLeft: 'còn ${_hoursLeftToday()} giờ', textColor: textColor, subTextColor: subTextColor, isDark: isDark),
                  const SizedBox(height: 12),
                  _buildTaskCard(tasks: dailyTasks, cardColor: cardColor, textColor: textColor, subTextColor: subTextColor, iconBgColor: iconBgColor, progressBgColor: progressBgColor, dividerColor: dividerColor),
                  const SizedBox(height: 28),
                  _buildSectionHeader(title: 'Hàng tuần', progress: '$weeklyDone/${weeklyTasks.length}', timeLeft: 'còn ${_daysLeftInWeek()} ngày', textColor: textColor, subTextColor: subTextColor, isDark: isDark),
                  const SizedBox(height: 12),
                  _buildTaskCard(tasks: weeklyTasks, cardColor: cardColor, textColor: textColor, subTextColor: subTextColor, iconBgColor: iconBgColor, progressBgColor: progressBgColor, dividerColor: dividerColor),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar(Color textColor) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 30),
            ),
          ),
          Text('Thử thách', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900)),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _coinIcon(size: 30, fontSize: 16),
                const SizedBox(width: 8),
                Text('$_coinBalance', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String progress, required String timeLeft, required Color textColor, required Color subTextColor, required bool isDark}) {
    return Row(
      children: [
        Text(title, style: TextStyle(color: subTextColor, fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF5B5B5B) : const Color(0xFFDADADA), borderRadius: BorderRadius.circular(999)),
          child: Text(progress, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        const Spacer(),
        Text(timeLeft, style: TextStyle(color: subTextColor, fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildTaskCard({required List<_ChallengeTask> tasks, required Color cardColor, required Color textColor, required Color subTextColor, required Color iconBgColor, required Color progressBgColor, required Color dividerColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          for (int i = 0; i < tasks.length; i++) ...[
            _buildTaskRow(task: tasks[i], textColor: textColor, subTextColor: subTextColor, iconBgColor: iconBgColor, progressBgColor: progressBgColor),
            if (i != tasks.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Divider(height: 1, thickness: 1.2, color: dividerColor),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskRow({required _ChallengeTask task, required Color textColor, required Color subTextColor, required Color iconBgColor, required Color progressBgColor}) {
    final isCompleted = task.completed;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isCompleted ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.05),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isCompleted ? greenColor : iconBgColor,
                  shape: BoxShape.circle,
                  boxShadow: isCompleted ? [BoxShadow(color: greenColor.withOpacity(0.5), blurRadius: 12 * value, spreadRadius: 2 * value)] : null,
                ),
                child: Icon(task.icon, color: isCompleted ? Colors.white : Colors.white.withOpacity(0.75), size: 31),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontSize: 23, fontWeight: FontWeight.w900, height: 1.1)),
                        ),
                        if (task.reward != null)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: isCompleted ? 1.0 : 0.0),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, val, child) {
                              return Opacity(
                                opacity: val,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: coinColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: val > 0.5 ? [BoxShadow(color: coinColor.withOpacity(0.5), blurRadius: 8 * val, spreadRadius: 2 * val)] : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.monetization_on, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text('+${task.reward}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(task.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.w700)),
                    if (task.showProgress) ...[
                      const SizedBox(height: 12),
                      _buildProgressBar(value: task.progress, label: task.progressLabel, progressBgColor: progressBgColor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar({required double value, required String label, required Color progressBgColor}) {
    return SizedBox(
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: value, minHeight: 18, backgroundColor: progressBgColor, valueColor: const AlwaysStoppedAnimation<Color>(greenColor)),
          ),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1)),
        ],
      ),
    );
  }

  Widget _coinIcon({required double size, required double fontSize}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: coinColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text('B', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w900)),
    );
  }
}

class _ChallengeTask {
  const _ChallengeTask({required this.title, required this.subtitle, required this.icon, required this.current, required this.target, required this.reward, this.showProgress = true, this.taskKey});
  final String title;
  final String subtitle;
  final IconData icon;
  final double current;
  final double target;
  final int? reward;
  final bool showProgress;
  final String? taskKey;

  bool get completed => current >= target;
  double get progress => target <= 0 ? 0 : (current / target).clamp(0.0, 1.0).toDouble();
  String get progressLabel => '${current.toInt()} / ${target.toInt()}';
}