import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum _Gender { male, female }

enum _ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive,
}

enum _GoalType {
  loseFat,
  maintain,
  gainWeight,
  buildMuscle,
}

class HealthCalculatorScreen extends StatefulWidget {
  const HealthCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<HealthCalculatorScreen> createState() => _HealthCalculatorScreenState();
}

class _HealthCalculatorScreenState extends State<HealthCalculatorScreen> {
  static const Color greenColor = Color(0xFF58B40B);
  static const Color glowGreen = Color(0xFF8DFF73);
  static const Color darkBackground = Color(0xFF06120D);

  _Gender gender = _Gender.male;
  double weightKg = 65;
  double heightCm = 170;
  int age = 25;
  _ActivityLevel activityLevel = _ActivityLevel.moderate;
  _GoalType goal = _GoalType.maintain;

  bool _savingGoal = false;

  /// BMI = cân nặng(kg) / (chiều cao(m))^2
  /// Phân loại: <18.5 thiếu cân, 18.5-22.9 bình thường, 23-24.9 thừa cân nhẹ, 25-29.9 thừa cân, >=30 béo phì
  double get bmi {
    final heightM = heightCm / 100;
    if (heightM <= 0) return 0;
    return weightKg / (heightM * heightM);
  }

  /// BMR (Basal Metabolic Rate) - công thức Mifflin-St Jeor
  /// Nam: 10*W + 6.25*H - 5*A + 5
  /// Nữ: 10*W + 6.25*H - 5*A - 161
  double get bmr {
    final genderConstant = gender == _Gender.male ? 5 : -161;
    return 10 * weightKg + 6.25 * heightCm - 5 * age + genderConstant;
  }

  /// TDEE = BMR * hệ số vận động (1.2 - 1.9)
  double get tdee => bmr * _activityFactor(activityLevel);

  /// Calo mục tiêu dựa trên mục tiêu (giảm mỡ, duy trì, tăng cân, tăng cơ)
  /// Giới hạn dưới: nam 1500 kcal, nữ 1200 kcal
  double get goalCalories {
    final minimumCalories = gender == _Gender.male ? 1500.0 : 1200.0;
    switch (goal) {
      case _GoalType.loseFat:
        return math.max(minimumCalories, tdee * 0.80);
      case _GoalType.maintain:
        return tdee;
      case _GoalType.gainWeight:
        return tdee * 1.15;
      case _GoalType.buildMuscle:
        return tdee * 1.10;
    }
  }

  /// Phân bổ macro (Protein/Fat/Carbs) theo từng mục tiêu
  /// Giảm mỡ: protein cao (35%) để giữ cơ
  /// Duy trì: cân bằng (25/25/50)
  /// Tăng cân: carb cao (55%) để đủ năng lượng
  /// Tăng cơ: protein cao (30%), carb đủ (45%)
  Map<String, int> get macroPreset {
    switch (goal) {
      case _GoalType.loseFat:
        return const {'protein': 35, 'fat': 25, 'carbs': 40};
      case _GoalType.maintain:
        return const {'protein': 25, 'fat': 25, 'carbs': 50};
      case _GoalType.gainWeight:
        return const {'protein': 25, 'fat': 20, 'carbs': 55};
      case _GoalType.buildMuscle:
        return const {'protein': 30, 'fat': 25, 'carbs': 45};
    }
  }

  int get proteinPct => macroPreset['protein']!;
  int get fatPct => macroPreset['fat']!;
  int get carbsPct => macroPreset['carbs']!;

  /// Tổng macro phải = 100% mới hợp lệ
  int get macroTotal => proteinPct + fatPct + carbsPct;

  /// Protein: 4 kcal/g, Fat: 9 kcal/g, Carbs: 4 kcal/g
  double get proteinGram => goalCalories * proteinPct / 100 / 4;
  double get fatGram => goalCalories * fatPct / 100 / 9;
  double get carbsGram => goalCalories * carbsPct / 100 / 4;

  /// Ước tính % mỡ cơ thể bằng công thức Deurenberg
  /// BF% = 1.20*BMI + 0.23*Tuổi - 10.8*GiớiTính - 5.4
  /// Giới hạn trong khoảng 3% - 60%
  double get estimatedBodyFat {
    final sexValue = gender == _Gender.male ? 1 : 0;
    final value = 1.20 * bmi + 0.23 * age - 10.8 * sexValue - 5.4;
    return value.clamp(3, 60).toDouble();
  }

  /// Cân nặng lý tưởng theo công thức Devine
  /// Nam: 50 + 2.3*(inch_vượt_5ft)
  /// Nữ: 45.5 + 2.3*(inch_vượt_5ft)
  double get idealWeight {
    final heightInches = heightCm / 2.54;
    final inchesOverFiveFeet = math.max(0, heightInches - 60);
    final base = gender == _Gender.male ? 50.0 : 45.5;
    return base + 2.3 * inchesOverFiveFeet;
  }

