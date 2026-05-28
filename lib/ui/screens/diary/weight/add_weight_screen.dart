import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_tracker/data/repositories/firestore.dart';
import 'package:health_tracker/shared/services/tree_service.dart';
import 'package:intl/intl.dart';

class AddWeightScreen extends StatefulWidget {
  const AddWeightScreen({Key? key}) : super(key: key);

  @override
  State<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  static const Color greenColor = Color(0xFF58B40B);
  static const Color darkBackground = Color(0xFF06120D);
  static const Color cardColor = Color(0xFF121C17);

  final _formKey = GlobalKey<FormState>();

  DateTime date = DateTime.now();
  bool _isSaving = false;

  late final TextEditingController weightController;
  late final TextEditingController heightController;
  late final TextEditingController bodyFatController;
  late final TextEditingController skeletalMuscleController;
  late final TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    weightController = TextEditingController(text: '60');
    heightController = TextEditingController();
    bodyFatController = TextEditingController();
    skeletalMuscleController = TextEditingController();
    noteController = TextEditingController();
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    bodyFatController.dispose();
    skeletalMuscleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  double? _parseNumber(String value) {
    final text = value.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  double? get _weight => _parseNumber(weightController.text);
  double? get _heightCm => _parseNumber(heightController.text);
  double? get _bodyFatPercent => _parseNumber(bodyFatController.text);
  double? get _skeletalMuscleKg => _parseNumber(skeletalMuscleController.text);

  double? get _bmi {
    final weight = _weight;
    final heightCm = _heightCm;
    if (weight == null || heightCm == null || weight <= 0 || heightCm <= 0) {
      return null;
    }

    final heightM = heightCm / 100;
    return weight / math.pow(heightM, 2);
  }

  double? get _fatMassKg {
    final weight = _weight;
    final bodyFat = _bodyFatPercent;
    if (weight == null || bodyFat == null || weight <= 0) return null;
    return weight * bodyFat / 100;
  }

  double? get _leanMassKg {
    final weight = _weight;
    final fatMass = _fatMassKg;
    if (weight == null || fatMass == null) return null;
    return weight - fatMass;
  }

  double? get _musclePercent {
    final weight = _weight;
    final muscle = _skeletalMuscleKg;
    if (weight == null || muscle == null || weight <= 0) return null;
    return muscle / weight * 100;
  }

  String _bmiStatus(double? bmi) {
    if (bmi == null) return 'Nhập chiều cao để tính BMI';
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 23) return 'Bình thường';
    if (bmi < 25) return 'Hơi thừa cân';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  Color _bmiColor(double? bmi) {
    if (bmi == null) return Colors.white.withOpacity(0.55);
    if (bmi < 18.5) return const Color(0xFFFFC857);
    if (bmi < 23) return greenColor;
    if (bmi < 25) return const Color(0xFFFFC857);
    return const Color(0xFFFF6B6B);
  }

  Future<void> _pickDate() async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (newDate == null) return;

    setState(() {
      date = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        date.hour,
        date.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );

    if (newTime == null) return;

    setState(() {
      date = DateTime(
        date.year,
        date.month,
        date.day,
        newTime.hour,
        newTime.minute,
      );
    });
  }

  String? _validateWeight(String? value) {
    final weight = _parseNumber(value ?? '');
    if (weight == null) return 'Vui lòng nhập cân nặng';
    if (weight <= 0) return 'Cân nặng phải lớn hơn 0 kg';
    if (weight > 500) return 'Cân nặng không hợp lệ';
    return null;
  }

  String? _validateHeight(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final height = _parseNumber(text);
    if (height == null) return 'Chiều cao không hợp lệ';
    if (height < 50 || height > 250) return 'Nhập chiều cao theo cm';
    return null;
  }

  String? _validateBodyFat(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final bodyFat = _parseNumber(text);
    if (bodyFat == null) return 'Tỷ lệ mỡ không hợp lệ';
    if (bodyFat < 0 || bodyFat > 75) return 'Tỷ lệ mỡ nên nằm trong 0 - 75%';
    return null;
  }

  String? _validateSkeletalMuscle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final muscle = _parseNumber(text);
    final weight = _weight;
    if (muscle == null) return 'Khối lượng cơ không hợp lệ';
    if (muscle < 0) return 'Khối lượng cơ không được âm';
    if (weight != null && muscle > weight) {
      return 'Cơ xương không thể lớn hơn cân nặng';
    }
    return null;
  }

