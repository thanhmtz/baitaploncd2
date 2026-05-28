import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_tracker/shared/services/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({Key? key}) : super(key: key);

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  static const Color greenColor = Color(0xFF58B40B);

  DateTime _weekStart = _getMonday(DateTime.now());
  int _selectedDayIndex = DateTime.now().weekday - 1;
  late Future<Map<String, dynamic>?> _dayPlanFuture;

  static DateTime _getMonday(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - diff);
  }

  String get _weekId => DateFormat('yyyy-MM-dd').format(_weekStart);

  List<DateTime> get _daysOfWeek {
    return List.generate(7, (index) {
      return _weekStart.add(Duration(days: index));
    });
  }

  DateTime get _selectedDate => _daysOfWeek[_selectedDayIndex];

  final List<String> _mealTypes = [
    'breakfast',
    'lunch',
    'dinner',
    'snacks',
  ];

  final Map<String, String> _mealEmojis = {
    'breakfast': '🍳',
    'lunch': '🍱',
    'dinner': '🍲',
    'snacks': '🍪',
  };

  final Map<String, Color> _mealColors = {
    'breakfast': const Color(0xFFFFC947),
    'lunch': const Color(0xFF58B40B),
    'dinner': const Color(0xFFFF6B75),
    'snacks': const Color(0xFF9C27B0),
  };

  Color get bgColor => Theme.of(context).scaffoldBackgroundColor;

  Color get cardColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E1E1E) : Colors.white;
  }

  Color get softCardColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF0D8);
  }

  Color get textColor => Theme.of(context).colorScheme.onSurface;

  Color get subTextColor {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.58);
  }

  Color get progressBgColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200;
  }

  @override
  void initState() {
    super.initState();
    _refreshDayPlan();
  }

  void _refreshDayPlan() {
    _dayPlanFuture = _loadDayPlan(_selectedDayIndex);
  }

  void _goToPreviousWeek() {
    if (!mounted) return;

    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _refreshDayPlan();
    });
  }

  void _goToNextWeek() {
    if (!mounted) return;

    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _refreshDayPlan();
    });
  }

  void _goToCurrentWeek() {
    if (!mounted) return;

    setState(() {
      _weekStart = _getMonday(DateTime.now());
      _selectedDayIndex = DateTime.now().weekday - 1;
      _refreshDayPlan();
    });
  }

  bool _isCurrentWeek() {
    final currentMonday = _getMonday(DateTime.now());

    return _weekStart.year == currentMonday.year &&
        _weekStart.month == currentMonday.month &&
        _weekStart.day == currentMonday.day;
  }

  String _weekRangeText() {
    final first = _daysOfWeek.first;
    final last = _daysOfWeek.last;

    return '${DateFormat('dd/MM').format(first)} - ${DateFormat('dd/MM/yyyy').format(last)}';
  }

  Future<Map<String, dynamic>?> _loadDayPlan(int dayIndex) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mealPlans')
        .doc(_weekId)
        .get();

    if (!doc.exists) return null;

    final daysRaw = doc.data()?['days'];
    if (daysRaw is! Map) return null;

    final dayRaw = daysRaw[dayIndex.toString()];
    if (dayRaw is! Map) return null;

    return Map<String, dynamic>.from(dayRaw);
  }

  Future<void> _saveMeal(
    int dayIndex,
    String mealType,
    Map<String, dynamic> mealData,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mealPlans')
        .doc(_weekId)
        .set({
      'days': {
        dayIndex.toString(): {
          mealType: mealData,
        },
      },
    }, SetOptions(merge: true));
  }

  Future<void> _clearMeal(int dayIndex, String mealType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mealPlans')
        .doc(_weekId);

    final snap = await ref.get();
    if (!snap.exists) return;

    await ref.update({
      'days.$dayIndex.$mealType': FieldValue.delete(),
    });
  }

  Future<void> _clearDay(int dayIndex) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mealPlans')
        .doc(_weekId);

    final snap = await ref.get();
    if (!snap.exists) return;

    await ref.update({
      'days.$dayIndex': FieldValue.delete(),
    });
  }

  String _mealTypeLabel(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      case 'snacks':
        return 'Ăn vặt';
      default:
        return mealType;
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  _DayTotals _calculateTotals(Map<String, dynamic>? dayData) {
    final totals = _DayTotals();

    if (dayData == null) return totals;

    for (final mealType in _mealTypes) {
      final rawMeal = dayData[mealType];

      if (rawMeal is! Map) continue;

      final meal = Map<String, dynamic>.from(rawMeal);

      totals.calories += _toDouble(meal['calories']);
      totals.protein += _toDouble(meal['protein']);
      totals.carbs += _toDouble(meal['carbs']);
      totals.fat += _toDouble(meal['fat']);
      totals.mealCount++;
    }

    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().getUser;
    final goalCal = user?.goalCalories ?? 2100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: bgColor,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: bgColor,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _dayPlanFuture,
          builder: (context, snapshot) {
            final dayData = snapshot.data;
            final totals = _calculateTotals(dayData);
            final loading = snapshot.connectionState == ConnectionState.waiting;

            return Stack(
              children: [
                _buildMainContent(
                  dayData: dayData,
                  totals: totals,
                  goalCal: goalCal,
                  loading: loading,
                ),
                if (totals.hasAny) _buildClearDayButton(),
              ],
            );
          },
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent({
    required Map<String, dynamic>? dayData,
    required _DayTotals totals,
    required int goalCal,
    required bool loading,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        18,
        8,
        18,
        totals.hasAny ? 120 : 36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 22),
          _buildWeekSwitcher(),
          const SizedBox(height: 22),
          _buildCalendar(),
          const SizedBox(height: 22),
          _buildSummaryCard(
            totals: totals,
            goalCal: goalCal,
            loading: loading,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(),
          const SizedBox(height: 14),
          ..._mealTypes.map((mealType) {
            final rawMeal = dayData?[mealType];
            final meal =
                rawMeal is Map ? Map<String, dynamic>.from(rawMeal) : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMealSlot(
                mealType: mealType,
                meal: meal,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final showCurrentWeek = !_isCurrentWeek();

    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: textColor,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kế hoạch bữa ăn',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lên thực đơn theo từng ngày',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _goToCurrentWeek,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: showCurrentWeek ? 12 : 10,
              vertical: showCurrentWeek ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: showCurrentWeek ? greenColor : cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: showCurrentWeek
                ? const Text(
                    'Tuần này',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Icon(
                    Icons.today_rounded,
                    color: textColor,
                    size: 22,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekSwitcher() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.04,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _weekArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: _goToPreviousWeek,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Tuần',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _weekRangeText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _weekArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: _goToNextWeek,
          ),
        ],
      ),
    );
  }

  Widget _weekArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: softCardColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: textColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    const dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final today = DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = _daysOfWeek[index];

        final isSelected = index == _selectedDayIndex;
        final isToday = day.year == today.year &&
            day.month == today.month &&
            day.day == today.day;

        return GestureDetector(
          onTap: () {
            if (!mounted) return;

            setState(() {
              _selectedDayIndex = index;
              _refreshDayPlan();
            });
          },
          child: Column(
            children: [
              Text(
                dayNames[index],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? textColor : subTextColor,
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: 46,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Positioned(
                        top: 1,
                        child: Container(
                          width: 18,
                          height: 4,
                          decoration: BoxDecoration(
                            color: textColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: isSelected ? 42 : 38,
                      height: isSelected ? 42 : 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? textColor : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: greenColor, width: 2)
                            : null,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSelected ? bgColor : textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard({
    required _DayTotals totals,
    required int goalCal,
    required bool loading,
  }) {
    final progress =
        goalCal <= 0 ? 0.0 : (totals.calories / goalCal).clamp(0.0, 1.0);
    final remaining = goalCal - totals.calories;
    final progressColor =
        totals.calories > goalCal ? const Color(0xFFFF6B75) : greenColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.04,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: loading
          ? const SizedBox(
              height: 126,
              child: Center(
                child: CircularProgressIndicator(
                  color: greenColor,
                  strokeWidth: 2.6,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: softCardColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Text(
                          '🍽️',
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              text: totals.calories.toInt().toString(),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                              children: [
                                TextSpan(
                                  text: '/$goalCal kcal',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: progressBgColor,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _summaryMiniTile(
                        emoji: '🥩',
                        label: 'Đạm',
                        value: '${totals.protein.toInt()}g',
                        color: const Color(0xFFFF6B75),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _summaryMiniTile(
                        emoji: '🍚',
                        label: 'Carb',
                        value: '${totals.carbs.toInt()}g',
                        color: const Color(0xFFFFC947),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _summaryMiniTile(
                        emoji: '🥑',
                        label: 'Béo',
                        value: '${totals.fat.toInt()}g',
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  remaining >= 0
                      ? 'Còn lại ${remaining.toInt()} kcal so với mục tiêu.'
                      : 'Vượt mục tiêu ${remaining.abs().toInt()} kcal.',
                  style: TextStyle(
                    color:
                        remaining >= 0 ? subTextColor : const Color(0xFFFF6B75),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryMiniTile({
    required String emoji,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: softCardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Text(
          'Thực đơn trong ngày',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Text(
          'Chạm để sửa',
          style: TextStyle(
            color: subTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMealSlot({
    required String mealType,
    required Map<String, dynamic>? meal,
  }) {
    final emoji = _mealEmojis[mealType] ?? '🍽️';
    final color = _mealColors[mealType] ?? greenColor;

    final hasMeal = meal != null;
    final name = meal?['name']?.toString() ?? '';
    final calories = _toDouble(meal?['calories']);
    final protein = _toDouble(meal?['protein']);
    final carbs = _toDouble(meal?['carbs']);
    final fat = _toDouble(meal?['fat']);

    return GestureDetector(
      onTap: () => _showMealSheet(_selectedDayIndex, mealType, meal),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.04,
              ),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 27),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hasMeal
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name.isEmpty ? _mealTypeLabel(mealType) : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${calories.toInt()} kcal',
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _miniMacro(icon: '🥩', value: protein),
                              const SizedBox(width: 7),
                              _miniMacro(icon: '🍚', value: carbs),
                              const SizedBox(width: 7),
                              _miniMacro(icon: '🥑', value: fat),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mealTypeLabel(mealType),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chạm để thêm món vào kế hoạch',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: hasMeal ? softCardColor : greenColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasMeal ? Icons.edit_rounded : Icons.add_rounded,
                color: hasMeal ? textColor : Colors.white,
                size: hasMeal ? 18 : 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMacro({
    required String icon,
    required double value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 2),
        Text(
          '${value.toInt()}g',
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _showMealSheet(
    int dayIndex,
    String mealType,
    Map<String, dynamic>? existing,
  ) async {
    final nameCtrl = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final caloriesCtrl = TextEditingController(
      text: existing?['calories']?.toString() ?? '',
    );
    final proteinCtrl = TextEditingController(
      text: existing?['protein']?.toString() ?? '',
    );
    final carbsCtrl = TextEditingController(
      text: existing?['carbs']?.toString() ?? '',
    );
    final fatCtrl = TextEditingController(
      text: existing?['fat']?.toString() ?? '',
    );

    bool saving = false;
    String? toastText;

    double readDouble(TextEditingController controller) {
      return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
    }

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom +
                    MediaQuery.of(sheetContext).padding.bottom +
                    18,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: subTextColor.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: softCardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _mealEmojis[mealType] ?? '🍽️',
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                existing == null
                                    ? 'Thêm ${_mealTypeLabel(mealType).toLowerCase()}'
                                    : 'Sửa ${_mealTypeLabel(mealType).toLowerCase()}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Nhập calories và macro dự kiến',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _inputField(
                      controller: nameCtrl,
                      label: 'Tên món ăn',
                      hint: 'Ví dụ: Cơm gà, yến mạch...',
                      icon: Icons.restaurant_rounded,
                    ),
                    const SizedBox(height: 10),
                    _inputField(
                      controller: caloriesCtrl,
                      label: 'Calories',
                      hint: '0',
                      suffix: 'kcal',
                      icon: Icons.local_fire_department_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _inputField(
                            controller: proteinCtrl,
                            label: 'Đạm',
                            hint: '0',
                            suffix: 'g',
                            icon: Icons.fitness_center_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _inputField(
                            controller: carbsCtrl,
                            label: 'Carb',
                            hint: '0',
                            suffix: 'g',
                            icon: Icons.rice_bowl_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _inputField(
                      controller: fatCtrl,
                      label: 'Chất béo',
                      hint: '0',
                      suffix: 'g',
                      icon: Icons.spa_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    if (existing != null) ...[
                      GestureDetector(
                        onTap: saving
                            ? null
                            : () async {
                                FocusManager.instance.primaryFocus?.unfocus();

                                setSheetState(() {
                                  saving = true;
                                });

                                try {
                                  await _clearMeal(dayIndex, mealType);

                                  toastText =
                                      'Đã xóa ${_mealTypeLabel(mealType).toLowerCase()}';

                                  if (modalContext.mounted) {
                                    Navigator.of(modalContext).pop(true);
                                  }
                                } catch (e) {
                                  if (modalContext.mounted) {
                                    setSheetState(() {
                                      saving = false;
                                    });
                                  }

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Có lỗi xảy ra: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Center(
                            child: Text(
                              'Xóa bữa này',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    GestureDetector(
                      onTap: saving
                          ? null
                          : () async {
                              FocusManager.instance.primaryFocus?.unfocus();

                              setSheetState(() {
                                saving = true;
                              });

                              try {
                                final name = nameCtrl.text.trim();

                                await _saveMeal(dayIndex, mealType, {
                                  'name': name.isEmpty
                                      ? _mealTypeLabel(mealType)
                                      : name,
                                  'calories': readDouble(caloriesCtrl),
                                  'protein': readDouble(proteinCtrl),
                                  'carbs': readDouble(carbsCtrl),
                                  'fat': readDouble(fatCtrl),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });

                                toastText = existing == null
                                    ? 'Đã thêm ${_mealTypeLabel(mealType).toLowerCase()}'
                                    : 'Đã cập nhật ${_mealTypeLabel(mealType).toLowerCase()}';

                                if (modalContext.mounted) {
                                  Navigator.of(modalContext).pop(true);
                                }
                              } catch (e) {
                                if (modalContext.mounted) {
                                  setSheetState(() {
                                    saving = false;
                                  });
                                }

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Có lỗi xảy ra: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: greenColor,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: greenColor.withOpacity(0.28),
                              blurRadius: 22,
                              offset: const Offset(0, 9),
                            ),
                          ],
                        ),
                        child: Center(
                          child: saving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Lưu bữa ăn',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;

    if (changed == true) {
      setState(_refreshDayPlan);

      if (toastText != null) {
        _showToast(toastText!);
      }
    }
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isNumber = keyboardType == TextInputType.number;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: isNumber
          ? [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ]
          : null,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(
          icon,
          color: greenColor,
          size: 21,
        ),
        filled: true,
        fillColor: cardColor,
        labelStyle: TextStyle(
          color: subTextColor,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: subTextColor.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
        suffixStyle: TextStyle(
          color: subTextColor,
          fontWeight: FontWeight.w800,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: greenColor,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildClearDayButton() {
    final bottom = MediaQuery.of(context).padding.bottom + 18;

    return Positioned(
      left: 18,
      right: 18,
      bottom: bottom,
      child: GestureDetector(
        onTap: _showClearDaySheet,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.24 : 0.08,
                ),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Xóa kế hoạch ngày này',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showClearDaySheet() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            MediaQuery.of(modalContext).padding.bottom + 18,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: subTextColor.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Xóa kế hoạch ngày?',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tất cả bữa ăn đã lên kế hoạch trong ngày này sẽ bị xóa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () async {
                  try {
                    await _clearDay(_selectedDayIndex);

                    if (modalContext.mounted) {
                      Navigator.of(modalContext).pop(true);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Có lỗi xảy ra: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Center(
                    child: Text(
                      'Xóa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(modalContext).pop(false),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (changed == true) {
      setState(_refreshDayPlan);
      _showToast('Đã xóa kế hoạch ngày');
    }
  }

  void _showToast(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: greenColor,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
  }

}

class _DayTotals {
  double calories = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;
  int mealCount = 0;

  bool get hasAny {
    return mealCount > 0 ||
        calories > 0 ||
        protein > 0 ||
        carbs > 0 ||
        fat > 0;
  }
}