import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:health_tracker/data/models/blood_pressure_model.dart';
import 'package:intl/intl.dart';

class BloodPressureStatsScreen extends StatefulWidget {
  const BloodPressureStatsScreen({Key? key}) : super(key: key);

  @override
  State<BloodPressureStatsScreen> createState() =>
      _BloodPressureStatsScreenState();
}

class _BloodPressureStatsScreenState extends State<BloodPressureStatsScreen> {
  String _selectedPeriod = 'Week';
  late Future<List<BloodPressure>> _readingsFuture;

  @override
  void initState() {
    super.initState();
    _readingsFuture = _fetchAllReadings();
  }

  void _reload() {
    setState(() {
      _readingsFuture = _fetchAllReadings();
    });
  }

  Future<void> _refresh() async {
    final future = _fetchAllReadings();
    setState(() {
      _readingsFuture = future;
    });
    await future;
  }

  Future<List<BloodPressure>> _fetchAllReadings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diary')
        .get();

    final allReadings = <BloodPressure>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final bpData = data['bloodPressure'];

      if (bpData is! List || bpData.isEmpty) continue;

      final docDate = _parseDiaryDate(doc.id);

      for (final item in bpData) {
        if (item is! Map) continue;

        try {
          allReadings.add(
            BloodPressure.fromJson(
              Map<String, dynamic>.from(item),
              date: docDate,
            ),
          );
        } catch (_) {
          continue;
        }
      }
    }

    allReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return allReadings;
  }

  DateTime _parseDiaryDate(String docId) {
    final formats = [
      'd-M-y',
      'd-M-yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'd/M/y',
      'dd/MM/yyyy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parseStrict(docId);
      } catch (_) {}
    }

    return DateTime.now();
  }

  List<BloodPressure> _readingsInRange(
    List<BloodPressure> readings,
    _DateRange range,
  ) {
    return readings.where((reading) {
      final time = reading.timestamp;
      return !time.isBefore(range.start) && time.isBefore(range.end);
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  int _averageInt(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return (list.reduce((a, b) => a + b) / list.length).round();
  }

  double _averageDouble(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  String _compareText({
    required int currentSys,
    required int currentDia,
    required int? previousSys,
    required int? previousDia,
    required String previousLabel,
  }) {
    if (previousSys == null || previousDia == null) {
      return 'Chưa có dữ liệu $previousLabel để so sánh.';
    }

    final sysDelta = currentSys - previousSys;
    final diaDelta = currentDia - previousDia;

    if (sysDelta.abs() <= 2 && diaDelta.abs() <= 2) {
      return 'Trung bình gần như không đổi so với $previousLabel.';
    }

    final sysText = sysDelta > 0 ? '+$sysDelta' : '$sysDelta';
    final diaText = diaDelta > 0 ? '+$diaDelta' : '$diaDelta';

    return 'So với $previousLabel: tâm thu $sysText mmHg, tâm trương $diaText mmHg.';
  }

  String _trendText(List<BloodPressure> readings) {
    if (readings.length < 2) {
      return 'Thêm ít nhất 2 lần đo trong kỳ để xem xu hướng thay đổi.';
    }

    final latest = readings.last;
    final previous = readings[readings.length - 2];

    final sysDelta = latest.systolic - previous.systolic;
    final diaDelta = latest.diastolic - previous.diastolic;

    if (sysDelta.abs() <= 3 && diaDelta.abs() <= 3) {
      return 'Chỉ số khá ổn định so với lần đo trước trong kỳ.';
    }

    final sysText = sysDelta > 0 ? '+$sysDelta' : '$sysDelta';
    final diaText = diaDelta > 0 ? '+$diaDelta' : '$diaDelta';

    return 'So với lần trước trong kỳ: tâm thu $sysText mmHg, tâm trương $diaText mmHg.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê huyết áp'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _buildPeriodChip('Week', 'Tuần'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Month', 'Tháng'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Year', 'Năm'),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<BloodPressure>>(
                future: _readingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _reload,
                    );
                  }

                  final allReadings = snapshot.data ?? [];
                  final currentRange = _currentRange(_selectedPeriod);
                  final previousRange = _previousRange(_selectedPeriod);

                  final readings = _readingsInRange(allReadings, currentRange);
                  final previousReadings =
                      _readingsInRange(allReadings, previousRange);

                  if (readings.isEmpty) {
                    return _EmptyState(
                      periodLabel: currentRange.label,
                      onRetry: _reload,
                    );
                  }

                  final latest = readings.last;
                  final latestLevel =
                      _bpLevelFor(latest.systolic, latest.diastolic);

                  final avgSystolic =
                      _averageInt(readings.map((e) => e.systolic));
                  final avgDiastolic =
                      _averageInt(readings.map((e) => e.diastolic));
                  final avgPulse = _averageInt(readings.map((e) => e.pulse));
                  final avgLevel = _bpLevelFor(avgSystolic, avgDiastolic);

                  final previousAvgSystolic = previousReadings.isEmpty
                      ? null
                      : _averageInt(previousReadings.map((e) => e.systolic));
                  final previousAvgDiastolic = previousReadings.isEmpty
                      ? null
                      : _averageInt(previousReadings.map((e) => e.diastolic));

                  final avgMap = _averageDouble(
                    readings.map(
                      (e) => _meanArterialPressure(
                        e.systolic,
                        e.diastolic,
                      ),
                    ),
                  );

                  final avgPulsePressure = _averageInt(
                    readings.map(
                      (e) => _pulsePressure(
                        e.systolic,
                        e.diastolic,
                      ),
                    ),
                  );

                  final monthlyChartPoints =
                      _buildMonthlyAveragePoints(allReadings);
                  final yearlyChartPoints =
                      _buildYearlyAveragePoints(allReadings);

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _PeriodSummaryCard(
                          label: currentRange.label,
                          count: readings.length,
                          avgSystolic: avgSystolic,
                          avgDiastolic: avgDiastolic,
                          previousAvgSystolic: previousAvgSystolic,
                          previousAvgDiastolic: previousAvgDiastolic,
                          previousLabel: previousRange.shortLabel,
                          level: avgLevel,
                          compareText: _compareText(
                            currentSys: avgSystolic,
                            currentDia: avgDiastolic,
                            previousSys: previousAvgSystolic,
                            previousDia: previousAvgDiastolic,
                            previousLabel: previousRange.shortLabel,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _LatestBpCard(
                          latest: latest,
                          level: latestLevel,
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth = constraints.maxWidth < 340
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 12) / 2;

                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: itemWidth,
                                  child: _MetricCard(
                                    icon: Icons.monitor_heart_rounded,
                                    label: 'Huyết áp TB',
                                    value: '$avgSystolic/$avgDiastolic',
                                    sub: 'mmHg',
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _MetricCard(
                                    icon: Icons.water_drop_rounded,
                                    label: 'MAP TB',
                                    value: avgMap.toStringAsFixed(0),
                                    sub: 'mmHg',
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _MetricCard(
                                    icon: Icons.compare_arrows_rounded,
                                    label: 'Pulse Pressure TB',
                                    value: '$avgPulsePressure',
                                    sub: 'mmHg',
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _MetricCard(
                                    icon: Icons.favorite_rounded,
                                    label: 'Nhịp tim TB',
                                    value: '$avgPulse',
                                    sub: 'bpm',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _InsightCard(
                          level: avgLevel,
                          trendText: _trendText(readings),
                        ),
                        const SizedBox(height: 14),
                        _FormulaCard(
                          systolic: avgSystolic,
                          diastolic: avgDiastolic,
                        ),
                        const SizedBox(height: 14),

                        const _SectionTitle(title: 'Biểu đồ huyết áp'),
                        const SizedBox(height: 10),

                        if (_selectedPeriod == 'Week')
                          (readings.length > 1)
                              ? _BpChartCard(readings: readings)
                              : const _NeedMoreDataCard(),

                        if (_selectedPeriod == 'Month')
                          (monthlyChartPoints.isNotEmpty)
                              ? _AverageBpChartCard(points: monthlyChartPoints)
                              : const _NeedMoreDataCard(
                                  message:
                                      'Chưa có dữ liệu để hiển thị biểu đồ trung bình theo tháng.',
                                ),

                        if (_selectedPeriod == 'Year')
                          (yearlyChartPoints.isNotEmpty)
                              ? _AverageBpChartCard(points: yearlyChartPoints)
                              : const _NeedMoreDataCard(
                                  message:
                                      'Chưa có dữ liệu để hiển thị biểu đồ trung bình theo năm.',
                                ),

                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'Lịch sử đo chi tiết'),
                        const SizedBox(height: 10),
                        ...readings.reversed.take(50).map(
                              (bp) => _ReadingTile(bp: bp),
                            ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    final selected = _selectedPeriod == period;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.16),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withOpacity(0.72),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodSummaryCard extends StatelessWidget {
  const _PeriodSummaryCard({
    required this.label,
    required this.count,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.previousAvgSystolic,
    required this.previousAvgDiastolic,
    required this.previousLabel,
    required this.level,
    required this.compareText,
  });

  final String label;
  final int count;
  final int avgSystolic;
  final int avgDiastolic;
  final int? previousAvgSystolic;
  final int? previousAvgDiastolic;
  final String previousLabel;
  final _BpLevel level;
  final String compareText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: level.color.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: level.color.withOpacity(0.12),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.analytics_rounded, color: level.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Trung bình $label',
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
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
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
                  '$avgSystolic',
                  style: TextStyle(
                    fontSize: 58,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    color: level.color,
                  ),
                ),
                Text(
                  '/$avgDiastolic',
                  style: TextStyle(
                    fontSize: 38,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface.withOpacity(0.82),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'mmHg',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.52),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count lần đo • $compareText',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.66),
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (previousAvgSystolic != null && previousAvgDiastolic != null) ...[
            const SizedBox(height: 8),
            Text(
              '$previousLabel: $previousAvgSystolic/$previousAvgDiastolic mmHg',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.50),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LatestBpCard extends StatelessWidget {
  const _LatestBpCard({
    required this.latest,
    required this.level,
  });

  final BloodPressure latest;
  final _BpLevel level;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final map = _meanArterialPressure(latest.systolic, latest.diastolic);
    final pp = _pulsePressure(latest.systolic, latest.diastolic);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(level.icon, color: level.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lần đo mới nhất trong kỳ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                level.label,
                style: TextStyle(
                  color: level.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${latest.systolic}',
                  style: TextStyle(
                    fontSize: 42,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    color: level.color,
                  ),
                ),
                Text(
                  '/${latest.diastolic}',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface.withOpacity(0.82),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 6),
                  child: Text(
                    'mmHg',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.52),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _SmallInfoChip(
                icon: Icons.favorite_rounded,
                label: '${latest.pulse} bpm',
              ),
              _SmallInfoChip(
                icon: Icons.water_drop_rounded,
                label: 'MAP ${map.toStringAsFixed(0)}',
              ),
              _SmallInfoChip(
                icon: Icons.compare_arrows_rounded,
                label: 'PP $pp',
              ),
              _SmallInfoChip(
                icon: Icons.calendar_month_rounded,
                label: DateFormat('dd/MM/yyyy').format(latest.timestamp),
              ),
              _SmallInfoChip(
                icon: Icons.schedule_rounded,
                label: DateFormat('HH:mm').format(latest.timestamp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const Spacer(),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.48),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.level,
    required this.trendText,
  });

  final _BpLevel level;
  final String trendText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  'Gợi ý theo trung bình trong kỳ',
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
              color: colorScheme.onSurface.withOpacity(0.78),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: level.color.withOpacity(0.18)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trendText,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({
    required this.systolic,
    required this.diastolic,
  });

  final int systolic;
  final int diastolic;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pp = _pulsePressure(systolic, diastolic);
    final map = _meanArterialPressure(systolic, diastolic);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.functions_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Công thức theo trung bình',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth < 360
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _FormulaTile(
                      title: 'MAP',
                      formula: '($systolic + 2 × $diastolic) / 3',
                      value: map.toStringAsFixed(0),
                      unit: 'mmHg',
                      icon: Icons.water_drop_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _FormulaTile(
                      title: 'Pulse Pressure',
                      formula: '$systolic - $diastolic',
                      value: '$pp',
                      unit: 'mmHg',
                      icon: Icons.compare_arrows_rounded,
                      color: const Color(0xFF7E57C2),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'MAP = áp lực động mạch trung bình. Pulse Pressure = hiệu số giữa huyết áp tâm thu và tâm trương. Các công thức chỉ hỗ trợ theo dõi xu hướng.',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.58),
              height: 1.35,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaTile extends StatelessWidget {
  const _FormulaTile({
    required this.title,
    required this.formula,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String title;
  final String formula;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formula,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.56),
              fontSize: 12,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.52),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Biểu đồ mới theo style cột dọc như mẫu:
/// - Không dùng nhiều nhãn trên trục X để tránh dính chữ.
/// - Mỗi cột là khoảng huyết áp: từ tâm trương lên tâm thu.
/// - Màu dùng theo theme app, không sao chép màu mẫu.
class _BpChartCard extends StatelessWidget {
  const _BpChartCard({required this.readings});

  final List<BloodPressure> readings;

  @override
  Widget build(BuildContext context) {
    final points = readings.asMap().entries.map((entry) {
      final bp = entry.value;

      return _BpChartPoint(
        x: entry.key.toDouble(),
        systolic: bp.systolic,
        diastolic: bp.diastolic,
        pulse: bp.pulse,
        label: DateFormat('d/M').format(bp.timestamp),
      );
    }).toList();

    return _BpRangeChartCard(points: points);
  }
}

class _AverageBpChartCard extends StatelessWidget {
  const _AverageBpChartCard({required this.points});

  final List<_BpChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return _BpRangeChartCard(points: points);
  }
}

class _BpRangeChartCard extends StatelessWidget {
  const _BpRangeChartCard({required this.points});

  final List<_BpChartPoint> points;

  int _averageInt(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return (list.reduce((a, b) => a + b) / list.length).round();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final avgSystolic = _averageInt(points.map((e) => e.systolic));
    final avgDiastolic = _averageInt(points.map((e) => e.diastolic));
    final pulseValues = points
        .where((e) => e.pulse != null)
        .map((e) => e.pulse!)
        .toList(growable: false);
    final avgPulse = pulseValues.isEmpty ? null : _averageInt(pulseValues);

    return Container(
      height: 440,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ChartTopValue(
                  title: 'Tâm thu',
                  value: '$avgSystolic',
                  unit: 'mmHg',
                ),
              ),
              Expanded(
                child: _ChartTopValue(
                  title: 'Tâm trương',
                  value: '$avgDiastolic',
                  unit: 'mmHg',
                ),
              ),
              Expanded(
                child: _ChartTopValue(
                  title: 'Xung',
                  value: avgPulse == null ? '--' : '$avgPulse',
                  unit: 'BPM',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _BpChartColorLegend(),
          const SizedBox(height: 8),
         Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = math.max(
                constraints.maxWidth,
                70 + points.length * 42.0,
              );

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: chartWidth,
                  height: constraints.maxHeight,
                  child: CustomPaint(
                    painter: _BpRangeChartPainter(
                      points: points,
                      lowColor: const Color(0xFF039BE5),
                      normalColor: const Color(0xFF43A047),
                      elevatedColor: const Color(0xFFFB8C00),
                      highColor: const Color(0xFFE53935),
                      urgentColor: const Color(0xFFD32F2F),
                      gridColor: colorScheme.outline.withOpacity(0.22),
                      textColor: colorScheme.onSurface.withOpacity(0.58),
                      strongTextColor: colorScheme.onSurface.withOpacity(0.74),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        ],
      ),
    );
  }
}

class _ChartTopValue extends StatelessWidget {
  const _ChartTopValue({
    required this.title,
    required this.value,
    required this.unit,
  });

  final String title;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.48),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}


class _BpChartColorLegend extends StatelessWidget {
  const _BpChartColorLegend();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _BpLegendItem(
              color: Color(0xFF039BE5),
              label: 'Thấp',
            ),
            SizedBox(width: 8),
            _BpLegendItem(
              color: Color(0xFF43A047),
              label: 'Bình thường',
            ),
            SizedBox(width: 8),
            _BpLegendItem(
              color: Color(0xFFFB8C00),
              label: 'Tăng nhẹ',
            ),
            SizedBox(width: 8),
            _BpLegendItem(
              color: Color(0xFFE53935),
              label: 'Cao',
            ),
            SizedBox(width: 8),
            _BpLegendItem(
              color: Color(0xFFD32F2F),
              label: 'Rất cao',
            ),
          ],
        ),
      ),
    );
  }
}

class _BpLegendItem extends StatelessWidget {
  const _BpLegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.68),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BpRangeChartPainter extends CustomPainter {
  const _BpRangeChartPainter({
    required this.points,
    required this.lowColor,
    required this.normalColor,
    required this.elevatedColor,
    required this.highColor,
    required this.urgentColor,
    required this.gridColor,
    required this.textColor,
    required this.strongTextColor,
  });

  final List<_BpChartPoint> points;
  final Color lowColor;
  final Color normalColor;
  final Color elevatedColor;
  final Color highColor;
  final Color urgentColor;
  final Color gridColor;
  final Color textColor;
  final Color strongTextColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const left = 48.0;
    const right = 18.0;
    const top = 12.0;
    const bottom = 56.0;

    final plotWidth = math.max(1.0, size.width - left - right);
    final plotHeight = math.max(1.0, size.height - top - bottom);

    final minData =
        points.map((e) => e.diastolic).reduce((a, b) => a < b ? a : b);
    final maxData =
        points.map((e) => e.systolic).reduce((a, b) => a > b ? a : b);

    final minY = math.max(0, ((minData - 10) / 10).floor() * 10).toDouble();
    final maxY = (((maxData + 10) / 10).ceil() * 10).toDouble();

    double yFor(double value) {
      if (maxY == minY) return top + plotHeight;
      return top + ((maxY - value) / (maxY - minY)) * plotHeight;
    }

    double xFor(int index) {
      if (points.length == 1) return left + plotWidth / 2;
      return left + (plotWidth / (points.length - 1)) * index;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = gridColor.withOpacity(0.75)
      ..strokeWidth = 1;

    final barPaint = Paint()
  ..strokeWidth = points.length <= 1
      ? 28
      : points.length <= 4
          ? 24
          : 18
  ..strokeCap = StrokeCap.round;

    final valuesForAxis = _axisValues(minY, maxY);

    for (final value in valuesForAxis) {
      final y = yFor(value);
      _drawDashedLine(
        canvas,
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );

      _drawText(
        canvas,
        value.toInt().toString(),
        Offset(0, y - 8),
        textColor,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      );
    }

    final baseY = yFor(minY);
    canvas.drawLine(
      Offset(left, baseY),
      Offset(size.width - right, baseY),
      axisPaint,
    );

    final showValueLabels = points.length <= 4;
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x = xFor(i);
      final topY = yFor(point.systolic.toDouble());
      final bottomY = yFor(point.diastolic.toDouble());

      barPaint.color = _barColorFor(point.systolic, point.diastolic);

      canvas.drawLine(
        Offset(x, bottomY),
        Offset(x, topY),
        barPaint,
      );

      if (showValueLabels && (bottomY - topY).abs() >= 30) {
        _drawCenteredText(
          canvas,
          '${point.systolic}',
          Offset(x, topY - 24),
          strongTextColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        );

        _drawCenteredText(
          canvas,
          '${point.diastolic}',
          Offset(x, bottomY + 10),
          textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        );
      }

      final middleIndex = ((points.length - 1) / 2).round();
      final quarterIndex = ((points.length - 1) / 4).round();
      final threeQuarterIndex = (((points.length - 1) * 3) / 4).round();

     final labelEvery = points.length <= 6 ? 1 : (points.length / 4).ceil();

      final showXAxisLabel = i == 0 ||
          i == points.length - 1 ||
          i % labelEvery == 0;

      if (showXAxisLabel) {
        _drawCenteredText(
          canvas,
          point.label,
          Offset(x, size.height - 28),
          textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        );
      }
    }
  }

  Color _barColorFor(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) {
      return urgentColor;
    }

    if (systolic >= 140 || diastolic >= 90) {
      return highColor;
    }

    if ((systolic >= 120 && systolic <= 139) ||
        (diastolic >= 70 && diastolic <= 89)) {
      return elevatedColor;
    }

    if (systolic < 90 || diastolic < 60) {
      return lowColor;
    }

    return normalColor;
  }

  List<double> _axisValues(double minY, double maxY) {
    final span = math.max(1.0, maxY - minY);
    final rawStep = span / 4;
    final step = math.max(10, (rawStep / 10).ceil() * 10).toDouble();

    final values = <double>[];
    var value = maxY;

    while (value >= minY - 0.001) {
      values.add(value);
      value -= step;
    }

    // Không thêm nhãn minY nếu nó quá gần nhãn cuối.
    // Cách này tránh lỗi hiển thị kiểu 140 và 130 dính sát nhau.
    if (values.length < 4) {
      final candidate = minY;
      if (values.isEmpty || (values.last - candidate).abs() >= step * 0.65) {
        values.add(candidate);
      }
    }

    return values;
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashWidth = 4.0;
    const dashSpace = 5.0;

    final totalDistance = (end - start).distance;
    final direction = (end - start) / totalDistance;

    var currentDistance = 0.0;

    while (currentDistance < totalDistance) {
      final nextDistance = math.min(
        currentDistance + dashWidth,
        totalDistance,
      );

      canvas.drawLine(
        start + direction * currentDistance,
        start + direction * nextDistance,
        paint,
      );

      currentDistance += dashWidth + dashSpace;
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    painter.paint(canvas, offset);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    Color color, {
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _BpRangeChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lowColor != lowColor ||
        oldDelegate.normalColor != normalColor ||
        oldDelegate.elevatedColor != elevatedColor ||
        oldDelegate.highColor != highColor ||
        oldDelegate.urgentColor != urgentColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.strongTextColor != strongTextColor;
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.bp});

  final BloodPressure bp;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = _bpLevelFor(bp.systolic, bp.diastolic);
    final hasNote = bp.notes != null && bp.notes!.trim().isNotEmpty;
    final map = _meanArterialPressure(bp.systolic, bp.diastolic);
    final pp = _pulsePressure(bp.systolic, bp.diastolic);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: level.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(level.icon, color: level.color),
        ),
        title: Text(
          '${bp.systolic}/${bp.diastolic} mmHg — ${level.label}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Ngày đo: ${DateFormat('dd/MM/yyyy').format(bp.timestamp)} • Giờ: ${DateFormat('HH:mm').format(bp.timestamp)}\n'
            'Nhịp tim: ${bp.pulse} bpm • MAP ${map.toStringAsFixed(0)} • PP $pp',
            style: TextStyle(
              height: 1.35,
              color: colorScheme.onSurface.withOpacity(0.64),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: hasNote
            ? Tooltip(
                message: bp.notes!,
                child: const Icon(Icons.sticky_note_2_rounded, size: 20),
              )
            : null,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.periodLabel,
    required this.onRetry,
  });

  final String periodLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 90),
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
          ),
          child: Column(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monitor_heart_rounded,
                  size: 42,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Chưa có dữ liệu huyết áp',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chưa tìm thấy lần đo nào trong $periodLabel. Hãy thêm chỉ số mới để xem biểu đồ, xu hướng và gợi ý sức khỏe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.4,
                  color: colorScheme.onSurface.withOpacity(0.62),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tải lại dữ liệu'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colorScheme.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.error.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Không tải được dữ liệu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.62),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedMoreDataCard extends StatelessWidget {
  const _NeedMoreDataCard({
    this.message = 'Thêm ít nhất 2 lần đo để hiển thị biểu đồ xu hướng.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.62),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
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

class _DateRange {
  const _DateRange({
    required this.start,
    required this.end,
    required this.label,
    required this.shortLabel,
  });

  final DateTime start;
  final DateTime end;
  final String label;
  final String shortLabel;
}

class _BpChartPoint {
  const _BpChartPoint({
    required this.x,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    required this.label,
  });

  final double x;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final String label;
}

_DateRange _currentRange(String period) {
  final now = DateTime.now();

  if (period == 'Year') {
    return _DateRange(
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year + 1, 1, 1),
      label: 'năm nay',
      shortLabel: 'năm nay',
    );
  }

  if (period == 'Month') {
    return _DateRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 1),
      label: 'tháng này',
      shortLabel: 'tháng này',
    );
  }

  final startOfToday = DateTime(now.year, now.month, now.day);
  final weekStart = startOfToday.subtract(
    Duration(days: now.weekday - DateTime.monday),
  );

  return _DateRange(
    start: weekStart,
    end: weekStart.add(const Duration(days: 7)),
    label: 'tuần này',
    shortLabel: 'tuần này',
  );
}

_DateRange _previousRange(String period) {
  final current = _currentRange(period);

  if (period == 'Year') {
    return _DateRange(
      start: DateTime(current.start.year - 1, 1, 1),
      end: current.start,
      label: 'năm trước',
      shortLabel: 'năm trước',
    );
  }

  if (period == 'Month') {
    return _DateRange(
      start: DateTime(current.start.year, current.start.month - 1, 1),
      end: current.start,
      label: 'tháng trước',
      shortLabel: 'tháng trước',
    );
  }

  return _DateRange(
    start: current.start.subtract(const Duration(days: 7)),
    end: current.start,
    label: 'tuần trước',
    shortLabel: 'tuần trước',
  );
}

List<_BpChartPoint> _buildMonthlyAveragePoints(
  List<BloodPressure> readings,
) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 11, 1);
  final end = DateTime(now.year, now.month + 1, 1);
  final grouped = <DateTime, List<BloodPressure>>{};

  for (final reading in readings) {
    final time = reading.timestamp;
    final key = DateTime(time.year, time.month, 1);

    if (key.isBefore(start) || !key.isBefore(end)) continue;

    grouped.putIfAbsent(key, () => <BloodPressure>[]).add(reading);
  }

  return _buildChartPointsFromGroups(
    grouped,
    labelBuilder: (key) => DateFormat('MM/yy').format(key),
  );
}

List<_BpChartPoint> _buildYearlyAveragePoints(
  List<BloodPressure> readings,
) {
  final grouped = <DateTime, List<BloodPressure>>{};

  for (final reading in readings) {
    final time = reading.timestamp;
    final key = DateTime(time.year, 1, 1);
    grouped.putIfAbsent(key, () => <BloodPressure>[]).add(reading);
  }

  return _buildChartPointsFromGroups(
    grouped,
    labelBuilder: (key) => DateFormat('yyyy').format(key),
  );
}

List<_BpChartPoint> _buildChartPointsFromGroups(
  Map<DateTime, List<BloodPressure>> grouped, {
  required String Function(DateTime key) labelBuilder,
}) {
  final keys = grouped.keys.toList()..sort();

  return keys.asMap().entries.map((entry) {
    final index = entry.key;
    final key = entry.value;
    final values = grouped[key]!;

    final avgSystolic = (values
                .map((e) => e.systolic)
                .reduce((a, b) => a + b) /
            values.length)
        .round();

    final avgDiastolic = (values
                .map((e) => e.diastolic)
                .reduce((a, b) => a + b) /
            values.length)
        .round();

    final avgPulse = (values
                .map((e) => e.pulse)
                .reduce((a, b) => a + b) /
            values.length)
        .round();

    return _BpChartPoint(
      x: index.toDouble(),
      systolic: avgSystolic,
      diastolic: avgDiastolic,
      pulse: avgPulse,
      label: labelBuilder(key),
    );
  }).toList();
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