  Future<void> _saveWeight() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showToast('Vui lòng kiểm tra lại thông tin', isSuccess: false);
      return;
    }

    final weight = _weight!;
    final bodyFat = _bodyFatPercent;
    final skeletalMuscle = _skeletalMuscleKg;

    setState(() => _isSaving = true);

    try {
      await Future.sync(
        () => FireStoreCrud().updateDiaryWeight(
          date,
          _formatNumber(weight),
          bodyFat == null ? '' : _formatNumber(bodyFat),
          skeletalMuscle == null ? '' : _formatNumber(skeletalMuscle),
          noteController.text.trim(),
        ),
      );

      await Future.sync(() => TreeService().addWeightXp());

      if (!mounted) return;
      _showToast('Đã lưu cân nặng! +5 XP');

      await Future.delayed(const Duration(milliseconds: 650));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error saving weight: $e');
      if (mounted) {
        _showToast('Không lưu được cân nặng. Vui lòng thử lại.', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showToast(String text, {bool isSuccess = true}) {
    try {
      final overlay = Overlay.of(context);
      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) {
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 420),
            tween: Tween(begin: -120.0, end: 38.0),
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
                        maxWidth: MediaQuery.of(context).size.width * 0.88,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                                color: isSuccess ? greenColor : const Color(0xFFE76B5B),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isSuccess
                                  ? const Icon(Icons.check, color: Colors.white, size: 15)
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
        if (overlayEntry.mounted) overlayEntry.remove();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text),
            backgroundColor: isSuccess ? greenColor : Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    18 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateTimeCard(),
                      const SizedBox(height: 14),
                      _buildWeightCard(),
                      const SizedBox(height: 14),
                      _buildBodyInfoCard(),
                      const SizedBox(height: 14),
                      _buildResultCard(),
                      const SizedBox(height: 14),
                      _buildNoteCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          ),
          const Expanded(
            child: Text(
              'Thêm cân nặng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return _AppCard(
      child: Row(
        children: [
          Expanded(
            child: _SmallActionTile(
              icon: Icons.calendar_month_rounded,
              title: 'Ngày',
              value: DateFormat('dd/MM/yyyy').format(date),
              onTap: _isSaving ? null : _pickDate,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SmallActionTile(
              icon: Icons.access_time_rounded,
              title: 'Giờ',
              value: DateFormat('HH:mm').format(date),
              onTap: _isSaving ? null : _pickTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightCard() {
    return _AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(icon: Icons.monitor_weight_rounded),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cân nặng hiện tại',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: weightController,
            enabled: !_isSaving,
            validator: _validateWeight,
            onChanged: (_) => setState(() {}),
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 54,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.4,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.18)),
              suffixText: 'kg',
              suffixStyle: TextStyle(
                color: Colors.white.withOpacity(0.52),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.055),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: greenColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyInfoCard() {
    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cơ thể',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _NumberInput(
            controller: heightController,
            label: 'Chiều cao',
            unit: 'cm',
            hint: 'VD: 170',
            enabled: !_isSaving,
            validator: _validateHeight,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _NumberInput(
            controller: bodyFatController,
            label: 'Tỷ lệ mỡ cơ thể',
            unit: '%',
            hint: 'Tùy chọn',
            enabled: !_isSaving,
            validator: _validateBodyFat,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _NumberInput(
            controller: skeletalMuscleController,
            label: 'Khối lượng cơ xương',
            unit: 'kg',
            hint: 'Tùy chọn',
            enabled: !_isSaving,
            validator: _validateSkeletalMuscle,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final bmi = _bmi;
    final fatMass = _fatMassKg;
    final leanMass = _leanMassKg;
    final musclePercent = _musclePercent;

    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(icon: Icons.analytics_rounded),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tính toán tự động',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  title: 'BMI',
                  value: bmi == null ? '--' : bmi.toStringAsFixed(1),
                  subtitle: _bmiStatus(bmi),
                  valueColor: _bmiColor(bmi),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBox(
                  title: 'Mỡ',
                  value: fatMass == null ? '--' : '${fatMass.toStringAsFixed(1)} kg',
                  subtitle: fatMass == null ? 'Nhập % mỡ' : 'Khối lượng mỡ',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  title: 'Nạc',
                  value: leanMass == null ? '--' : '${leanMass.toStringAsFixed(1)} kg',
                  subtitle: leanMass == null ? 'Cần % mỡ' : 'Weight - fat mass',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBox(
                  title: 'Cơ',
                  value: musclePercent == null ? '--' : '${musclePercent.toStringAsFixed(1)}%',
                  subtitle: musclePercent == null ? 'Nhập cơ xương' : 'Cơ / cân nặng',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Công thức: BMI = cân nặng / chiều cao², mỡ kg = cân nặng × % mỡ, nạc kg = cân nặng - mỡ kg.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.46),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return _AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(icon: Icons.edit_note_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: noteController,
              enabled: !_isSaving,
              minLines: 2,
              maxLines: 5,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Ghi chú: sau ăn, sau tập, buổi sáng...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.38)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        decoration: BoxDecoration(
          color: darkBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.18)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text(
                  'Hủy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Lưu cân nặng',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _AddWeightScreenState.cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.075)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _AddWeightScreenState.greenColor.withOpacity(0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: _AddWeightScreenState.greenColor,
        size: 22,
      ),
    );
  }
}

class _SmallActionTile extends StatelessWidget {
  const _SmallActionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.045),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _AddWeightScreenState.greenColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.48),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.controller,
    required this.label,
    required this.unit,
    required this.hint,
    required this.enabled,
    required this.validator,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final String hint;
  final bool enabled;
  final String? Function(String?) validator;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      ],
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.58)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.28)),
        suffixText: unit,
        suffixStyle: TextStyle(
          color: Colors.white.withOpacity(0.56),
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.045),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: _AddWeightScreenState.greenColor, width: 1.8),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1.8),
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.title,
    required this.value,
    required this.subtitle,
    this.valueColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.065)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.46),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.40),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
