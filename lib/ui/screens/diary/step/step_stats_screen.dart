import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StepStatsScreen extends StatefulWidget {
  const StepStatsScreen({Key? key}) : super(key: key);

  @override
  State<StepStatsScreen> createState() => _StepStatsScreenState();
}

class _StepStatsScreenState extends State<StepStatsScreen> {
  DateTime _selectedDate = DateTime.now();
  int _todaySteps = 0;
  Map<String, int> _weeklySteps = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final Map<String, int> weekly = {};
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}_${date.month}_${date.day}';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('diary')
            .doc(dateKey)
            .get();
        
        if (doc.exists && doc.data() != null && doc.data()!.containsKey('totalSteps')) {
          weekly[dateKey] = doc.data()!['totalSteps'] as int;
        } else {
          weekly[dateKey] = 0;
        }
      } catch (e) {
        weekly[dateKey] = 0;
      }
    }

    final dateKey = '${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('diary')
          .doc(dateKey)
          .get();
      _todaySteps = (doc.exists && doc.data() != null && doc.data()!.containsKey('totalSteps'))
          ? doc.data()!['totalSteps'] as int
          : 0;
    } catch (e) {
      _todaySteps = 0;
    }

    if (mounted) {
      setState(() {
        _weeklySteps = weekly;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() => _selectedDate = date);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Steps', style: TextStyle(fontSize: 20)),
        leading: TextButton(
          style: TextButton.styleFrom(shape: const CircleBorder()),
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.chevron_left, size: 34),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                  _buildStatsCard(),
                  const SizedBox(height: 24),
                  _buildChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _selectDate,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selected Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      DateFormat('EEEE, d MMMM y').format(_selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Text(
                '$_todaySteps',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    const goal = 12000;
    final distance = _todaySteps ~/ 1400;
    final calories = _todaySteps ~/ 25;
    final percent = goal > 0 ? ((_todaySteps / goal) * 100).clamp(0, 100).toInt() : 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.directions_walk, '$_todaySteps', 'steps', Colors.blue),
            Container(width: 1, height: 50, color: Colors.grey.shade700),
            _buildStatItem(Icons.straighten, '$distance', 'km', Colors.green),
            Container(width: 1, height: 50, color: Colors.grey.shade700),
            _buildStatItem(Icons.local_fire_department, '$calories', 'kcal', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildChart() {
    final avgSteps = _weeklySteps.isNotEmpty
        ? (_weeklySteps.values.fold<int>(0, (sum, s) => sum + s) ~/ 7)
        : 0;
    final maxSteps = _weeklySteps.values.isEmpty ? 0 : _weeklySteps.values.reduce((a, b) => a > b ? a : b);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${(avgSteps ~/ 1000)}k avg',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: _weeklySteps.isEmpty
                  ? const Center(child: Text('No data'))
                  : LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _buildSpots(),
                            isCurved: true,
                            gradient: const LinearGradient(colors: [Colors.orange, Colors.pink]),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                final isToday = index == 6;
                                return FlDotCirclePainter(
                                  radius: isToday ? 6 : 3,
                                  color: Colors.orange,
                                  strokeWidth: 0,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.orange.withOpacity(0.3),
                                  Colors.pink.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                        minY: 0,
                        maxY: maxSteps > 0 ? maxSteps * 1.2 : 15000,
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(getTitlesWidget: _bottomTitles, reservedSize: 32)),
                          rightTitles: AxisTitles(),
                          topTitles: AxisTitles(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    final spots = <FlSpot>[];
    final values = _weeklySteps.values.toList();
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i].toDouble()));
    }
    return spots;
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final index = value.toInt();
    if (index >= 0 && index < 7) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(weekDays[index], style: const TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }
    return const Text('');
  }
}