import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health_tracker/ui/widgets/indicator_widget.dart';
import 'package:intl/intl.dart';

class WaterStatsScreen extends StatefulWidget {
  const WaterStatsScreen({Key? key}) : super(key: key);

  @override
  State<WaterStatsScreen> createState() => _WaterStatsScreenState();
}

class _WaterStatsScreenState extends State<WaterStatsScreen> {
  static const int waterGoal = 2000;

  Future<Map<String, int>> _getWeekWaterData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final now = DateTime.now();
    final Map<String, int> weekData = {};
    final List<int> weekOrder = [6, 5, 4, 3, 2, 1, 0];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: weekOrder[i]));
      final dateKey = DateFormat('d-M-y').format(date);
      final dayLabel = DateFormat('E').format(date);
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('diary')
            .doc(dateKey)
            .get();
        int water = 0;
        if (doc.exists && doc.data()!.containsKey('water')) {
          water = doc.get('water');
        }
        weekData[dayLabel] = water;
      } catch (e) {
        weekData[dayLabel] = 0;
      }
    }
    return weekData;
  }

  Future<Map<String, int>> _getMonthWaterData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final now = DateTime.now();
    final Map<String, int> monthData = {};

    for (int day = 1; day <= now.day; day++) {
      final date = DateTime(now.year, now.month, day);
      final dateKey = DateFormat('d-M-y').format(date);
      final dayLabel = '$day';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('diary')
            .doc(dateKey)
            .get();
        int water = 0;
        if (doc.exists && doc.data()!.containsKey('water')) {
          water = doc.get('water');
        }
        monthData[dayLabel] = water;
      } catch (e) {
        monthData[dayLabel] = 0;
      }
    }
    return monthData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _getAppBar(context),
      body: DefaultTabController(
        length: 3,
        initialIndex: 0,
        child: Column(children: [
          SizedBox(
            height: 36,
            child: TabBar(
              isScrollable: true,
              tabs: const [
                Tab(text: 'Week'),
                Tab(text: 'Month'),
                Tab(text: 'Year'),
              ],
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [
                    Color.fromARGB(255, 255, 88, 128),
                    Color.fromARGB(255, 250, 124, 108),
                  ])),
              labelPadding: const EdgeInsets.symmetric(horizontal: 40),
            ),
          ),
          Expanded(
              child: TabBarView(children: [
            _buildWeekTab(),
            _buildMonthTab(),
            _buildYearTab(),
          ]))
        ]),
      ),
    );
  }

  Widget _buildWeekTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<Map<String, int>>(
        future: _getWeekWaterData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const MyCircularIndicator();
          }
          final data = snapshot.data!;
          final todayWater = data[DateFormat('E').format(DateTime.now())] ?? 0;
          final total = data.values.fold<int>(0, (sum, v) => sum + v);
          final avgMl = data.isEmpty ? 0 : total ~/ data.length;
          final avgCups = (avgMl / 240).toStringAsFixed(1);

          return Column(
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    todayWater.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 36),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ml',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 139, 139, 139),
                        fontSize: 18),
                  ),
                  const Text(
                    ' today',
                    style: TextStyle(
                        color: Color.fromARGB(255, 139, 139, 139),
                        fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: BarChart(
                    BarChartData(
                        borderData: FlBorderData(show: false),
                        barGroups: _buildBarGroups(data),
                        maxY: 4000,
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(
                          show: true,
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  getTitlesWidget: leftTitles,
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 1)),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: bottomTitles,
                            reservedSize: 42,
                          )),
                          rightTitles: AxisTitles(),
                          topTitles: AxisTitles(),
                        )),
                  )),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildAverageCard(avgMl, avgCups)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildGoalCard(todayWater)),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<Map<String, int>>(
        future: _getMonthWaterData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const MyCircularIndicator();
          }
          final data = snapshot.data!;
          final total = data.values.fold<int>(0, (sum, v) => sum + v);
          final days = data.length;
          final avg = days == 0 ? 0 : total ~/ days;

          return Column(
            children: [
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Monthly Summary',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(height: 20),
                      _buildStatRow('Total', '$total ml'),
                      _buildStatRow('Average', '$avg ml/day'),
                      _buildStatRow('Days tracked', '$days days'),
                      _buildStatRow(
                          'Goal met',
                          '${data.values.where((v) => v >= waterGoal).length} days'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildYearTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Yearly Overview',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 16),
                  Text(
                    'Track your water intake daily to see yearly insights.',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.glassWater,
                          color: Colors.blue.shade400, size: 48),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, int> data) {
    final List<String> dayOrder = [
      'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
    ];
    final List<BarChartGroupData> groups = [];
    for (int i = 0; i < dayOrder.length; i++) {
      final value = data[dayOrder[i]]?.toDouble() ?? 0;
      groups.add(BarChartGroupData(x: i + 1, barRods: [
        BarChartRodData(
            width: 12,
            toY: value,
            gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.blue.shade800, Colors.blue.shade200]))
      ]));
    }
    return groups;
  }

  Widget _buildAverageCard(int avgMl, String avgCups) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(
                    child: Text('Average Intake',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20))),
                Align(
                    alignment: Alignment.centerRight,
                    child: Icon(FontAwesomeIcons.glassWater,
                        color: Colors.blue))
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Text(
                  avgCups,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const SizedBox(width: 4),
                Text(
                  'cups/day',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(int todayWater) {
    final progress = todayWater / waterGoal;
    final percent = (progress * 100).round().clamp(0, 100);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(
                    child: Text('Today Goal',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20))),
                Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.water_drop, color: Colors.blue))
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Text(
                  '$percent',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const SizedBox(width: 4),
                Text(
                  '%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$todayWater / $waterGoal ml',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _getAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      title: const Text('Water', style: TextStyle(fontSize: 20)),
      leading: TextButton(
          style: TextButton.styleFrom(shape: const CircleBorder()),
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.chevron_left, size: 34)),
    );
  }
}

Widget bottomTitles(double value, TitleMeta meta) {
  const style = TextStyle(
    color: Color.fromARGB(255, 191, 191, 191),
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  Widget text;
  switch (value.toInt()) {
    case 1:
      text = const Text('Sun', style: style);
      break;
    case 2:
      text = const Text('Mon', style: style);
      break;
    case 3:
      text = const Text('Tue', style: style);
      break;
    case 4:
      text = const Text('Wed', style: style);
      break;
    case 5:
      text = const Text('Thu', style: style);
      break;
    case 6:
      text = const Text('Fri', style: style);
      break;
    case 7:
      text = const Text('Sat', style: style);
      break;
    default:
      text = const Text('', style: style);
      break;
  }
  return Padding(padding: const EdgeInsets.only(top: 8.0), child: text);
}

Widget leftTitles(double value, TitleMeta meta) {
  const style = TextStyle(
    color: Color.fromARGB(255, 191, 191, 191),
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  String text;
  switch (value.toInt()) {
    case 0:
      text = '0';
      break;
    case 1000:
      text = '1';
      break;
    case 2000:
      text = '2';
      break;
    case 3000:
      text = '3';
      break;
    case 4000:
      text = '4';
      break;
    default:
      return Container();
  }
  return Text(text, style: style, textAlign: TextAlign.left);
}
