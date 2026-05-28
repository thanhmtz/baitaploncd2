import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({Key? key, required this.date}) : super(key: key);

  final DateTime date;

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen>
    with SingleTickerProviderStateMixin {
  static const Color greenColor = Color(0xFF58B40B);
  static const Color glowGreen = Color(0xFF8DFF73);
  static const Color darkBackground = Color(0xFF06120D);

  List<Map<String, dynamic>> _monthData = [];
  bool _isLoading = true;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.96, end: 1.045).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowOpacity = Tween<double>(begin: 0.36, end: 0.72).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void didUpdateWidget(covariant StreakScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.date.year != widget.date.year ||
        oldWidget.date.month != widget.date.month) {
      setState(() => _isLoading = true);
      _loadData();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final diaryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('diary');

      final startOfMonth = DateTime(widget.date.year, widget.date.month, 1);
      final daysInMonth = _daysInMonth(startOfMonth);

      final monthDocs = await Future.wait(
        List.generate(daysInMonth, (index) {
          final day = DateTime(
            startOfMonth.year,
            startOfMonth.month,
            index + 1,
          );
          final dayStr = DateFormat('d-M-y').format(day);
          return diaryRef.doc(dayStr).get();
        }),
      );

      _monthData = monthDocs
          .map(
            (doc) => doc.exists
                ? Map<String, dynamic>.from(doc.data()!)
                : <String, dynamic>{},
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading monthly streak data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  bool _hasFoods(Map<String, dynamic> data) {
    if (data.isEmpty) return false;

    final mealGroups = [
      'breakfast',
      'Breakfast',
      'buaSang',
      'lunch',
      'Lunch',
      'buaTrua',
      'dinner',
      'Dinner',
      'buaToi',
    ];

    for (final key in mealGroups) {
      if (!data.containsKey(key)) continue;

      final meal = data[key];
      if (meal is Map) {
        final foods = meal['foods'];
        final items = meal['items'];
        final calories = _toDouble(
          meal['calories'] ?? meal['kcal'] ?? data['totalCalories'] ?? 0,
        );

        if (foods is List && foods.isNotEmpty) return true;
        if (items is List && items.isNotEmpty) return true;
        if (calories > 0) return true;
      }
    }

    final calories = _toDouble(data['totalCalories']);
    return calories > 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final startOfMonth = DateTime(widget.date.year, widget.date.month, 1);
    final daysInMonth = _daysInMonth(startOfMonth);
    final streakData = _calculateMonthStreak(startOfMonth);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentDayIndex = _getCurrentDayIndex(
      today: today,
      startOfMonth: startOfMonth,
      daysInMonth: daysInMonth,
    );

    return Scaffold(
      backgroundColor: darkBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF04110B),
              Color(0xFF092017),
              Color(0xFF080D0B),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                left: -70,
                child: _BackgroundGlow(
                  size: 210,
                  color: greenColor,
                  opacity: 0.18,
                ),
              ),
              Positioned(
                right: -95,
                bottom: 80,
                child: _BackgroundGlow(
                  size: 260,
                  color: glowGreen,
                  opacity: 0.10,
                ),
              ),
              Positioned(
                top: 12,
                left: 14,
                child: _buildBackButton(),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 34),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _isLoading
                        ? const _PremiumLoader()
                        : _buildStreakCard(
                            streakData: streakData,
                            startOfMonth: startOfMonth,
                            today: today,
                            currentDayIndex: currentDayIndex,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getCurrentDayIndex({
    required DateTime today,
    required DateTime startOfMonth,
    required int daysInMonth,
  }) {
    final endOfMonth = DateTime(
      startOfMonth.year,
      startOfMonth.month,
      daysInMonth,
    );

    if (today.isBefore(startOfMonth)) return 0;
    if (today.isAfter(endOfMonth)) return daysInMonth - 1;

    return today.day - 1;
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  List<bool> _calculateMonthStreak(DateTime startOfMonth) {
    final daysInMonth = _daysInMonth(startOfMonth);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(daysInMonth, (index) {
      final day = DateTime(startOfMonth.year, startOfMonth.month, index + 1);
      final isTracked = index < _monthData.length
          ? _hasFoods(_monthData[index])
          : false;

      if (day.isAfter(today)) return false;
      return isTracked;
    });
  }

  Widget _buildStreakCard({
    required List<bool> streakData,
    required DateTime startOfMonth,
    required DateTime today,
    required int currentDayIndex,
  }) {
    final consecutiveDays = _countConsecutiveDays(streakData, currentDayIndex);
    final streakLabel = _getStreakLabel(consecutiveDays);
    final streakEmoji = _getStreakEmoji(consecutiveDays);

    return Container(
      padding: const EdgeInsets.fromLTRB(26, 34, 26, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18261E),
            Color(0xFF101B15),
            Color(0xFF090E0C),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.085)),
        boxShadow: [
          BoxShadow(
            color: greenColor.withOpacity(0.24),
            blurRadius: 44,
            spreadRadius: 1,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.38),
            blurRadius: 34,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseScale.value,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        glowGreen.withOpacity(0.22),
                        greenColor.withOpacity(0.12),
                        Colors.white.withOpacity(0.035),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: greenColor.withOpacity(_glowOpacity.value),
                        blurRadius: 42,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: child,
                ),
              );
            },
            child: Center(
              child: Text(
                streakEmoji,
                style: const TextStyle(fontSize: 42),
              ),
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 340),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              '$consecutiveDays',
              key: ValueKey(consecutiveDays),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 54,
                height: 0.90,
                fontWeight: FontWeight.w900,
                letterSpacing: -2.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'NGÀY GIỮ CHUỖI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.56),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              streakLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.74),
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildMonthCalendar(
            startOfMonth: startOfMonth,
            streakData: streakData,
            today: today,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar({
    required DateTime startOfMonth,
    required List<bool> streakData,
    required DateTime today,
  }) {
    final daysInMonth = _daysInMonth(startOfMonth);
    final leadingEmptyCells = startOfMonth.weekday - DateTime.monday;
    final totalCells = _roundUpToFullWeeks(leadingEmptyCells + daysInMonth);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.075)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tháng ${startOfMonth.month}/${startOfMonth.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(7, (index) {
              return Expanded(
                child: Text(
                  _getDayName(index + 1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.50),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leadingEmptyCells + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final day = DateTime(
                startOfMonth.year,
                startOfMonth.month,
                dayNumber,
              );
              final dataIndex = dayNumber - 1;
              final isCompleted = dataIndex < streakData.length
                  ? streakData[dataIndex]
                  : false;
              final isToday = _isSameDay(day, today);
              final isFuture = day.isAfter(today);

              return _buildMonthDayCell(
                day: day,
                isCompleted: isCompleted,
                isToday: isToday,
                isFuture: isFuture,
              );
            },
          ),
        ],
      ),
    );
  }

  int _roundUpToFullWeeks(int cells) {
    final remainder = cells % 7;
    if (remainder == 0) return cells;
    return cells + (7 - remainder);
  }

  String _getStreakLabel(int consecutiveDays) {
    if (consecutiveDays >= 21) {
      return 'Chuỗi rất mạnh. Bạn đã giữ nhịp gần như cả tháng.';
    }
    if (consecutiveDays >= 14) {
      return 'Hai tuần liên tục là một thành tích rất tốt.';
    }
    if (consecutiveDays >= 7) {
      return 'Một tuần hoàn hảo. Bạn đang giữ nhịp rất tốt.';
    }
    if (consecutiveDays >= 4) {
      return 'Thói quen đang vào guồng. Tiếp tục duy trì nhé.';
    }
    if (consecutiveDays >= 2) {
      return 'Đà đang lên. Đừng để chuỗi bị ngắt hôm nay.';
    }
    if (consecutiveDays == 1) {
      return 'Ngày đầu đã hoàn thành. Ngày mai quay lại để nối chuỗi.';
    }
    return 'Bắt đầu nhẹ nhàng. Hoàn thành hôm nay để tạo chuỗi mới.';
  }

  String _getStreakEmoji(int consecutiveDays) {
    if (consecutiveDays >= 21) return '👑';
    if (consecutiveDays >= 7) return '🏆';
    if (consecutiveDays >= 2) return '🔥';
    return '🌱';
  }

  int _countConsecutiveDays(List<bool> streakData, int currentDayIndex) {
    if (streakData.isEmpty) return 0;

    int count = 0;
    final safeIndex = currentDayIndex.clamp(0, streakData.length - 1);

    for (int i = safeIndex; i >= 0; i--) {
      if (streakData[i]) {
        count++;
      } else {
        break;
      }
    }

    return count;
  }

  String _getDayName(int weekday) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days[weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildMonthDayCell({
    required DateTime day,
    required bool isCompleted,
    required bool isToday,
    required bool isFuture,
  }) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: isToday ? 32 : 28,
              height: isToday ? 32 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? null
                    : Colors.white.withOpacity(isFuture ? 0.030 : 0.070),
                gradient: isCompleted
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF9CFF7D),
                          Color(0xFF58B40B),
                        ],
                      )
                    : null,
                border: Border.all(
                  color: isToday
                      ? Colors.white.withOpacity(0.94)
                      : Colors.white.withOpacity(isFuture ? 0.045 : 0.09),
                  width: isToday ? 2 : 1,
                ),
                boxShadow: [
                  if (isCompleted)
                    BoxShadow(
                      color: greenColor.withOpacity(isToday ? 0.58 : 0.30),
                      blurRadius: isToday ? 16 : 10,
                      spreadRadius: isToday ? 1.5 : 0.5,
                    ),
                  if (isToday && !isCompleted)
                    BoxShadow(
                      color: Colors.white.withOpacity(0.18),
                      blurRadius: 12,
                      spreadRadius: 0.5,
                    ),
                ],
              ),
              child: Center(
                child: isCompleted && !isFuture
                    ? const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF07120D),
                        size: 18,
                      )
                    : isToday
                        ? Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: greenColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${day.day}',
              style: TextStyle(
                color: isToday
                    ? Colors.white
                    : Colors.white.withOpacity(isFuture ? 0.24 : 0.48),
                fontSize: 9,
                height: 1.0,
                fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(opacity),
              blurRadius: size * 0.55,
              spreadRadius: size * 0.12,
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumLoader extends StatelessWidget {
  const _PremiumLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.055),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: _StreakScreenState.greenColor.withOpacity(0.26),
              blurRadius: 26,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              _StreakScreenState.greenColor,
            ),
          ),
        ),
      ),
    );
  }
}
