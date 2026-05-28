import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health_tracker/shared/services/tree_service.dart';
import 'package:health_tracker/shared/services/water_reminder_service.dart';
import 'package:health_tracker/ui/screens/diary/water/water_reminder_sheet.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

class AddWaterScreen extends StatefulWidget {
  const AddWaterScreen({Key? key}) : super(key: key);

  @override
  State<AddWaterScreen> createState() => _AddWaterScreenState();
}

class _AddWaterScreenState extends State<AddWaterScreen> {
  static const int waterGoal = 2000;
  int waterValue = 0;

  @override
  void initState() {
    super.initState();
    fetchWaterValue();
  }

  Future<void> fetchWaterValue() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('diary')
          .doc(DateFormat('d-M-y').format(DateTime.now()))
          .get();
      if (doc.exists && doc.data()!.containsKey('water')) {
        setState(() {
          waterValue = doc.get('water');
        });
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> _saveWater() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('diary')
          .doc(DateFormat('d-M-y').format(DateTime.now()))
          .set({'water': waterValue}, SetOptions(merge: true));
    } catch (e) {
      log(e.toString());
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
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
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
        overlayEntry.remove();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text), backgroundColor: Colors.green.shade700),
        );
      }
    }
  }

  void _addWater() {
    final previousValue = waterValue;
    setState(() {
      waterValue += 250;
    });
    if (previousValue < 2000 && waterValue >= 2000) {
      TreeService().addWaterXp();
      _showSuccessToast('\u{1F4A7}  +10 XP');
    }
  }

  void _subtractWater() {
    setState(() {
      if (waterValue - 250 >= 0) {
        waterValue -= 250;
      } else {
        waterValue = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveWater();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Water'),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: () async {
                  await _saveWater();
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.check))
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(children: [
                      const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Today',
                            style: TextStyle(fontSize: 20),
                          )),
                      const SizedBox(height: 16),
                      LinearPercentIndicator(
                        linearGradient: LinearGradient(
                            colors: [Colors.blue.shade800, Colors.blue]),
                        lineHeight: 28,
                        percent: waterValue > waterGoal
                            ? 1
                            : waterValue / waterGoal,
                        animation: true,
                        animateFromLastPercent: true,
                        curve: Curves.bounceOut,
                        animationDuration: 800,
                        barRadius: const Radius.circular(24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$waterValue / $waterGoal ml',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                              onPressed: _subtractWater,
                              icon: const Icon(Icons.remove)),
                          Text('$waterValue ml',
                              style: const TextStyle(fontSize: 18)),
                          IconButton(
                              onPressed: _addWater,
                              icon: const Icon(Icons.add)),
                        ],
                      )
                    ])),
              ),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Reminders',
                              style: TextStyle(fontSize: 20)),
                          TextButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => const WaterReminderSheet(),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Manage'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _WaterReminderPreview(),
                    ],
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaterReminderPreview extends StatefulWidget {
  @override
  State<_WaterReminderPreview> createState() => _WaterReminderPreviewState();
}

class _WaterReminderPreviewState extends State<_WaterReminderPreview> {
  final WaterReminderService _service = WaterReminderService();
  List<WaterReminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.getReminders();
    if (!mounted) return;
    setState(() => _reminders = list);
  }

  Future<void> _toggle(String id, bool value) async {
    await _service.toggleReminder(id, value);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _reminders.where((r) => r.enabled).toList();
    if (enabled.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No reminders set. Tap Manage to add one.',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return Column(
      children: enabled.take(3).map((r) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Text('\u{1F4A7}', style: TextStyle(fontSize: 20)),
        title: Text(r.timeLabel,
            style: const TextStyle(fontSize: 16)),
        trailing: Transform.scale(
          scale: 0.7,
          child: CupertinoSwitch(
            value: true,
            activeColor: Colors.green,
            onChanged: (v) => _toggle(r.id, false),
          ),
        ),
      )).toList(),
    );
  }
}
