import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health_tracker/shared/services/water_reminder_service.dart';

class WaterReminderSheet extends StatefulWidget {
  const WaterReminderSheet({Key? key}) : super(key: key);

  @override
  State<WaterReminderSheet> createState() => _WaterReminderSheetState();
}

class _WaterReminderSheetState extends State<WaterReminderSheet> {
  final WaterReminderService _service = WaterReminderService();
  List<WaterReminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.getReminders();
    if (!mounted) return;
    setState(() {
      _reminders = list;
      _loading = false;
    });
  }

  Future<void> _toggle(String id, bool value) async {
    await _service.toggleReminder(id, value);
    await _load();
  }

  Future<void> _delete(String id) async {
    await _service.deleteReminder(id);
    await _load();
  }

  Future<void> _showTimePicker(WaterReminder reminder) async {
    final initial = DateTime(2000, 1, 1, reminder.hour, reminder.minute);

    final result = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 280,
        color: CupertinoTheme.of(context).barBackgroundColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pop(context, _picked),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initial,
                use24hFormat: false,
                onDateTimeChanged: (dt) => _picked = dt,
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      reminder.hour = result.hour;
      reminder.minute = result.minute;
      await _service.updateReminder(reminder);
      await _load();
    }
  }

  DateTime _picked = DateTime(2000, 1, 1, 7, 0);

  Future<void> _addReminder() async {
    _picked = DateTime(2000, 1, 1, 7, 0);

    final result = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 280,
        color: CupertinoTheme.of(context).barBackgroundColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('Add',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pop(context, _picked),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _picked,
                use24hFormat: false,
                onDateTimeChanged: (dt) => _picked = dt,
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final reminder = WaterReminder(hour: result.hour, minute: result.minute);
      await _service.addReminder(reminder);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '\u{1F4A7} Water Reminders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _reminders.length,
                itemBuilder: (context, i) {
                  final r = _reminders[i];
                  return Dismissible(
                    key: ValueKey(r.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _delete(r.id),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          r.timeLabel,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w500),
                        ),
                        trailing: Transform.scale(
                          scale: 0.8,
                          child: CupertinoSwitch(
                            value: r.enabled,
                            activeColor: Colors.green,
                            onChanged: (v) => _toggle(r.id, v),
                          ),
                        ),
                        onTap: () => _showTimePicker(r),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add, color: Colors.green),
                label: const Text('Add Reminder',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
