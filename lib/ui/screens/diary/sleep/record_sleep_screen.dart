import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_range_picker/time_range_picker.dart';

class RecordSleepScreen extends StatefulWidget {
  const RecordSleepScreen({Key? key}) : super(key: key);

  @override
  State<RecordSleepScreen> createState() => _RecordSleepScreenState();
}

class _RecordSleepScreenState extends State<RecordSleepScreen> {
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _saved = false;

  double _calculateHours() {
    if (_start == null || _end == null) return 0;
    final startMin = _start!.hour * 60 + _start!.minute;
    var endMin = _end!.hour * 60 + _end!.minute;
    if (endMin <= startMin) {
      endMin += 24 * 60;
    }
    return (endMin - startMin) / 60.0;
  }

  Future<void> _save() async {
    if (_start == null || _end == null) return;
    final hours = _calculateHours();
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final key = 'sleep_duration_${now.year}_${now.month}_${now.day}';
    await prefs.setDouble(key, hours);
    setState(() => _saved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu giấc ngủ: ${hours.toStringAsFixed(1)}h')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _calculateHours();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi giấc ngủ'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TimeRangePicker(
              start: _start,
              end: _end,
              strokeColor: const Color.fromARGB(255, 255, 200, 38),
              handlerColor: const Color.fromARGB(255, 255, 200, 38),
              strokeWidth: 5,
              ticks: 12,
              ticksLength: 5,
              backgroundWidget: const Text(
                'Giấc ngủ',
                style: TextStyle(fontSize: 24),
              ),
              onStartChange: (val) => setState(() => _start = val),
              onEndChange: (val) => setState(() => _end = val),
            ),
            if (_start != null && _end != null) ...[
              const SizedBox(height: 24),
              Text(
                'Thời gian ngủ: ${hours.toStringAsFixed(1)} giờ',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saved ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 200, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _saved ? 'Đã lưu' : 'Lưu',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