  /// Khối nạc = cân nặng * (1 - %mỡ)
  double get leanMass => weightKg * (1 - estimatedBodyFat / 100);

  /// Lưu mục tiêu xuống Firestore (dùng chung field với MacroConfigScreen)
  /// Kiểm tra: đã đăng nhập, macro = 100%
  Future<void> _saveGoalToFirestore() async {
    if (_savingGoal) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showToast('Bạn cần đăng nhập để lưu mục tiêu.', isSuccess: false);
      return;
    }

    if (macroTotal != 100) {
      _showToast('Tổng macro phải bằng 100%.', isSuccess: false);
      return;
    }

    setState(() => _savingGoal = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'goalCalories': goalCalories.round(),
        'goalProteinPct': proteinPct,
        'goalFatPct': fatPct,
        'goalCarbsPct': carbsPct,
        'healthGoal': _goalKey(goal),
        'activityLevel': _activityKey(activityLevel),
        'calculatorWeightKg': double.parse(weightKg.toStringAsFixed(1)),
        'calculatorHeightCm': double.parse(heightCm.toStringAsFixed(1)),
        'calculatorAge': age,
        'calculatorGender': gender == _Gender.male ? 'male' : 'female',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _showToast(
        'Đã áp dụng mục tiêu: ${goalCalories.round()} kcal • '
        'P$proteinPct/F$fatPct/C$carbsPct',
      );
    } catch (e) {
      if (!mounted) return;
      _showToast('Không lưu được mục tiêu. Vui lòng thử lại.', isSuccess: false);
      debugPrint('Error saving calculated goal: $e');
    } finally {
      if (mounted) {
        setState(() => _savingGoal = false);
      }
    }
  }

  void _showToast(String text, {bool isSuccess = true}) {
    try {
      final overlay = Overlay.of(context);
      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) {
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 450),
            tween: Tween(begin: -120.0, end: 40.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Positioned(
                top: value,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.86,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSuccess ? greenColor : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSuccess
                                    ? greenColor
                                    : const Color(0xFFE76B5B),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isSuccess
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 15,
                                    )
                                  : const Text(
                                      '!',
                                      style: TextStyle(
                                        color: Color(0xFFE76B5B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      overlay.insert(overlayEntry);

      Future.delayed(const Duration(seconds: 2), () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: isSuccess ? greenColor : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                top: -95,
                left: -80,
                child: _GlowBlob(
                  size: 230,
                  color: greenColor,
                  opacity: 0.20,
                ),
              ),
              Positioned(
                right: -95,
                bottom: 80,
                child: _GlowBlob(
                  size: 270,
                  color: glowGreen,
                  opacity: 0.10,
                ),
              ),
              Column(
                children: [
                  _buildHeader(l10n),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMainResultCard(l10n),
                          const SizedBox(height: 16),
                          _buildInputCard(l10n),
                          const SizedBox(height: 16),
                          _buildEnergyCard(l10n),
                          const SizedBox(height: 16),
                          _buildBodyCard(l10n),
                          const SizedBox(height: 16),
                          _buildMacroCard(l10n),
                          const SizedBox(height: 16),
                          _buildApplyGoalCard(l10n),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            child: Material(
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 139, right: 16),
            child: Text(
              l10n.healthCalculator,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainResultCard(AppLocalizations l10n) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      child: Column(
        children: [
          Text(
            'BMI',
            style: TextStyle(
              color: Colors.white.withOpacity(0.56),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bmi.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 66,
              height: 0.95,
              fontWeight: FontWeight.w900,
              letterSpacing: -3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _bmiColor(bmi).withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _bmiColor(bmi).withOpacity(0.42)),
            ),
            child: Text(
              _bmiCategory(bmi, l10n),
              style: TextStyle(
                color: _bmiColor(bmi),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _QuickStat(
                  label: l10n.goal,
                  value: '${goalCalories.round()}',
                  unit: l10n.kcalPerDay,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickStat(
                  label: l10n.idealWeight,
                  value: idealWeight.toStringAsFixed(1),
                  unit: 'kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(AppLocalizations l10n) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.bodyInfo, Icons.person_rounded),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  label: l10n.male,
                  icon: Icons.male_rounded,
                  selected: gender == _Gender.male,
                  onTap: () => setState(() => gender = _Gender.male),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SegmentButton(
                  label: l10n.female,
                  icon: Icons.female_rounded,
                  selected: gender == _Gender.female,
                  onTap: () => setState(() => gender = _Gender.female),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSliderRow(
            label: l10n.weight,
            value: weightKg,
            unit: 'kg',
            min: 25,
            max: 220,
            divisions: 1950,
            onChanged: (value) => setState(() => weightKg = value),
          ),
          _buildSliderRow(
            label: l10n.height,
            value: heightCm,
            unit: 'cm',
            min: 100,
            max: 230,
            divisions: 1300,
            onChanged: (value) => setState(() => heightCm = value),
          ),
          _buildSliderRow(
            label: l10n.age,
            value: age.toDouble(),
            unit: l10n.yearsOld,
            min: 10,
            max: 90,
            divisions: 80,
            decimal: false,
            onChanged: (value) => setState(() => age = value.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyCard(AppLocalizations l10n) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.dailyEnergy, Icons.local_fire_department_rounded),
          const SizedBox(height: 14),
          _label(l10n.activityLevel),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ActivityLevel.values.map((level) {
              return _ChoicePill(
                label: _activityLabel(level, l10n),
                selected: activityLevel == level,
                onTap: () => setState(() => activityLevel = level),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _label(l10n.goal),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _GoalType.values.map((item) {
              return _ChoicePill(
                label: _goalLabel(item, l10n),
                selected: goal == item,
                onTap: () => setState(() => goal = item),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: greenColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: greenColor.withOpacity(0.18)),
            ),
            child: Text(
              _goalExplanation(l10n),
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'BMR',
                  value: bmr.round().toString(),
                  unit: 'kcal',
                  icon: Icons.bedtime_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'TDEE',
                  value: tdee.round().toString(),
                  unit: 'kcal',
                  icon: Icons.directions_run_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCard(AppLocalizations l10n) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.bodyComposition, Icons.monitor_weight_rounded),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: l10n.bodyFat,
                  value: estimatedBodyFat.toStringAsFixed(1),
                  unit: '%',
                  icon: Icons.percent_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: l10n.leanMass,
                  value: leanMass.toStringAsFixed(1),
                  unit: 'kg',
                  icon: Icons.fitness_center_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.disclaimer,
            style: TextStyle(
              color: Colors.white.withOpacity(0.50),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(AppLocalizations l10n) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.macroSuggestion, Icons.pie_chart_rounded),
          const SizedBox(height: 8),
          Text(
            'Tỉ lệ này sẽ được lưu đúng theo MacroConfigScreen: '
            'Protein $proteinPct% • Fat $fatPct% • Carbs $carbsPct%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.52),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _MacroRow(
            label: 'Protein',
            grams: proteinGram,
            percent: proteinPct / 100,
            color: const Color(0xFFFF8FA3),
          ),
          const SizedBox(height: 12),
          _MacroRow(
            label: 'Fat',
            grams: fatGram,
            percent: fatPct / 100,
            color: const Color(0xFF7C83FF),
          ),
          const SizedBox(height: 12),
          _MacroRow(
            label: 'Carbs',
            grams: carbsGram,
            percent: carbsPct / 100,
            color: const Color(0xFFFFC857),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                macroTotal == 100
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                color: macroTotal == 100 ? glowGreen : const Color(0xFFE76B5B),
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                'Tổng macro: $macroTotal%',
                style: TextStyle(
                  color: macroTotal == 100
                      ? glowGreen
                      : const Color(0xFFE76B5B),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplyGoalCard(AppLocalizations l10n) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Áp dụng vào mục tiêu', Icons.save_rounded),
          const SizedBox(height: 12),
          Text(
            'Khi bấm lưu, app sẽ cập nhật các field dùng chung với '
            'MacroConfigScreen: goalCalories, goalProteinPct, '
            'goalFatPct, goalCarbsPct.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontSize: 13,
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniGoalTile(
                  label: 'Calories',
                  value: '${goalCalories.round()}',
                  unit: 'kcal',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniGoalTile(
                  label: 'Macro',
                  value: 'P$proteinPct/F$fatPct/C$carbsPct',
                  unit: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _savingGoal ? null : _saveGoalToFirestore,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 56,
              decoration: BoxDecoration(
                color: _savingGoal ? Colors.white.withOpacity(0.12) : greenColor,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  if (!_savingGoal)
                    BoxShadow(
                      color: greenColor.withOpacity(0.32),
                      blurRadius: 22,
                      offset: const Offset(0, 9),
                    ),
                ],
              ),
              child: Center(
                child: _savingGoal
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lưu làm mục tiêu hằng ngày',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required String unit,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    bool decimal = true,
  }) {
    final valueText = decimal ? value.toStringAsFixed(1) : value.round().toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _label(label)),
              Text(
                '$valueText $unit',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: greenColor,
              inactiveTrackColor: Colors.white.withOpacity(0.10),
              thumbColor: Colors.white,
              overlayColor: greenColor.withOpacity(0.16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              min: min,
              max: max,
              divisions: divisions,
              value: value.clamp(min, max).toDouble(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: greenColor.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: glowGreen, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.68),
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  double _activityFactor(_ActivityLevel level) {
    switch (level) {
      case _ActivityLevel.sedentary:
        return 1.2;
      case _ActivityLevel.light:
        return 1.375;
      case _ActivityLevel.moderate:
        return 1.55;
      case _ActivityLevel.active:
        return 1.725;
      case _ActivityLevel.veryActive:
        return 1.9;
    }
  }

  String _activityLabel(_ActivityLevel level, AppLocalizations l10n) {
    switch (level) {
      case _ActivityLevel.sedentary:
        return l10n.sedentary;
      case _ActivityLevel.light:
        return l10n.light;
      case _ActivityLevel.moderate:
        return l10n.moderate;
      case _ActivityLevel.active:
        return l10n.active;
      case _ActivityLevel.veryActive:
        return l10n.veryActive;
    }
  }

  String _goalLabel(_GoalType item, AppLocalizations l10n) {
    switch (item) {
      case _GoalType.loseFat:
        return l10n.loseFat;
      case _GoalType.maintain:
        return l10n.maintain;
      case _GoalType.gainWeight:
        return l10n.gainWeight;
      case _GoalType.buildMuscle:
        return l10n.buildMuscle;
    }
  }

  String _goalExplanation(AppLocalizations l10n) {
    switch (goal) {
      case _GoalType.loseFat:
        return 'Giảm mỡ: calories = TDEE × 80%, protein cao để giữ cơ. '
            'Macro chuẩn: Protein 35%, Fat 25%, Carbs 40%.';
      case _GoalType.maintain:
        return 'Duy trì: calories = TDEE. Macro cân bằng: '
            'Protein 25%, Fat 25%, Carbs 50%.';
      case _GoalType.gainWeight:
        return 'Tăng cân: calories = TDEE × 115%, ưu tiên carb để đủ năng lượng. '
            'Macro chuẩn: Protein 25%, Fat 20%, Carbs 55%.';
      case _GoalType.buildMuscle:
        return 'Tăng cơ: calories = TDEE × 110%, protein và carb cao để hỗ trợ tập luyện. '
            'Macro chuẩn: Protein 30%, Fat 25%, Carbs 45%.';
    }
  }

  String _activityKey(_ActivityLevel level) {
    switch (level) {
      case _ActivityLevel.sedentary:
        return 'sedentary';
      case _ActivityLevel.light:
        return 'light';
      case _ActivityLevel.moderate:
        return 'moderate';
      case _ActivityLevel.active:
        return 'active';
      case _ActivityLevel.veryActive:
        return 'veryActive';
    }
  }

  String _goalKey(_GoalType item) {
    switch (item) {
      case _GoalType.loseFat:
        return 'loseFat';
      case _GoalType.maintain:
        return 'maintain';
      case _GoalType.gainWeight:
        return 'gainWeight';
      case _GoalType.buildMuscle:
        return 'buildMuscle';
    }
  }

  String _bmiCategory(double value, AppLocalizations l10n) {
    if (value < 18.5) return l10n.underweight;
    if (value < 23) return l10n.normal;
    if (value < 25) return l10n.mildlyOverweight;
    if (value < 30) return l10n.overweight;
    return l10n.obese;
  }

  Color _bmiColor(double value) {
    if (value < 18.5) return const Color(0xFF64B5F6);
    if (value < 23) return glowGreen;
    if (value < 25) return const Color(0xFFFFD54F);
    if (value < 30) return const Color(0xFFFF9800);
    return const Color(0xFFE76B5B);
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18261E),
            Color(0xFF101B15),
            Color(0xFF090E0C),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _HealthCalculatorScreenState.greenColor.withOpacity(0.16),
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
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
              blurRadius: size * 0.58,
              spreadRadius: size * 0.10,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _HealthCalculatorScreenState.greenColor
        : Colors.white.withOpacity(0.08);

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? _HealthCalculatorScreenState.glowGreen.withOpacity(0.45)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? _HealthCalculatorScreenState.greenColor.withOpacity(0.95)
          : Colors.white.withOpacity(0.065),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _HealthCalculatorScreenState.glowGreen.withOpacity(0.45)
                  : Colors.white.withOpacity(0.07),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(selected ? 1 : 0.76),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.075)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.52),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.075)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _HealthCalculatorScreenState.glowGreen, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.54),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.48),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.grams,
    required this.percent,
    required this.color,
  });

  final String label;
  final double grams;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentText = '${(percent * 100).round()}%';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${grams.round()} g',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              percentText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.50),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MiniGoalTile extends StatelessWidget {
  const _MiniGoalTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.075)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.52),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
