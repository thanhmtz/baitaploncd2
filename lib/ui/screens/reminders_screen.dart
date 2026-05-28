import 'package:flutter/material.dart';
import 'package:health_tracker/shared/services/reminder_service.dart';
import 'package:intl/intl.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderService _service = ReminderService();
  List<Reminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.getReminders();
    setState(() {
      _reminders = list;
      _loading = false;
    });
  }

  Future<void> _toggle(Reminder r) async {
    await _service.toggleReminder(r.id, !r.enabled);
    await _load();
  }

  Future<void> _editTime(Reminder r) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: r.time,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    await _service.updateReminder(r.copyWith(
      hour: picked.hour,
      minute: picked.minute,
    ));
    await _load();
  }

  Future<void> _delete(Reminder r) async {
    await _service.deleteReminder(r.id);
    await _load();
  }

  Future<void> _addCustom() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;

    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Reminder'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Reminder name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    await _service.addReminder(Reminder(
      title: name.trim(),
      subtitle: 'Nhắc nhở hàng ngày',
      hour: picked.hour,
      minute: picked.minute,
    ));
    await _load();
  }

  String _formatTime(int hour, int minute) {
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Health Reminders'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustom,
        backgroundColor: const Color(0xFF4A90D9),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No reminders yet',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a health reminder',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final r = _reminders[index];
        return _ReminderCard(
          reminder: r,
          timeText: _formatTime(r.hour, r.minute),
          onToggle: () => _toggle(r),
          onTap: () => _editTime(r),
          onDelete: () => _delete(r),
        );
      },
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final String timeText;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.timeText,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = reminder.enabled ? 1.0 : 0.4;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Opacity(
        opacity: opacity,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: reminder.enabled
                              ? Colors.black87
                              : Colors.grey.shade400,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: reminder.enabled
                              ? Colors.black87
                              : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reminder.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: reminder.enabled
                              ? Colors.grey.shade500
                              : Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Switch.adaptive(
                    value: reminder.enabled,
                    activeColor: const Color(0xFF4A90D9),
                    onChanged: (_) => onToggle(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
