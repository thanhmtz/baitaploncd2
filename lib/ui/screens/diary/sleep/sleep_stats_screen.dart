import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SleepStatsScreen extends StatefulWidget {
  const SleepStatsScreen({Key? key}) : super(key: key);

  @override
  State<SleepStatsScreen> createState() => _SleepStatsScreenState();
}

class _SleepStatsScreenState extends State<SleepStatsScreen> {
  bool _isLoading = true;
  final List<double> _weekSleep = List.filled(7, 0.0);
  final List<double> _monthSleep = List.filled(4, 0.0);
  final List<double> _yearSleep = List.filled(12, 0.0);
  double _todaySleep = 0;
  double _avgSleep = 0;
  double _avgMonthSleep = 0;
  double _avgYearSleep = 0;

  @override
  void initState() {
    super.initState();
    _loadSleepData();
  }

  Future<void> _loadSleepData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      final todayKey = 'sleep_duration_${now.year}_${now.month}_${now.day}';
      _todaySleep = prefs.getDouble(todayKey) ?? 0;

      double total = 0;
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final key = 'sleep_duration_${date.year}_${date.month}_${date.day}';
        _weekSleep[6 - i] = prefs.getDouble(key) ?? 0;
        total += _weekSleep[6 - i];
      }
      _avgSleep = total / 7;

      double monthTotal = 0;
      for (int i = 0; i < 4; i++) {
        double weekSum = 0;
        for (int d = 0; d < 7; d++) {
          final date = now.subtract(Duration(days: i * 7 + d));
          final key = 'sleep_duration_${date.year}_${date.month}_${date.day}';
          weekSum += prefs.getDouble(key) ?? 0;
        }
        _monthSleep[3 - i] = weekSum / 7;
      }
      _avgMonthSleep = _monthSleep.reduce((a, b) => a + b) / 4;

      double yearTotal = 0;
      for (int m = 0; m < 12; m++) {
        final monthDate = DateTime(now.year, now.month - m, 1);
        final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
        double monthSum = 0;
        int count = 0;
        for (int d = 1; d <= daysInMonth; d++) {
          final date = DateTime(monthDate.year, monthDate.month, d);
          if (date.isAfter(now)) break;
          final key = 'sleep_duration_${date.year}_${date.month}_${date.day}';
          final val = prefs.getDouble(key) ?? 0;
          monthSum += val;
          if (val > 0) count++;
        }
        _yearSleep[11 - m] = count > 0 ? monthSum / count : 0;
      }
      _avgYearSleep = _yearSleep.reduce((a, b) => a + b) / 12;
    } catch (e) {
      debugPrint('Load sleep data error: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _getAppBar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              initialIndex: 0,
              child: Column(children: [
                SizedBox(
                  height: 36,
                  child: TabBar(
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Tuần'),
                      Tab(text: 'Tháng'),
                      Tab(text: 'Năm'),
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
                  Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                _avgSleep > 0
                                    ? _avgSleep.toStringAsFixed(1)
                                    : '0',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 36),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Giờ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 139, 139, 139),
                                    fontSize: 18),
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
                                    barGroups: List.generate(7, (i) {
                                      return BarChartGroupData(
                                          x: i + 1,
                                          barsSpace: 10,
                                          barRods: [
                                            BarChartRodData(
                                                width: 12,
                                                toY: _weekSleep[i],
                                                gradient: LinearGradient(
                                                    begin:
                                                        Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                    colors: [
                                                      Colors.orange.shade700,
                                                      Colors.amber,
                                                    ])),
                                          ]);
                                    }),
                                    maxY: 12,
                                    gridData:
                                        const FlGridData(show: false),
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
                              Expanded(
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {},
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          const Row(
                                            children: [
                                              Expanded(
                                                  child: Text(
                                                'Tổng giấc ngủ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),
                                              )),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Icon(
                                                  CupertinoIcons
                                                      .moon_stars_fill,
                                                  color: Color.fromARGB(
                                                      255, 255, 203, 51),
                                                ),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 32),
                                          Align(
                                            alignment:
                                                Alignment.centerLeft,
                                            child: Text(
                                              _todaySleep > 0
                                                  ? '${_todaySleep.toStringAsFixed(1)}h'
                                                  : 'Chưa ghi',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 24),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {},
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          const Row(
                                            children: [
                                              Expanded(
                                                  child: Text(
                                                'Ngủ sâu',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),
                                              )),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Icon(
                                                  FontAwesomeIcons.bed,
                                                  color: Color.fromARGB(
                                                      255, 152, 162, 255),
                                                ),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 32),
                                          Align(
                                            alignment:
                                                Alignment.centerLeft,
                                            child: Text(
                                              _todaySleep > 0
                                                  ? '${(_todaySleep * 0.4).toStringAsFixed(1)}h'
                                                  : '0h',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 24),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircularPercentIndicator(
                                    startAngle: 240,
                                    reverse: true,
                                    radius: 45,
                                    lineWidth: 7,
                                    animation: true,
                                    percent: _todaySleep > 0
                                        ? (_todaySleep / 8.0).clamp(0.0, 1.0)
                                        : 0,
                                    center: Text(
                                      _todaySleep > 0
                                          ? '${(_todaySleep / 8.0 * 100).toInt()}%'
                                          : '0%',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor:
                                        Colors.grey.shade800.withOpacity(0.3),
                                    linearGradient: const LinearGradient(
                                        colors: [
                                          Color.fromARGB(255, 255, 209, 59),
                                          Color.fromARGB(255, 248, 105, 51),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomLeft),
                                    circularStrokeCap:
                                        CircularStrokeCap.round,
                                  ),
                                  const Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding:
                                            EdgeInsets.only(left: 16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                              'Chất lượng giấc ngủ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ),
                                            SizedBox(height: 14),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                                Text('0 - 50% Kém'),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.orange,
                                                  size: 16,
                                                ),
                                                Text('50 - 70% Trung bình'),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.green,
                                                  size: 16,
                                                ),
                                                Text('Trên 70% Tốt'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          )
                        ],
                      )),
                  // MONTH TAB
                  Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                _avgMonthSleep > 0
                                    ? _avgMonthSleep.toStringAsFixed(1)
                                    : '0',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 36),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Giờ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 139, 139, 139),
                                    fontSize: 18),
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
                                    barGroups: List.generate(4, (i) {
                                      return BarChartGroupData(
                                          x: i + 1,
                                          barsSpace: 10,
                                          barRods: [
                                            BarChartRodData(
                                                width: 16,
                                                toY: _monthSleep[i],
                                                gradient: LinearGradient(
                                                    begin:
                                                        Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                    colors: [
                                                      Colors.orange.shade700,
                                                      Colors.amber,
                                                    ])),
                                          ]);
                                    }),
                                    maxY: 12,
                                    gridData:
                                        const FlGridData(show: false),
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
                                        getTitlesWidget: monthBottomTitles,
                                        reservedSize: 42,
                                      )),
                                      rightTitles: AxisTitles(),
                                      topTitles: AxisTitles(),
                                    )),
                              )),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Row(
                                          children: [
                                            Expanded(
                                                child: Text(
                                              'Tổng giấc ngủ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20),
                                            )),
                                            Align(
                                              alignment:
                                                  Alignment.centerRight,
                                              child: Icon(
                                                CupertinoIcons.moon_stars_fill,
                                                color: Color.fromARGB(
                                                    255, 255, 203, 51),
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 32),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _avgMonthSleep > 0
                                                ? '${_avgMonthSleep.toStringAsFixed(1)}h'
                                                : 'Chưa ghi',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 24),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                  // YEAR TAB
                  Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                _avgYearSleep > 0
                                    ? _avgYearSleep.toStringAsFixed(1)
                                    : '0',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 36),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Giờ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 139, 139, 139),
                                    fontSize: 18),
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
                                    barGroups: List.generate(12, (i) {
                                      return BarChartGroupData(
                                          x: i + 1,
                                          barsSpace: 10,
                                          barRods: [
                                            BarChartRodData(
                                                width: 8,
                                                toY: _yearSleep[i],
                                                gradient: LinearGradient(
                                                    begin:
                                                        Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                    colors: [
                                                      Colors.orange.shade700,
                                                      Colors.amber,
                                                    ])),
                                          ]);
                                    }),
                                    maxY: 12,
                                    gridData:
                                        const FlGridData(show: false),
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
                                        getTitlesWidget: yearBottomTitles,
                                        reservedSize: 42,
                                      )),
                                      rightTitles: AxisTitles(),
                                      topTitles: AxisTitles(),
                                    )),
                              )),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Row(
                                          children: [
                                            Expanded(
                                                child: Text(
                                              'Tổng giấc ngủ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20),
                                            )),
                                            Align(
                                              alignment:
                                                  Alignment.centerRight,
                                              child: Icon(
                                                CupertinoIcons.moon_stars_fill,
                                                color: Color.fromARGB(
                                                    255, 255, 203, 51),
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 32),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _avgYearSleep > 0
                                                ? '${_avgYearSleep.toStringAsFixed(1)}h'
                                                : 'Chưa ghi',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 24),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                ]))
              ]),
            ),
    );
  }

  AppBar _getAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      title: const Text(
        'Giấc ngủ',
        style: TextStyle(fontSize: 20),
      ),
      leading: TextButton(
          style: TextButton.styleFrom(
            shape: const CircleBorder(),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.chevron_left,
            size: 34,
          )),
      actions: [
        TextButton(
            style: TextButton.styleFrom(
              shape: const CircleBorder(),
            ),
            onPressed: () {},
            child: const Icon(
              Icons.settings,
              size: 28,
            )),
      ],
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
      text = const Text('CN', style: style);
      break;
    case 2:
      text = const Text('T2', style: style);
      break;
    case 3:
      text = const Text('T3', style: style);
      break;
    case 4:
      text = const Text('T4', style: style);
      break;
    case 5:
      text = const Text('T5', style: style);
      break;
    case 6:
      text = const Text('T6', style: style);
      break;
    case 7:
      text = const Text('T7', style: style);
      break;
    default:
      text = const Text('', style: style);
      break;
  }

  return Padding(padding: const EdgeInsets.only(top: 8.0), child: text);
}

Widget monthBottomTitles(double value, TitleMeta meta) {
  const style = TextStyle(
    color: Color.fromARGB(255, 191, 191, 191),
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  final labels = ['T1', 'T2', 'T3', 'T4'];
  final idx = value.toInt() - 1;
  return Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Text(idx >= 0 && idx < labels.length ? labels[idx] : '', style: style),
  );
}

Widget yearBottomTitles(double value, TitleMeta meta) {
  const style = TextStyle(
    color: Color.fromARGB(255, 191, 191, 191),
    fontWeight: FontWeight.bold,
    fontSize: 11,
  );
  final labels = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
  final idx = value.toInt() - 1;
  return Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Text(idx >= 0 && idx < labels.length ? labels[idx] : '', style: style),
  );
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
    case 2:
      text = '02';
      break;
    case 4:
      text = '04';
      break;
    case 6:
      text = '06';
      break;
    case 8:
      text = '08';
      break;
    default:
      return Container();
  }

  return Text(text, style: style, textAlign: TextAlign.left);
}
