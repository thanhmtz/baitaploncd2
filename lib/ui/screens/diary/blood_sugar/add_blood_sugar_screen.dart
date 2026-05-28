import 'package:flutter/material.dart';
import 'package:health_tracker/data/models/blood_sugar_model.dart';
import 'package:health_tracker/data/repositories/firestore.dart';
import 'package:health_tracker/shared/services/tree_service.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';

class AddBloodSugarScreen extends StatefulWidget {
  const AddBloodSugarScreen({Key? key}) : super(key: key);

  @override
  State<AddBloodSugarScreen> createState() => _AddBloodSugarScreenState();
}

class _AddBloodSugarScreenState extends State<AddBloodSugarScreen> {
  DateTime date = DateTime.now();
  double value = 5.6;
  BloodSugarMealContext mealContext = BloodSugarMealContext.fasting;
  bool _saving = false;

  late final TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  _BloodSugarLevel get _level => _bloodSugarLevelFor(value, mealContext);

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
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );

    if (time == null) return;

    setState(() {
      date = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await FireStoreCrud().updateDiaryBloodSugar(
        value: value,
        mealContext: mealContext.name,
        date: date,
        notes: noteController.text.trim(),
      );

      await TreeService().addBloodSugarXp();

      if (!mounted) return;

      _showSuccessToast('🩸 Đã lưu đường huyết! +10 XP');
      await Future.delayed(const Duration(milliseconds: 650));

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không lưu được dữ liệu: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSuccessToast(String text) {
    try {
      final overlay = Overlay.of(context);
      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) {
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 450),
            tween: Tween(begin: -120.0, end: 48.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Positioned(
                top: value,
                left: 16,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
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
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2DBB7A),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check,
                                color: Color(0xFF2DBB7A),
                                size: 16,
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
                                fontWeight: FontWeight.w800,
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
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  String get contextLabel => _contextLabel(mealContext);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm đường huyết'),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(isDark ? 0.16 : 0.08),
              colorScheme.surface,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            _DateTimeCard(
              date: date,
              onPickDate: _pickDate,
              onPickTime: _pickTime,
            ),
            const SizedBox(height: 14),
            _CurrentBloodSugarCard(
              value: value,
              contextLabel: contextLabel,
              level: _level,
            ),
            const SizedBox(height: 14),
            _BloodSugarPickerCard(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
            const SizedBox(height: 14),
            _MealContextCard(
              selected: mealContext,
              onChanged: (ctx) => setState(() => mealContext = ctx),
            ),
            const SizedBox(height: 14),
            _AdviceCard(
              level: _level,
              value: value,
              mealContext: mealContext,
            ),
            const SizedBox(height: 14),
            _NoteCard(controller: noteController),
            const SizedBox(height: 10),
            Text(
              'Lưu ý: phân loại chỉ hỗ trợ theo dõi sức khỏe, không thay thế chẩn đoán y tế.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.52),
                height: 1.35,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Lưu',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeCard extends StatelessWidget {
  const _DateTimeCard({
    required this.date,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime date;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          Expanded(
            child: _DateTimeButton(
              icon: Icons.calendar_month_rounded,
              label: 'Ngày đo',
              value: DateFormat('dd/MM/yyyy').format(date),
              onTap: onPickDate,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DateTimeButton(
              icon: Icons.schedule_rounded,
              label: 'Giờ đo',
              value: DateFormat('HH:mm').format(date),
              onTap: onPickTime,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.primary.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.56),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
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

class _CurrentBloodSugarCard extends StatelessWidget {
  const _CurrentBloodSugarCard({
    required this.value,
    required this.contextLabel,
    required this.level,
  });

  final double value;
  final String contextLabel;
  final _BloodSugarLevel level;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: level.color.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: level.color.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(level.icon, color: level.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Chỉ số hiện tại',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  level.label,
                  style: TextStyle(
                    color: level.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 64,
                    height: 0.95,
                    color: level.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 9),
                  child: Text(
                    'mmol/L',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.52),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SmallInfoChip(
            icon: Icons.restaurant_menu_rounded,
            label: contextLabel,
          ),
        ],
      ),
    );
  }
}

class _BloodSugarPickerCard extends StatelessWidget {
  const _BloodSugarPickerCard({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        children: [
          const _CardTitle(
            icon: Icons.bloodtype_rounded,
            title: 'Đường huyết',
          ),
          const SizedBox(height: 8),
          Text(
            'mmol/L',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.50),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: DecimalNumberPicker(
              minValue: 1,
              maxValue: 35,
              value: value,
              decimalPlaces: 1,
              onChanged: onChanged,
              selectedTextStyle: const TextStyle(
                color: Colors.teal,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
              textStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.34),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealContextCard extends StatelessWidget {
  const _MealContextCard({
    required this.selected,
    required this.onChanged,
  });

  final BloodSugarMealContext selected;
  final ValueChanged<BloodSugarMealContext> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.schedule_rounded,
            title: 'Thời điểm đo',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BloodSugarMealContext.values.map((ctx) {
              final isSelected = selected == ctx;
              return ChoiceChip(
                avatar: Icon(_contextIcon(ctx), size: 16),
                label: Text(_contextLabel(ctx)),
                selected: isSelected,
                onSelected: (_) => onChanged(ctx),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({
    required this.level,
    required this.value,
    required this.mealContext,
  });

  final _BloodSugarLevel level;
  final double value;
  final BloodSugarMealContext mealContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: level.color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_rounded, color: level.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gợi ý theo chỉ số đo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            level.advice,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.78),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: level.color.withOpacity(0.18)),
          const SizedBox(height: 10),
          _FormulaLine(
            title: 'Quy đổi',
            formula: '${value.toStringAsFixed(1)} mmol/L × 18.018',
            result: '${(value * 18.018).toStringAsFixed(0)} mg/dL',
          ),
          const SizedBox(height: 8),
          Text(
            _rangeText(mealContext),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.64),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaLine extends StatelessWidget {
  const _FormulaLine({
    required this.title,
    required this.formula,
    required this.result,
  });

  final String title;
  final String formula;
  final String result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$title = $formula',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.64),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          result,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_note_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.multiline,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Ghi chú: trước/sau ăn bao lâu, triệu chứng, thuốc...',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  const _SmallInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BloodSugarLevel {
  const _BloodSugarLevel({
    required this.label,
    required this.advice,
    required this.icon,
    required this.color,
  });

  final String label;
  final String advice;
  final IconData icon;
  final Color color;
}

_BloodSugarLevel _bloodSugarLevelFor(
  double value,
  BloodSugarMealContext mealContext,
) {
  if (value < 3.0) {
    return const _BloodSugarLevel(
      label: 'Rất thấp',
      advice:
          'Đường huyết đang rất thấp. Nếu có run tay, vã mồ hôi, lú lẫn, ngất hoặc khó chịu nhiều, hãy xử trí theo hướng dẫn y tế và liên hệ nhân viên y tế ngay.',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFD32F2F),
    );
  }

  if (value < 3.9) {
    return const _BloodSugarLevel(
      label: 'Thấp',
      advice:
          'Đường huyết hơi thấp. Nên nghỉ ngơi, theo dõi triệu chứng và đo lại. Nếu có dấu hiệu bất thường, hãy liên hệ nhân viên y tế.',
      icon: Icons.south_rounded,
      color: Color(0xFF039BE5),
    );
  }

  switch (mealContext) {
    case BloodSugarMealContext.fasting:
    case BloodSugarMealContext.beforeMeal:
      if (value <= 5.5) {
        return const _BloodSugarLevel(
          label: 'Bình thường',
          advice:
              'Chỉ số đang trong vùng thường gặp khi đói hoặc trước bữa ăn. Hãy tiếp tục theo dõi định kỳ.',
          icon: Icons.check_circle_rounded,
          color: Color(0xFF43A047),
        );
      }
      if (value <= 6.9) {
        return const _BloodSugarLevel(
          label: 'Tăng nhẹ',
          advice:
              'Chỉ số đang cao hơn vùng bình thường khi đói/trước ăn. Nên theo dõi thêm các lần đo khác và trao đổi với bác sĩ nếu kết quả lặp lại.',
          icon: Icons.trending_up_rounded,
          color: Color(0xFFFB8C00),
        );
      }
      return const _BloodSugarLevel(
        label: 'Cao',
        advice:
            'Chỉ số đang cao. Hãy đo lại đúng cách, ghi nhận thời điểm ăn/uống thuốc và hỏi ý kiến bác sĩ nếu kết quả lặp lại hoặc có triệu chứng.',
        icon: Icons.priority_high_rounded,
        color: Color(0xFFE53935),
      );

    case BloodSugarMealContext.afterMeal:
      if (value < 7.8) {
        return const _BloodSugarLevel(
          label: 'Bình thường',
          advice:
              'Chỉ số sau ăn đang trong vùng thường gặp. Hãy ghi rõ sau ăn bao lâu để theo dõi chính xác hơn.',
          icon: Icons.check_circle_rounded,
          color: Color(0xFF43A047),
        );
      }
      if (value <= 11.0) {
        return const _BloodSugarLevel(
          label: 'Tăng nhẹ',
          advice:
              'Chỉ số sau ăn đang tăng. Nên theo dõi xu hướng, chú ý khẩu phần tinh bột/đường và đo lại vào các ngày khác.',
          icon: Icons.trending_up_rounded,
          color: Color(0xFFFB8C00),
        );
      }
      return const _BloodSugarLevel(
        label: 'Cao',
        advice:
            'Chỉ số sau ăn đang cao. Nếu kết quả lặp lại hoặc có mệt nhiều, khát nhiều, tiểu nhiều, hãy trao đổi với bác sĩ.',
        icon: Icons.priority_high_rounded,
        color: Color(0xFFE53935),
      );

    case BloodSugarMealContext.bedtime:
      if (value <= 7.8) {
        return const _BloodSugarLevel(
          label: 'Ổn định',
          advice:
              'Chỉ số trước khi ngủ đang ở vùng ổn định để theo dõi. Mục tiêu cụ thể có thể khác nhau tùy từng người.',
          icon: Icons.check_circle_rounded,
          color: Color(0xFF43A047),
        );
      }
      if (value <= 10.0) {
        return const _BloodSugarLevel(
          label: 'Tăng nhẹ',
          advice:
              'Chỉ số trước khi ngủ hơi cao. Nên ghi chú bữa tối, vận động, thuốc và theo dõi thêm.',
          icon: Icons.trending_up_rounded,
          color: Color(0xFFFB8C00),
        );
      }
      return const _BloodSugarLevel(
        label: 'Cao',
        advice:
            'Chỉ số trước khi ngủ đang cao. Hãy theo dõi thêm và hỏi ý kiến bác sĩ nếu thường xuyên lặp lại.',
        icon: Icons.priority_high_rounded,
        color: Color(0xFFE53935),
      );
  }
}

String _contextLabel(BloodSugarMealContext ctx) {
  switch (ctx) {
    case BloodSugarMealContext.fasting:
      return 'Đói / sáng sớm';
    case BloodSugarMealContext.beforeMeal:
      return 'Trước ăn';
    case BloodSugarMealContext.afterMeal:
      return 'Sau ăn';
    case BloodSugarMealContext.bedtime:
      return 'Trước khi ngủ';
  }
}

IconData _contextIcon(BloodSugarMealContext ctx) {
  switch (ctx) {
    case BloodSugarMealContext.fasting:
      return Icons.wb_twilight_rounded;
    case BloodSugarMealContext.beforeMeal:
      return Icons.restaurant_menu_rounded;
    case BloodSugarMealContext.afterMeal:
      return Icons.restaurant_rounded;
    case BloodSugarMealContext.bedtime:
      return Icons.bedtime_rounded;
  }
}

String _rangeText(BloodSugarMealContext ctx) {
  switch (ctx) {
    case BloodSugarMealContext.fasting:
    case BloodSugarMealContext.beforeMeal:
      return 'Mốc tham khảo: bình thường 3.9–5.5, tăng nhẹ 5.6–6.9, cao từ 7.0 mmol/L.';
    case BloodSugarMealContext.afterMeal:
      return 'Mốc tham khảo sau ăn: bình thường <7.8, tăng nhẹ 7.8–11.0, cao từ 11.1 mmol/L.';
    case BloodSugarMealContext.bedtime:
      return 'Mốc trước ngủ chỉ để theo dõi xu hướng; mục tiêu cá nhân có thể khác nhau.';
  }
}
