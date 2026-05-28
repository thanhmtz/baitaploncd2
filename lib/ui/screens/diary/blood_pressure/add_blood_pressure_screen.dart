import 'package:flutter/material.dart';
import 'package:health_tracker/data/repositories/firestore.dart';
import 'package:health_tracker/shared/services/tree_service.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';

class AddBloodPressureScreen extends StatefulWidget {
  const AddBloodPressureScreen({Key? key}) : super(key: key);

  @override
  State<AddBloodPressureScreen> createState() => _AddBloodPressureScreenState();
}

class _AddBloodPressureScreenState extends State<AddBloodPressureScreen> {
  DateTime date = DateTime.now();
  int systolic = 120;
  int diastolic = 80;
  int pulse = 72;
  bool _saving = false;

  final _HealthWarningApi _healthWarningApi = _HealthWarningApi();

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

  _BpLevel get _level => _bpLevelFor(systolic, diastolic);

  String get bpCategory => _level.label;

  Color get bpCategoryColor => _level.color;

  String get bpSuggestion => _level.advice;

  int get pulsePressure => _pulsePressure(systolic, diastolic);

  double get map => _meanArterialPressure(systolic, diastolic);

  String get pulseSuggestion {
    if (pulse < 50) {
      return 'Nhịp tim hơi thấp. Nếu có chóng mặt, mệt hoặc ngất, hãy liên hệ nhân viên y tế.';
    }
    if (pulse > 100) {
      return 'Nhịp tim hơi cao. Hãy nghỉ yên vài phút và đo lại, đặc biệt nếu đang căng thẳng hoặc vừa vận động.';
    }
    return 'Nhịp tim đang ở vùng thường gặp khi nghỉ ngơi.';
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

  Future<bool> _confirmSaveIfHealthWarning() async {
    final warning = await _healthWarningApi.checkBloodPressure(
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
    );

    if (!mounted ||
        warning == null ||
        warning.severity == _HealthAlertSeverity.info) {
      return true;
    }

    final isUrgent = warning.severity == _HealthAlertSeverity.urgent;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(warning.icon, color: warning.color, size: 34),
          title: Text(warning.title),
          content: Text(
            '${warning.message}\n\n'
            '${isUrgent ? 'Đây là cảnh báo mức nguy hiểm. ' : ''}'
            'Bạn vẫn muốn lưu chỉ số này?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đo lại'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vẫn lưu'),
            ),
          ],
        );
      },
    );

    return shouldSave ?? false;
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    final canSave = await _confirmSaveIfHealthWarning();
    if (!canSave) {
      if (mounted) setState(() => _saving = false);
      return;
    }

    try {
      await FireStoreCrud().updateDiaryBloodPressure(
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        date: date,
        notes: noteController.text.trim(),
      );

      await TreeService().addBloodPressureXp();

      if (!mounted) return;

      _showSuccessToast('🩺 Đã lưu huyết áp! +10 XP');
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
                            blurRadius: 8,
                            offset: const Offset(0, 3),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm huyết áp'),
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
            _CurrentBpCard(
              systolic: systolic,
              diastolic: diastolic,
              pulse: pulse,
              level: _level,
              map: map,
              pulsePressure: pulsePressure,
            ),
            const SizedBox(height: 14),
            _BloodPressurePickerCard(
              systolic: systolic,
              diastolic: diastolic,
              onSystolicChanged: (value) {
                setState(() => systolic = value);
              },
              onDiastolicChanged: (value) {
                setState(() => diastolic = value);
              },
            ),
            const SizedBox(height: 14),
            _PulsePickerCard(
              pulse: pulse,
              suggestion: pulseSuggestion,
              onChanged: (value) {
                setState(() => pulse = value);
              },
            ),
            const SizedBox(height: 14),
            _AdviceCard(
              level: _level,
              systolic: systolic,
              diastolic: diastolic,
              map: map,
              pulsePressure: pulsePressure,
            ),
            const SizedBox(height: 14),
            _NoteCard(controller: noteController),
            const SizedBox(height: 10),
            Text(
              'Lưu ý: phân loại và công thức chỉ hỗ trợ theo dõi sức khỏe, không thay thế chẩn đoán y tế.',
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
                blurRadius: 8,
                offset: const Offset(0, -3),
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

class _CurrentBpCard extends StatelessWidget {
  const _CurrentBpCard({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.level,
    required this.map,
    required this.pulsePressure,
  });

  final int systolic;
  final int diastolic;
  final int pulse;
  final _BpLevel level;
  final double map;
  final int pulsePressure;

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
            blurRadius: 10,
            offset: const Offset(0, 5),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
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
                  '$systolic',
                  style: TextStyle(
                    fontSize: 64,
                    height: 0.95,
                    color: level.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '/$diastolic',
                  style: TextStyle(
                    fontSize: 42,
                    height: 1.05,
                    color: colorScheme.onSurface.withOpacity(0.82),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 9),
                  child: Text(
                    'mmHg',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.52),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _SmallInfoChip(
                icon: Icons.favorite_rounded,
                label: '$pulse bpm',
              ),
              _SmallInfoChip(
                icon: Icons.water_drop_rounded,
                label: 'MAP ${map.toStringAsFixed(0)}',
              ),
              _SmallInfoChip(
                icon: Icons.compare_arrows_rounded,
                label: 'PP $pulsePressure',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BloodPressurePickerCard extends StatelessWidget {
  const _BloodPressurePickerCard({
    required this.systolic,
    required this.diastolic,
    required this.onSystolicChanged,
    required this.onDiastolicChanged,
  });

  final int systolic;
  final int diastolic;
  final ValueChanged<int> onSystolicChanged;
  final ValueChanged<int> onDiastolicChanged;

  @override
  Widget build(BuildContext context) {
    Widget systolicPicker() {
      return _NumberPickerColumn(
        title: 'Tâm thu',
        unit: 'Systolic',
        color: const Color(0xFFE53935),
        minValue: 60,
        maxValue: 250,
        value: systolic,
        onChanged: onSystolicChanged,
      );
    }

    Widget diastolicPicker() {
      return _NumberPickerColumn(
        title: 'Tâm trương',
        unit: 'Diastolic',
        color: const Color(0xFF1E88E5),
        minValue: 30,
        maxValue: 150,
        value: diastolic,
        onChanged: onDiastolicChanged,
      );
    }

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.monitor_heart_rounded,
            title: 'Huyết áp',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;

              if (compact) {
                return Column(
                  children: [
                    systolicPicker(),
                    const SizedBox(height: 8),
                    Text(
                      '/',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    diastolicPicker(),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: systolicPicker()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '/',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  Expanded(child: diastolicPicker()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PulsePickerCard extends StatelessWidget {
  const _PulsePickerCard({
    required this.pulse,
    required this.suggestion,
    required this.onChanged,
  });

  final int pulse;
  final String suggestion;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SoftCard(
      child: Column(
        children: [
          const _CardTitle(
            icon: Icons.favorite_rounded,
            title: 'Nhịp tim',
          ),
          const SizedBox(height: 8),
          _NumberPickerColumn(
            title: 'Pulse',
            unit: 'bpm',
            color: const Color(0xFF8E24AA),
            minValue: 30,
            maxValue: 220,
            value: pulse,
            onChanged: onChanged,
          ),
          const SizedBox(height: 8),
          Text(
            suggestion,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.62),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberPickerColumn extends StatelessWidget {
  const _NumberPickerColumn({
    required this.title,
    required this.unit,
    required this.color,
    required this.minValue,
    required this.maxValue,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String unit;
  final Color color;
  final int minValue;
  final int maxValue;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.50),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 150,
          child: NumberPicker(
            minValue: minValue,
            maxValue: maxValue,
            value: value,
            itemHeight: 44,
            itemWidth: 90,
            onChanged: onChanged,
            selectedTextStyle: TextStyle(
              color: color,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
            textStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.34),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
enum _HealthAlertSeverity { info, warning, urgent }

class _HealthAlertResult {
  const _HealthAlertResult({
    required this.severity,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final _HealthAlertSeverity severity;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
}

class _HealthWarningApi {
  Future<_HealthAlertResult?> checkBloodPressure({
    required int systolic,
    required int diastolic,
    required int pulse,
  }) async {
    // Đây là API/service nội bộ, chỉ chạy khi người dùng bấm Lưu.
    // Nếu sau này có backend thật, chỉ cần thay logic trong hàm này bằng http.post().

    final map = _meanArterialPressure(systolic, diastolic);
    final pulsePressure = _pulsePressure(systolic, diastolic);

    if (systolic >= 180 || diastolic >= 120) {
      return const _HealthAlertResult(
        severity: _HealthAlertSeverity.urgent,
        title: 'Cảnh báo huyết áp rất cao',
        message:
            'Chỉ số đang ở mức rất cao. Hãy ngồi nghỉ yên 1–5 phút rồi đo lại. Nếu vẫn cao hoặc có đau ngực, khó thở, yếu/tê một bên, nhìn mờ, đau đầu dữ dội hoặc khó nói, hãy gọi cấp cứu ngay.',
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFD32F2F),
      );
    }

    if (systolic < 80 || diastolic < 50) {
      return const _HealthAlertResult(
        severity: _HealthAlertSeverity.urgent,
        title: 'Cảnh báo huyết áp rất thấp',
        message:
            'Chỉ số đang rất thấp. Nếu có chóng mặt, ngất, vã mồ hôi, mệt lả hoặc khó thở, hãy nằm nghỉ và liên hệ nhân viên y tế ngay.',
        icon: Icons.south_rounded,
        color: Color(0xFFD32F2F),
      );
    }

    if (pulse >= 130) {
      return const _HealthAlertResult(
        severity: _HealthAlertSeverity.urgent,
        title: 'Cảnh báo nhịp tim rất cao',
        message:
            'Nhịp tim đang rất cao. Hãy nghỉ yên và đo lại. Nếu kèm đau ngực, khó thở, choáng, hồi hộp dữ dội hoặc ngất, hãy gọi cấp cứu.',
        icon: Icons.favorite_rounded,
        color: Color(0xFFD32F2F),
      );
    }

    if (pulse <= 40) {
      return const _HealthAlertResult(
        severity: _HealthAlertSeverity.urgent,
        title: 'Cảnh báo nhịp tim rất thấp',
        message:
            'Nhịp tim đang rất thấp. Nếu có chóng mặt, mệt lả, ngất hoặc khó chịu nhiều, hãy liên hệ nhân viên y tế ngay.',
        icon: Icons.favorite_border_rounded,
        color: Color(0xFFD32F2F),
      );
    }

    if (systolic >= 160 || diastolic >= 100) {
      return const _HealthAlertResult(
        severity: _HealthAlertSeverity.warning,
        title: 'Huyết áp cao cần theo dõi sát',
        message:
            'Chỉ số đang cao. Nên nghỉ 5 phút rồi đo lại, ghi chú thời điểm đo, thuốc, cà phê, vận động hoặc căng thẳng. Nếu kết quả lặp lại nhiều lần, hãy trao đổi với bác sĩ.',
        icon: Icons.priority_high_rounded,
        color: Color(0xFFE53935),
      );
    }

    if (systolic >= 140 || diastolic >= 90) {
      return const _HealthAlertResult(
        severity: _HealthAlertSeverity.warning,
        title: 'Huyết áp tăng',
        message:
            'Chỉ số thuộc vùng tăng huyết áp. Nên đo lại vào ngày khác, theo dõi xu hướng và hạn chế muối, căng thẳng, rượu bia.',
        icon: Icons.trending_up_rounded,
        color: Color(0xFFFB8C00),
      );
    }

    if (systolic < 90 || diastolic < 60) {
      return const _HealthAlertResult(
        severity: _HealthAlertSeverity.warning,
        title: 'Huyết áp thấp',
        message:
            'Chỉ số hơi thấp. Hãy nghỉ ngơi, uống đủ nước nếu không bị hạn chế dịch, và theo dõi triệu chứng chóng mặt, mệt hoặc ngất.',
        icon: Icons.south_rounded,
        color: Color(0xFF039BE5),
      );
    }

    if (pulse > 100) {
      return const _HealthAlertResult(
        severity: _HealthAlertSeverity.warning,
        title: 'Nhịp tim hơi cao',
        message:
            'Nhịp tim đang cao hơn vùng thường gặp khi nghỉ. Hãy nghỉ yên vài phút và đo lại, đặc biệt nếu vừa vận động, uống cà phê hoặc đang căng thẳng.',
        icon: Icons.favorite_rounded,
        color: Color(0xFFFB8C00),
      );
    }

    if (pulse < 50) {
      return const _HealthAlertResult(
        severity: _HealthAlertSeverity.warning,
        title: 'Nhịp tim hơi thấp',
        message:
            'Nhịp tim đang thấp. Nếu bạn là người thường xuyên luyện tập thể thao có thể là bình thường, nhưng nếu có chóng mặt, mệt hoặc ngất thì nên liên hệ nhân viên y tế.',
        icon: Icons.favorite_border_rounded,
        color: Color(0xFF039BE5),
      );
    }

    if (pulsePressure >= 80) {
      return const _HealthAlertResult(
        severity: _HealthAlertSeverity.warning,
        title: 'Pulse Pressure cao',
        message:
            'Hiệu số huyết áp tâm thu - tâm trương đang cao. Nên đo lại và theo dõi thêm nhiều lần, đặc biệt nếu chỉ số này thường xuyên lặp lại.',
        icon: Icons.compare_arrows_rounded,
        color: Color(0xFFFB8C00),
      );
    }

    if (map < 60) {
      return const _HealthAlertResult(
        severity: _HealthAlertSeverity.warning,
        title: 'MAP thấp',
        message:
            'Áp lực động mạch trung bình đang thấp. Nếu có chóng mặt, mệt lả hoặc ngất, hãy liên hệ nhân viên y tế.',
        icon: Icons.water_drop_rounded,
        color: Color(0xFF039BE5),
      );
    }

    return const _HealthAlertResult(
      severity: _HealthAlertSeverity.info,
      title: 'Chỉ số hiện ổn định',
      message:
          'Chỉ số hiện không nằm trong vùng cảnh báo. Hãy tiếp tục đo định kỳ, ghi chú thời điểm đo và duy trì lối sống lành mạnh.',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF43A047),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({
    required this.level,
    required this.systolic,
    required this.diastolic,
    required this.map,
    required this.pulsePressure,
  });

  final _BpLevel level;
  final int systolic;
  final int diastolic;
  final double map;
  final int pulsePressure;

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
            title: 'MAP',
            formula: '($systolic + 2 × $diastolic) / 3',
            result: '${map.toStringAsFixed(0)} mmHg',
          ),
          const SizedBox(height: 8),
          _FormulaLine(
            title: 'Pulse Pressure',
            formula: '$systolic - $diastolic',
            result: '$pulsePressure mmHg',
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
                hintText: 'Ghi chú: thời điểm đo, cảm giác, thuốc, hoạt động...',
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
            blurRadius: 8,
            offset: const Offset(0, 4),
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

class _BpLevel {
  const _BpLevel({
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

int _pulsePressure(int systolic, int diastolic) {
  return (systolic - diastolic).clamp(0, 999);
}

double _meanArterialPressure(int systolic, int diastolic) {
  return (systolic + (2 * diastolic)) / 3.0;
}

_BpLevel _bpLevelFor(int systolic, int diastolic) {
  if (systolic >= 180 || diastolic >= 120) {
    return const _BpLevel(
      label: 'Rất cao',
      advice:
          'Chỉ số đang rất cao. Hãy nghỉ yên 1–5 phút rồi đo lại. Nếu vẫn cao hoặc có đau ngực, khó thở, yếu/tê, nhìn mờ, khó nói, hãy gọi cấp cứu ngay.',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFD32F2F),
    );
  }

  if (systolic >= 140 || diastolic >= 90) {
    return const _BpLevel(
      label: 'Tăng huyết áp',
      advice:
          'Chỉ số thuộc vùng tăng huyết áp. Nên đo lại vào ngày khác, theo dõi nhiều lần và hỏi ý kiến bác sĩ nếu kết quả lặp lại.',
      icon: Icons.priority_high_rounded,
      color: Color(0xFFE53935),
    );
  }

  if ((systolic >= 120 && systolic <= 139) ||
      (diastolic >= 70 && diastolic <= 89)) {
    return const _BpLevel(
      label: 'Tăng nhẹ',
      advice:
          'Chỉ số đang ở vùng tăng nhẹ. Nên giảm muối, ngủ đủ, vận động đều, hạn chế căng thẳng và tiếp tục theo dõi xu hướng.',
      icon: Icons.trending_up_rounded,
      color: Color(0xFFFB8C00),
    );
  }

  if (systolic < 90 || diastolic < 60) {
    return const _BpLevel(
      label: 'Thấp',
      advice:
          'Chỉ số hơi thấp. Nếu có chóng mặt, mệt, ngất hoặc khó chịu, hãy nghỉ ngơi và liên hệ nhân viên y tế.',
      icon: Icons.south_rounded,
      color: Color(0xFF039BE5),
    );
  }

  return const _BpLevel(
    label: 'Không tăng',
    advice:
        'Chỉ số hiện ở vùng không tăng. Hãy duy trì ăn uống lành mạnh, ngủ đủ, vận động đều và đo định kỳ.',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF43A047),
  );
}
