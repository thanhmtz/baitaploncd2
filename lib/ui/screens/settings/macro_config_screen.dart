import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_tracker/shared/services/user_provider.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';

class MacroConfigScreen extends StatefulWidget {
  const MacroConfigScreen({Key? key}) : super(key: key);

  @override
  State<MacroConfigScreen> createState() => _MacroConfigScreenState();
}

class _MacroConfigScreenState extends State<MacroConfigScreen> {
  static const Color greenColor = Color(0xFF58B40B);

  late int goalCalories;
  late int proteinPct;
  late int fatPct;
  late int carbsPct;

  bool _saving = false;
  bool _loadingGoals = true;

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

    final userProvider = context.read<UserProvider>();

    if (userProvider.isLoaded) {
      final user = userProvider.getUser;
      goalCalories = user.goalCalories ?? 2100;
      proteinPct = user.goalProteinPct ?? 25;
      fatPct = user.goalFatPct ?? 25;
      carbsPct = user.goalCarbsPct ?? 50;
    } else {
      goalCalories = 2100;
      proteinPct = 25;
      fatPct = 25;
      carbsPct = 50;
    }

    _normalizeMacros();
    _loadGoalsFromFirestore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: bgColor,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: bgColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Future<void> _loadGoalsFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data() ?? {};

      final loadedGoalCalories = _toInt(data['goalCalories']);
      final loadedProteinPct = _toInt(data['goalProteinPct']);
      final loadedFatPct = _toInt(data['goalFatPct']);
      final loadedCarbsPct = _toInt(data['goalCarbsPct']);

      if (!mounted) return;

