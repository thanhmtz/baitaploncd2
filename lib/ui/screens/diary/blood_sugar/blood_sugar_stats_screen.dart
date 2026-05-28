import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:health_tracker/data/models/blood_sugar_model.dart';
import 'package:intl/intl.dart';

class BloodSugarStatsScreen extends StatefulWidget {
  const BloodSugarStatsScreen({Key? key}) : super(key: key);

  @override
  State<BloodSugarStatsScreen> createState() => _BloodSugarStatsScreenState();
}

class _BloodSugarStatsScreenState extends State<BloodSugarStatsScreen> {
  String _selectedPeriod = 'Week';

  Future<List<BloodSugar>> _fetchReadings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diary')
        .get(const GetOptions(source: Source.server));

    final allReadings = <BloodSugar>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final bsData = data['bloodSugar'];
      if (bsData is List && bsData.isNotEmpty) {
        DateTime date;
        try {
          date = DateFormat('d-M-y').parse(doc.id);
        } catch (_) {
          continue;
        }

        for (final item in bsData) {
          allReadings.add(
            BloodSugar.fromJson(Map<String, dynamic>.from(item), date: date),
          );
        }
      }
    }

    final now = DateTime.now();
    final cutoff = _selectedPeriod == 'Year'
        ? now.subtract(const Duration(days: 365))
        : _selectedPeriod == 'Month'
            ? now.subtract(const Duration(days: 30))
            : now.subtract(const Duration(days: 7));

    allReadings.removeWhere((r) => r.timestamp.isBefore(cutoff));
    allReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return allReadings;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê đường huyết'),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
              child: FutureBuilder<List<BloodSugar>>(
                future: _fetchReadings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }

                  final allReadings = snapshot.data ?? [];

                  if (allReadings.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bloodtype, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có dữ liệu đường huyết',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final latest = allReadings.last;
                  final latestLevel = _bloodSugarLevelFor(
                    latest.value,
                    latest.mealContext,
                  );
                  final avg = allReadings
                          .map((r) => r.value)
                          .fold<double>(0, (sum, v) => sum + v) /
                      allReadings.length;
                  final minValue = allReadings
                      .map((r) => r.value)
                      .reduce((a, b) => a < b ? a : b);
                  final maxValue = allReadings
                      .map((r) => r.value)
                      .reduce((a, b) => a > b ? a : b);
                  final chartMaxY = math.max(10.0, (maxValue + 2).ceilToDouble());

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      children: [
                        _LatestCard(
                          latest: latest,
                          level: latestLevel,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Trung bình',
                                value: avg.toStringAsFixed(1),
                                unit: 'mmol/L',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                title: 'Thấp nhất',
                                value: minValue.toStringAsFixed(1),
                                unit: 'mmol/L',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                title: 'Cao nhất',
                                value: maxValue.toStringAsFixed(1),
                                unit: 'mmol/L',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (allReadings.length > 1)
                          _ChartCard(
                            readings: allReadings,
                            maxY: chartMaxY,
                            selectedPeriod: _selectedPeriod,
                          )
                        else
                          const SizedBox(
                            height: 250,
                            child: Center(
                              child: Text('Thêm dữ liệu để xem biểu đồ'),
                            ),
                          ),
                        const SizedBox(height: 14),
                        ...allReadings.reversed.take(20).map((bs) {
                          final level = _bloodSugarLevelFor(
                            bs.value,
                            bs.mealContext,
                          );
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: Icon(
                                level.icon,
                                color: level.color,
                              ),
                              title: Text(
                                '${bs.value.toStringAsFixed(1)} mmol/L — ${level.label}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat('dd/MM, HH:mm').format(bs.timestamp)}  |  ${_contextLabel(bs.mealContext)}',
                              ),
                              trailing: bs.notes != null && bs.notes!.isNotEmpty
                                  ? Tooltip(
                                      message: bs.notes,
                                      child: const Icon(Icons.note, size: 18),
                                    )
                                  : null,
                            ),
                          );
                        }),
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
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedPeriod = period),
    );
  }
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({
    required this.latest,
    required this.level,
  });

  final BloodSugar latest;
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
                  'Lần đo gần nhất',
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
                  latest.value.toStringAsFixed(1),
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
          const SizedBox(height: 8),
          Text(
            '${_contextLabel(latest.mealContext)} • ${DateFormat('dd/MM/yyyy, HH:mm').format(latest.timestamp)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.58),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SugarChartPoint {
  const _SugarChartPoint({
    required this.x,
    required this.value,
    required this.label,
    required this.mealContext,
  });

  final int x;
  final double value;
  final String label;
  final BloodSugarMealContext mealContext;
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.readings,
    required this.maxY,
    required this.selectedPeriod,
  });

  final List<BloodSugar> readings;
  final double maxY;
  final String selectedPeriod;

  List<_SugarChartPoint> _buildPoints() {
    final grouped = <DateTime, List<BloodSugar>>{};

    for (final reading in readings) {
      final t = reading.timestamp;

      final key = selectedPeriod == 'Year'
          ? DateTime(t.year, t.month, 1)
          : DateTime(t.year, t.month, t.day);

      grouped.putIfAbsent(key, () => <BloodSugar>[]).add(reading);
    }

    final keys = grouped.keys.toList()..sort();

    return keys.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value;
      final values = grouped[key]!;

      final avg = values
              .map((e) => e.value)
              .fold<double>(0, (sum, value) => sum + value) /
          values.length;

      final mealContext = values.any(
        (e) => e.mealContext == BloodSugarMealContext.afterMeal,
      )
          ? BloodSugarMealContext.afterMeal
          : values.first.mealContext;

      return _SugarChartPoint(
        x: index,
        value: avg,
        mealContext: mealContext,
        label: selectedPeriod == 'Year'
            ? 'T${key.month}'
            : DateFormat('d/M').format(key),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final points = _buildPoints();

    if (points.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text('Thêm dữ liệu để xem biểu đồ'),
        ),
      );
    }

    final safeMaxY = math.max(
      10.0,
      (points.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 2)
          .ceilToDouble(),
    );

    final bottomInterval =
        points.length <= 5 ? 1.0 : (points.length / 5).ceilToDouble();

    return Container(
      height: 320,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          const _BloodSugarChartLegend(),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: math.max(maxY, safeMaxY),
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outline.withOpacity(0.12),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withOpacity(0.45),
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: bottomInterval,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }

                        final step = bottomInterval.toInt();
                        final shouldShow = index == 0 ||
                            index == points.length - 1 ||
                            index % step == 0;

                        if (!shouldShow) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            points[index].label,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurface.withOpacity(0.45),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final point = points[group.x.toInt()];
                      final level = _bloodSugarLevelFor(
                        point.value,
                        point.mealContext,
                      );

                      return BarTooltipItem(
                        '${point.label}\n${point.value.toStringAsFixed(1)} mmol/L\n${level.label}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: points.map((point) {
                  final level = _bloodSugarLevelFor(
                    point.value,
                    point.mealContext,
                  );

                  return BarChartGroupData(
                    x: point.x,
                    barRods: [
                      BarChartRodData(
                        toY: point.value,
                        width: points.length <= 5 ? 22 : 14,
                        color: level.color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BloodSugarChartLegend extends StatelessWidget {
  const _BloodSugarChartLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: const [
        _SugarLegendItem(
          color: Color(0xFF039BE5),
          label: 'Thấp',
        ),
        _SugarLegendItem(
          color: Color(0xFF43A047),
          label: 'Bình thường',
        ),
        _SugarLegendItem(
          color: Color(0xFFFB8C00),
          label: 'Tăng nhẹ',
        ),
        _SugarLegendItem(
          color: Color(0xFFE53935),
          label: 'Cao',
        ),
        _SugarLegendItem(
          color: Color(0xFFD32F2F),
          label: 'Rất thấp',
        ),
      ],
    );
  }
}

class _SugarLegendItem extends StatelessWidget {
  const _SugarLegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