      setState(() {
        goalCalories = loadedGoalCalories ?? goalCalories;
        proteinPct = loadedProteinPct ?? proteinPct;
        fatPct = loadedFatPct ?? fatPct;
        carbsPct = loadedCarbsPct ?? carbsPct;
        _normalizeMacros();
      });
    } catch (e) {
      debugPrint('Error loading macro goals: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingGoals = false);
      }
    }
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int _clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  int _roundToFive(double value) {
    return ((value / 5).round() * 5).toInt();
  }

  void _normalizeMacros() {
    proteinPct = _clampInt(proteinPct, 5, 80);
    fatPct = _clampInt(fatPct, 5, 80);
    carbsPct = _clampInt(carbsPct, 5, 80);

    final total = proteinPct + fatPct + carbsPct;

    if (total != 100) {
      proteinPct = 25;
      fatPct = 25;
      carbsPct = 50;
    }
  }

  int get proteinGram {
    return (goalCalories * proteinPct / 100 / 4).round();
  }

  int get fatGram {
    return (goalCalories * fatPct / 100 / 9).round();
  }

  int get carbsGram {
    return (goalCalories * carbsPct / 100 / 4).round();
  }

  void _setProtein(double value) {
    final next = _clampInt(_roundToFive(value), 5, 80);
    final diff = next - proteinPct;
    final nextCarbs = carbsPct - diff;

    if (nextCarbs < 5 || nextCarbs > 80) return;

    setState(() {
      proteinPct = next;
      carbsPct = nextCarbs;
    });
  }

  void _setFat(double value) {
    final next = _clampInt(_roundToFive(value), 5, 80);
    final diff = next - fatPct;
    final nextCarbs = carbsPct - diff;

    if (nextCarbs < 5 || nextCarbs > 80) return;

    setState(() {
      fatPct = next;
      carbsPct = nextCarbs;
    });
  }

  void _setCarbs(double value) {
    final next = _clampInt(_roundToFive(value), 5, 80);
    final diff = next - carbsPct;
    final nextFat = fatPct - diff;

    if (nextFat < 5 || nextFat > 80) return;

    setState(() {
      carbsPct = next;
      fatPct = nextFat;
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await context.read<UserProvider>().updateMacroGoals(
            goalCalories: goalCalories,
            goalProteinPct: proteinPct,
            goalFatPct: fatPct,
            goalCarbsPct: carbsPct,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu mục tiêu calories & macro'),
          backgroundColor: greenColor,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = proteinPct + fatPct + carbsPct;
    final isValid = total == 100;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 116),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(total, isValid),
                  const SizedBox(height: 22),
                  if (_loadingGoals)
                    LinearProgressIndicator(
                      color: greenColor,
                      backgroundColor: progressBgColor,
                    ),
                  if (_loadingGoals) const SizedBox(height: 14),
                  _buildCaloriesCard(),
                  const SizedBox(height: 14),
                  _buildMacroCard(total, isValid),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            _buildSaveButton(isValid),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int total, bool isValid) {
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
                'Mục tiêu',
                style: TextStyle(
                  color: textColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Calories & macro mỗi ngày',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isValid
                ? greenColor.withOpacity(0.14)
                : Colors.red.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$total%',
            style: TextStyle(
              color: isValid ? greenColor : Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesCard() {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('🏆', 'Mục tiêu calories'),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        '$goalCalories',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'kcal',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 90,
            height: 150,
            decoration: BoxDecoration(
              color: softCardColor,
              borderRadius: BorderRadius.circular(26),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: NumberPicker(
                minValue: 800,
                maxValue: 6000,
                value: goalCalories.clamp(800, 6000),
                onChanged: (v) {
                  setState(() {
                    goalCalories = v;
                  });
                },
                itemHeight: 40,
                itemWidth: 90,
                axis: Axis.vertical,
                selectedTextStyle: const TextStyle(
                  fontSize: 22,
                  color: greenColor,
                  fontWeight: FontWeight.w900,
                ),
                textStyle: TextStyle(
                  fontSize: 16,
                  color: subTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(int total, bool isValid) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('🥗', 'Tỉ lệ macro'),
              const Spacer(),
              Text(
                isValid ? 'Hợp lệ' : 'Cần đủ 100%',
                style: TextStyle(
                  color: isValid ? greenColor : Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _macroSliderTile(
            emoji: '🥩',
            label: 'Chất đạm',
            value: proteinPct,
            grams: proteinGram,
            color: const Color(0xFFFF6B75),
            onChanged: _setProtein,
          ),
          const SizedBox(height: 14),
          _macroSliderTile(
            emoji: '🥑',
            label: 'Chất béo',
            value: fatPct,
            grams: fatGram,
            color: const Color(0xFF4CAF50),
            onChanged: _setFat,
          ),
          const SizedBox(height: 14),
          _macroSliderTile(
            emoji: '🍚',
            label: 'Tinh bột',
            value: carbsPct,
            grams: carbsGram,
            color: const Color(0xFFFFC947),
            onChanged: _setCarbs,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isValid
                  ? greenColor.withOpacity(0.12)
                  : Colors.red.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  isValid
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: isValid ? greenColor : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isValid
                        ? 'Tổng macro hiện tại là 100%.'
                        : 'Tổng hiện tại là $total%, cần bằng 100%.',
                    style: TextStyle(
                      color: isValid ? greenColor : Colors.red,
                      fontSize: 13,
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
  }

  Widget _sectionTitle(String emoji, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _macroSliderTile({
    required String emoji,
    required String label,
    required int value,
    required int grams,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    final percent = value / 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softCardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$grams g mỗi ngày',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  text: '$value',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  children: [
                    TextSpan(
                      text: '%',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 7,
              activeTrackColor: color,
              inactiveTrackColor: progressBgColor,
              thumbColor: color,
              overlayColor: color.withOpacity(0.16),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 18,
              ),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 5,
              max: 80,
              divisions: 15,
              label: '$value%',
              onChanged: onChanged,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: progressBgColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isValid) {
    final bottom = MediaQuery.of(context).padding.bottom + 18;

    return Positioned(
      left: 18,
      right: 18,
      bottom: bottom,
      child: GestureDetector(
        onTap: isValid && !_saving ? _save : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 58,
          decoration: BoxDecoration(
            color: isValid ? greenColor : progressBgColor,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              if (isValid)
                BoxShadow(
                  color: greenColor.withOpacity(0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
            ],
          ),
          child: Center(
            child: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isValid ? 'Lưu mục tiêu' : 'Macro cần đủ 100%',
                    style: TextStyle(
                      color: isValid ? Colors.white : subTextColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
