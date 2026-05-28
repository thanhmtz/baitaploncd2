import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pie_chart/pie_chart.dart' as pie;

class CaloriesStatsScreen extends StatefulWidget {
  const CaloriesStatsScreen({Key? key, required this.date}) : super(key: key);

  final DateTime date;

  @override
  State<CaloriesStatsScreen> createState() => _CaloriesStatsScreenState();
}

class _CaloriesStatsScreenState extends State<CaloriesStatsScreen> {
  static const double _defaultGoalCalories = 2000;

  String _selectedPeriod = 'Week';
  late Future<List<_NutritionDay>> _daysFuture;

  @override
  void initState() {
    super.initState();
    _daysFuture = _fetchAllDays();
  }

  void _reload() {
    setState(() {
      _daysFuture = _fetchAllDays();
    });
  }

  Future<void> _refresh() async {
    final future = _fetchAllDays();

    setState(() {
      _daysFuture = future;
    });

    await future;
  }

  Future<List<_NutritionDay>> _fetchAllDays() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diary')
        .get();

    final daysByKey = <DateTime, _NutritionDay>{};

    for (final doc in snapshot.docs) {
      final parsed = _parseDiaryDate(doc.id);
      if (parsed == null) continue;

      final dayKey = DateTime(parsed.year, parsed.month, parsed.day);
      final day = _nutritionDayFromMap(dayKey, doc.data());

      if (day.totalCalories <= 0 &&
          day.totalCarbs <= 0 &&
          day.totalProtein <= 0 &&
          day.totalFat <= 0) {
        continue;
      }

      daysByKey[dayKey] = day;
    }

    final days = daysByKey.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return days;
  }

  DateTime? _parseDiaryDate(String docId) {
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

    final underscore =
        RegExp(r'^(\d{4})_(\d{1,2})_(\d{1,2})$').firstMatch(docId);

    if (underscore != null) {
      final year = int.tryParse(underscore.group(1)!);
      final month = int.tryParse(underscore.group(2)!);
      final day = int.tryParse(underscore.group(3)!);

      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _mealMap(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _foodsFromMeal(Map<String, dynamic> meal) {
    final foods = meal['foods'];

    if (foods is! List) return [];

    return foods
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  double _sumFoods(List<Map<String, dynamic>> foods, String key) {
    return foods.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item[key]),
    );
  }

  double _mealValue({
    required Map<String, dynamic> data,
    required Map<String, dynamic> meal,
    required List<String> keys,
    String? foodKey,
  }) {
    for (final key in keys) {
      final mealValue = _toDouble(meal[key]);
      if (mealValue > 0) return mealValue;

      final topLevelValue = _toDouble(data[key]);
      if (topLevelValue > 0) return topLevelValue;
    }

    if (foodKey != null) {
      final foodSum = _sumFoods(_foodsFromMeal(meal), foodKey);
      if (foodSum > 0) return foodSum;
    }

    return 0;
  }

  _NutritionDay _nutritionDayFromMap(
    DateTime date,
    Map<String, dynamic> data,
  ) {
    final breakfast = _mealMap(
      data,
      ['Breakfast', 'breakfast', 'buaSang', 'morning'],
    );
    final lunch = _mealMap(
      data,
      ['Lunch', 'lunch', 'buaTrua', 'noon'],
    );
    final dinner = _mealMap(
      data,
      ['Dinner', 'dinner', 'buaToi', 'evening'],
    );
    final snacks = _mealMap(
      data,
      ['Snacks', 'snacks', 'snack', 'anVat'],
    );

    final mealPoints = <_NutritionChartPoint>[
      _mealPoint(
        date: date,
        data: data,
        meal: breakfast,
        title: 'Breakfast',
        shortLabel: 'B',
        caloriesKeys: ['breakfastCalories', 'calories'],
        proteinKeys: ['breakfastProtein', 'protein'],
        fatKeys: ['breakfastFat', 'fat'],
        carbsKeys: ['breakfastCarbs', 'carbs'],
      ),
      _mealPoint(
        date: date,
        data: data,
        meal: lunch,
        title: 'Lunch',
        shortLabel: 'L',
        caloriesKeys: ['lunchCalories', 'calories'],
        proteinKeys: ['lunchProtein', 'protein'],
        fatKeys: ['lunchFat', 'fat'],
        carbsKeys: ['lunchCarbs', 'carbs'],
      ),
      _mealPoint(
        date: date,
        data: data,
        meal: dinner,
        title: 'Dinner',
        shortLabel: 'D',
        caloriesKeys: ['dinnerCalories', 'calories'],
        proteinKeys: ['dinnerProtein', 'protein'],
        fatKeys: ['dinnerFat', 'fat'],
        carbsKeys: ['dinnerCarbs', 'carbs'],
      ),
      _mealPoint(
        date: date,
        data: data,
        meal: snacks,
        title: 'Snacks',
        shortLabel: 'S',
        caloriesKeys: ['snacksCalories', 'calories'],
        proteinKeys: ['snacksProtein', 'protein'],
        fatKeys: ['snacksFat', 'fat'],
        carbsKeys: ['snacksCarbs', 'carbs'],
      ),
    ];

    final fallbackCalories = mealPoints.fold<double>(
      0,
      (sum, point) => sum + point.calories,
    );
    final fallbackProtein = mealPoints.fold<double>(
      0,
      (sum, point) => sum + point.protein,
    );
    final fallbackFat = mealPoints.fold<double>(
      0,
      (sum, point) => sum + point.fat,
    );
    final fallbackCarbs = mealPoints.fold<double>(
      0,
      (sum, point) => sum + point.carbs,
    );

    return _NutritionDay(
      date: date,
      totalCalories: _toDouble(data['totalCalories']) > 0
          ? _toDouble(data['totalCalories'])
          : fallbackCalories,
      totalProtein: _toDouble(data['totalProtein']) > 0
          ? _toDouble(data['totalProtein'])
          : fallbackProtein,
      totalFat:
          _toDouble(data['totalFat']) > 0 ? _toDouble(data['totalFat']) : fallbackFat,
      totalCarbs: _toDouble(data['totalCarbs']) > 0
          ? _toDouble(data['totalCarbs'])
          : fallbackCarbs,
      mealPoints: mealPoints,
    );
  }

  _NutritionChartPoint _mealPoint({
    required DateTime date,
    required Map<String, dynamic> data,
    required Map<String, dynamic> meal,
    required String title,
    required String shortLabel,
    required List<String> caloriesKeys,
    required List<String> proteinKeys,
    required List<String> fatKeys,
    required List<String> carbsKeys,
  }) {
    return _NutritionChartPoint(
      date: date,
      label: title,
      shortLabel: shortLabel,
      calories: _mealValue(
        data: data,
        meal: meal,
        keys: caloriesKeys,
        foodKey: 'calories',
      ),
      protein: _mealValue(
        data: data,
        meal: meal,
        keys: proteinKeys,
        foodKey: 'protein',
      ),
      fat: _mealValue(
        data: data,
        meal: meal,
        keys: fatKeys,
        foodKey: 'fat',
      ),
      carbs: _mealValue(
        data: data,
        meal: meal,
        keys: carbsKeys,
        foodKey: 'carbs',
      ),
    );
  }

  _DateRange _currentRange(String period) {
    final base = DateTime(widget.date.year, widget.date.month, widget.date.day);

    if (period == 'Year') {
      return _DateRange(
        start: DateTime(base.year, 1, 1),
        end: DateTime(base.year + 1, 1, 1),
        label: 'năm nay',
      );
    }

    if (period == 'Month') {
      return _DateRange(
        start: DateTime(base.year, base.month, 1),
        end: DateTime(base.year, base.month + 1, 1),
        label: 'tháng này',
      );
    }

    final weekStart = base.subtract(
      Duration(days: base.weekday - DateTime.monday),
    );

    return _DateRange(
      start: weekStart,
      end: weekStart.add(const Duration(days: 7)),
      label: 'tuần này',
    );
  }

  List<_NutritionDay> _daysInRange(
    List<_NutritionDay> days,
    _DateRange range,
  ) {
    return days.where((day) {
      return !day.date.isBefore(range.start) && day.date.isBefore(range.end);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<_NutritionChartPoint> _chartPointsForPeriod(
    List<_NutritionDay> days,
    String period,
  ) {
    if (period == 'Year') {
      final grouped = <DateTime, List<_NutritionDay>>{};

      for (final day in days) {
        final key = DateTime(day.date.year, day.date.month, 1);
        grouped.putIfAbsent(key, () => <_NutritionDay>[]).add(day);
      }

      final keys = grouped.keys.toList()..sort();

      return keys.map((key) {
        final values = grouped[key]!;
        return _NutritionChartPoint(
          date: key,
          label: DateFormat('MM/yyyy').format(key),
          shortLabel: 'T${key.month}',
          calories: values.fold<double>(0, (sum, item) => sum + item.totalCalories),
          protein: values.fold<double>(0, (sum, item) => sum + item.totalProtein),
          fat: values.fold<double>(0, (sum, item) => sum + item.totalFat),
          carbs: values.fold<double>(0, (sum, item) => sum + item.totalCarbs),
        );
      }).toList();
    }

    return days.map((day) {
      return _NutritionChartPoint(
        date: day.date,
        label: DateFormat('dd/MM/yyyy').format(day.date),
        shortLabel: DateFormat('d/M').format(day.date),
        calories: day.totalCalories,
        protein: day.totalProtein,
        fat: day.totalFat,
        carbs: day.totalCarbs,
      );
    }).toList();
  }

  _NutritionSummary _summaryFromPoints(List<_NutritionChartPoint> points) {
    if (points.isEmpty) {
      return const _NutritionSummary(
        totalCalories: 0,
        avgCalories: 0,
        maxCalories: 0,
        totalProtein: 0,
        totalFat: 0,
        totalCarbs: 0,
      );
    }

    final totalCalories = points.fold<double>(
      0,
      (sum, point) => sum + point.calories,
    );

    return _NutritionSummary(
      totalCalories: totalCalories,
      avgCalories: totalCalories / points.length,
      maxCalories: points
          .map((e) => e.calories)
          .reduce((a, b) => a > b ? a : b),
      totalProtein: points.fold<double>(
        0,
        (sum, point) => sum + point.protein,
      ),
      totalFat: points.fold<double>(
        0,
        (sum, point) => sum + point.fat,
      ),
      totalCarbs: points.fold<double>(
        0,
        (sum, point) => sum + point.carbs,
      ),
    );
  }

  double _chartMaxY(List<_NutritionChartPoint> points) {
    if (points.isEmpty) return _defaultGoalCalories;

    final maxPoint = points
        .map((e) => e.calories)
        .reduce((a, b) => a > b ? a : b);

    return math.max(_defaultGoalCalories, maxPoint + 250);
  }

  @override
  Widget build(BuildContext context) {
    final range = _currentRange(_selectedPeriod);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê calories'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
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
            child: FutureBuilder<List<_NutritionDay>>(
              future: _daysFuture,
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

                final allDays = snapshot.data ?? [];
                final days = _daysInRange(allDays, range);
                final points = _chartPointsForPeriod(days, _selectedPeriod);

                if (points.isEmpty) {
                  return _EmptyState(
                    message: 'Chưa có dữ liệu calories trong ${range.label}.',
                    onRetry: _reload,
                  );
                }

                final summary = _summaryFromPoints(points);

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _NutritionSummaryCard(
                        label: range.label,
                        summary: summary,
                        itemCount: points.length,
                        goal: _defaultGoalCalories,
                      ),
                      const SizedBox(height: 14),
                      _MacroRingCard(
                        totalCalories: summary.totalCalories,
                        totalProtein: summary.totalProtein,
                        totalFat: summary.totalFat,
                        totalCarbs: summary.totalCarbs,
                      ),
                      const SizedBox(height: 18),
                      _NutritionHeatmapCard(
                        days: allDays,
                        month: DateTime(widget.date.year, widget.date.month, 1),
                        goal: _defaultGoalCalories,
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(title: 'Biểu đồ calories'),
                      const SizedBox(height: 10),
                      _CaloriesColumnChartCard(
                        points: points,
                        goal: _defaultGoalCalories,
                        maxY: _chartMaxY(points),
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(title: 'Lịch sử chi tiết'),
                      const SizedBox(height: 10),
                      ...points.reversed.map(
                        (point) => _NutritionHistoryTile(
                          point: point,
                          goal: _defaultGoalCalories,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
                      color: colorScheme.primary.withOpacity(0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
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

class _NutritionSummaryCard extends StatelessWidget {
  const _NutritionSummaryCard({
    required this.label,
    required this.summary,
    required this.itemCount,
    required this.goal,
  });

  final String label;
  final _NutritionSummary summary;
  final int itemCount;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final color = _calorieColor(summary.avgCalories, goal);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(
        context,
        shadowColor: color.withOpacity(0.11),
        borderColor: color.withOpacity(0.20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tổng quan $label',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              _StatusPill(
                label: _calorieLabel(summary.avgCalories, goal),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            child: Text(
              '${summary.totalCalories.toStringAsFixed(0)} kcal',
              style: TextStyle(
                color: color,
                fontSize: 46,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            percent: (summary.avgCalories / goal).clamp(0.0, 1.0).toDouble(),
            lineHeight: 7,
            padding: EdgeInsets.zero,
            barRadius: const Radius.circular(999),
            backgroundColor: color.withOpacity(0.12),
            progressColor: color,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  title: 'Trung bình',
                  value: summary.avgCalories.toStringAsFixed(0),
                  unit: 'kcal',
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  title: 'Cao nhất',
                  value: summary.maxCalories.toStringAsFixed(0),
                  unit: 'kcal',
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  title: 'Số cột',
                  value: '$itemCount',
                  unit: 'mục',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Mục tiêu tham chiếu: ${goal.toStringAsFixed(0)} kcal/ngày',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.56),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
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
        FittedBox(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.45),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.58),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MacroRingCard extends StatelessWidget {
  const _MacroRingCard({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
  });

  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;

  double _macroPercentage(double value, int type, double totalMacroCalories) {
    if (totalMacroCalories == 0) return 0;
    if (type == 1) return (value * 4 / totalMacroCalories) * 100;
    return (value * 9 / totalMacroCalories) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final totalMacroCalories = totalCarbs * 4 + totalProtein * 4 + totalFat * 9;

    final dataMap = <String, double>{
      'Carbs': totalCarbs > 0 ? totalCarbs : 0.001,
      'Fat': totalFat > 0 ? totalFat : 0.001,
      'Protein': totalProtein > 0 ? totalProtein : 0.001,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalCalories.toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const Text('kcal'),
                ],
              ),
              SizedBox(
                height: 96,
                width: 96,
                child: pie.PieChart(
                  dataMap: dataMap,
                  chartType: pie.ChartType.ring,
                  baseChartColor: Colors.grey.shade900.withOpacity(0.3),
                  colorList: const [
                    Color.fromARGB(255, 0, 210, 124),
                    Color.fromARGB(255, 128, 71, 246),
                    Color.fromARGB(255, 254, 164, 44),
                  ],
                  legendOptions: const pie.LegendOptions(showLegends: false),
                  chartValuesOptions: const pie.ChartValuesOptions(
                    showChartValues: false,
                  ),
                  ringStrokeWidth: 7,
                ),
              ),
            ],
          ),
          _MacroValue(
            percent: '${_macroPercentage(totalCarbs, 1, totalMacroCalories).round()}%',
            value: '${totalCarbs.toStringAsFixed(0)} g',
            label: 'Carbs',
            color: const Color.fromARGB(255, 0, 210, 124),
          ),
          _MacroValue(
            percent: '${_macroPercentage(totalFat, 2, totalMacroCalories).floor()}%',
            value: '${totalFat.toStringAsFixed(0)} g',
            label: 'Fat',
            color: const Color.fromARGB(255, 128, 71, 246),
          ),
          _MacroValue(
            percent:
                '${_macroPercentage(totalProtein, 1, totalMacroCalories).round()}%',
            value: '${totalProtein.toStringAsFixed(0)} g',
            label: 'Protein',
            color: const Color.fromARGB(255, 254, 164, 44),
          ),
        ],
      ),
    );
  }
}

class _MacroValue extends StatelessWidget {
  const _MacroValue({
    required this.percent,
    required this.value,
    required this.label,
    required this.color,
  });

  final String percent;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          percent,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 20),
        ),
        Text(label),
      ],
    );
  }
}


class _NutritionHeatmapCard extends StatelessWidget {
  const _NutritionHeatmapCard({
    required this.days,
    required this.month,
    required this.goal,
  });

  final List<_NutritionDay> days;
  final DateTime month;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);

    final monthDays = days.where((day) {
      return !day.date.isBefore(monthStart) && day.date.isBefore(monthEnd);
    }).toList();

    final dayMap = <DateTime, _NutritionDay>{
      for (final day in monthDays)
        DateTime(day.date.year, day.date.month, day.date.day): day,
    };

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = monthStart.weekday - DateTime.monday;
    final totalCells = leadingEmpty + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    final cells = <DateTime?>[];

    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(null);
    }

    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(month.year, month.month, day));
    }

    while (cells.length < rowCount * 7) {
      cells.add(null);
    }

    final achievedDays = monthDays
        .where(
          (day) =>
              day.totalCalories >= goal * 0.90 &&
              day.totalCalories <= goal * 1.10,
        )
        .length;

    final overDays = monthDays
        .where((day) => day.totalCalories > goal * 1.10)
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
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
                  Icons.grid_view_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Heatmap ăn uống tháng ${DateFormat('MM/yyyy').format(monthStart)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeatmapSummaryValue(
                  title: 'Có dữ liệu',
                  value: '${monthDays.length}',
                  color: colorScheme.primary,
                ),
              ),
              Expanded(
                child: _HeatmapSummaryValue(
                  title: 'Đạt goal',
                  value: '$achievedDays',
                  color: const Color(0xFF43A047),
                ),
              ),
              Expanded(
                child: _HeatmapSummaryValue(
                  title: 'Ăn quá nhiều',
                  value: '$overDays',
                  color: const Color(0xFFE53935),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _WeekdayLabel('T2'),
              _WeekdayLabel('T3'),
              _WeekdayLabel('T4'),
              _WeekdayLabel('T5'),
              _WeekdayLabel('T6'),
              _WeekdayLabel('T7'),
              _WeekdayLabel('CN'),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 6.0;
              final cellSize = (constraints.maxWidth - gap * 6) / 7;

              return Column(
                children: List.generate(rowCount, (row) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: row == rowCount - 1 ? 0 : gap,
                    ),
                    child: Row(
                      children: List.generate(7, (col) {
                        final index = row * 7 + col;
                        final date = cells[index];
                        final isLastCol = col == 6;

                        if (date == null) {
                          return Container(
                            width: cellSize,
                            height: cellSize,
                            margin: EdgeInsets.only(right: isLastCol ? 0 : gap),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant.withOpacity(0.28),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          );
                        }

                        final normalized =
                            DateTime(date.year, date.month, date.day);
                        final day = dayMap[normalized];
                        final calories = day?.totalCalories;
                        final color = _heatmapColor(calories, goal);
                        final label = calories == null
                            ? 'Không có dữ liệu'
                            : '${calories.toStringAsFixed(0)} kcal';

                        return Tooltip(
                          message:
                              '${DateFormat('dd/MM/yyyy').format(date)} • $label',
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            margin: EdgeInsets.only(right: isLastCol ? 0 : gap),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: color.withOpacity(0.30),
                              ),
                            ),
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: calories == null
                                    ? colorScheme.onSurface.withOpacity(0.36)
                                    : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeatmapLegendItem(
                color: Color(0xFFE0E0E0),
                label: 'Không có dữ liệu',
              ),
              _HeatmapLegendItem(
                color: Color(0xFF039BE5),
                label: 'Ăn thấp',
              ),
              _HeatmapLegendItem(
                color: Color(0xFF43A047),
                label: 'Đạt goal',
              ),
              _HeatmapLegendItem(
                color: Color(0xFFE53935),
                label: 'Vượt goal',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapSummaryValue extends StatelessWidget {
  const _HeatmapSummaryValue({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.58),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.48),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeatmapLegendItem extends StatelessWidget {
  const _HeatmapLegendItem({
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
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

class _CaloriesColumnChartCard extends StatelessWidget {
  const _CaloriesColumnChartCard({
    required this.points,
    required this.goal,
    required this.maxY,
  });

  final List<_NutritionChartPoint> points;
  final double goal;
  final double maxY;

  int _averageInt(Iterable<double> values) {
    final list = values.toList();

    if (list.isEmpty) return 0;

    return (list.reduce((a, b) => a + b) / list.length).round();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final avgCalories = _averageInt(points.map((e) => e.calories));
    final avgProtein = _averageInt(points.map((e) => e.protein));
    final avgCarbs = _averageInt(points.map((e) => e.carbs));

    return Container(
      height: 440,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ChartTopValue(
                  title: 'Calories TB',
                  value: '$avgCalories',
                  unit: 'kcal',
                ),
              ),
              Expanded(
                child: _ChartTopValue(
                  title: 'Protein TB',
                  value: '$avgProtein',
                  unit: 'g',
                ),
              ),
              Expanded(
                child: _ChartTopValue(
                  title: 'Carbs TB',
                  value: '$avgCarbs',
                  unit: 'g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _CaloriesLegend(),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = math.max(
                  constraints.maxWidth,
                  70 + points.length * 48.0,
                );

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: chartWidth,
                    height: constraints.maxHeight,
                    child: CustomPaint(
                      painter: _CaloriesColumnChartPainter(
                        points: points,
                        goal: goal,
                        maxY: maxY,
                        gridColor: colorScheme.outline.withOpacity(0.22),
                        textColor: colorScheme.onSurface.withOpacity(0.58),
                        strongTextColor: colorScheme.onSurface.withOpacity(0.76),
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

class _CaloriesLegend extends StatelessWidget {
  const _CaloriesLegend();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: const [
            _LegendItem(
              color: Color(0xFF039BE5),
              label: 'Thấp',
            ),
            SizedBox(width: 8),
            _LegendItem(
              color: Color(0xFF43A047),
              label: 'Đạt',
            ),
            SizedBox(width: 8),
            _LegendItem(
              color: Color(0xFFFB8C00),
              label: 'Gần cao',
            ),
            SizedBox(width: 8),
            _LegendItem(
              color: Color(0xFFE53935),
              label: 'Vượt',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
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

class _CaloriesColumnChartPainter extends CustomPainter {
  const _CaloriesColumnChartPainter({
    required this.points,
    required this.goal,
    required this.maxY,
    required this.gridColor,
    required this.textColor,
    required this.strongTextColor,
  });

  final List<_NutritionChartPoint> points;
  final double goal;
  final double maxY;
  final Color gridColor;
  final Color textColor;
  final Color strongTextColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const left = 52.0;
    const right = 18.0;
    const top = 14.0;
    const bottom = 58.0;

    final plotWidth = math.max(1.0, size.width - left - right);
    final plotHeight = math.max(1.0, size.height - top - bottom);

    final axisMax = (((math.max(goal, maxY) + 250) / 250).ceil() * 250).toDouble();

    double yFor(double value) {
      if (axisMax == 0) return top + plotHeight;
      return top + ((axisMax - value) / axisMax) * plotHeight;
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
          ? 30
          : points.length <= 4
              ? 26
              : 20
      ..strokeCap = StrokeCap.round;

    for (final value in _axisValues(axisMax)) {
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

    final goalY = yFor(goal);
    final goalPaint = Paint()
      ..color = const Color(0xFF43A047).withOpacity(0.40)
      ..strokeWidth = 1.5;

    _drawDashedLine(
      canvas,
      Offset(left, goalY),
      Offset(size.width - right, goalY),
      goalPaint,
    );

    _drawText(
      canvas,
      'Goal',
      Offset(size.width - right - 34, goalY - 18),
      const Color(0xFF43A047),
      fontSize: 10,
      fontWeight: FontWeight.w900,
    );

    final baseY = yFor(0);
    canvas.drawLine(
      Offset(left, baseY),
      Offset(size.width - right, baseY),
      axisPaint,
    );

    final showValueLabels = points.length <= 8;
    final labelEvery = points.length <= 6 ? 1 : (points.length / 4).ceil();

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x = xFor(i);
      final topY = yFor(point.calories);

      barPaint.color = _calorieColor(point.calories, goal);

      canvas.drawLine(
        Offset(x, baseY),
        Offset(x, topY),
        barPaint,
      );

      if (showValueLabels) {
        _drawCenteredText(
          canvas,
          point.calories.toStringAsFixed(0),
          Offset(x, topY - 23),
          strongTextColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        );
      }

      final showLabel = i == 0 || i == points.length - 1 || i % labelEvery == 0;

      if (showLabel) {
        _drawCenteredText(
          canvas,
          point.shortLabel,
          Offset(x, size.height - 30),
          textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        );
      }
    }
  }

  List<double> _axisValues(double axisMax) {
    final step = math.max(250, (axisMax / 4 / 250).ceil() * 250).toDouble();
    final values = <double>[];
    var value = axisMax;

    while (value >= -0.001) {
      values.add(value);
      value -= step;
    }

    if (!values.contains(0)) values.add(0);

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
    if (totalDistance == 0) return;

    final direction = (end - start) / totalDistance;
    var currentDistance = 0.0;

    while (currentDistance < totalDistance) {
      final nextDistance = math.min(currentDistance + dashWidth, totalDistance);

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
  bool shouldRepaint(covariant _CaloriesColumnChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.goal != goal ||
        oldDelegate.maxY != maxY ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.strongTextColor != strongTextColor;
  }
}

class _NutritionHistoryTile extends StatelessWidget {
  const _NutritionHistoryTile({
    required this.point,
    required this.goal,
  });

  final _NutritionChartPoint point;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final color = _calorieColor(point.calories, goal);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(context, shadowColor: Colors.transparent),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.local_fire_department_rounded, color: color),
        ),
        title: Text(
          '${point.calories.toStringAsFixed(0)} kcal — ${_calorieLabel(point.calories, goal)}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${point.label}\nProtein ${point.protein.toStringAsFixed(0)}g • Carbs ${point.carbs.toStringAsFixed(0)}g • Fat ${point.fat.toStringAsFixed(0)}g',
            style: TextStyle(
              height: 1.35,
              color: colorScheme.onSurface.withOpacity(0.64),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.onRetry,
  });

  final String message;
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
          decoration: _cardDecoration(context),
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
                  Icons.local_fire_department_rounded,
                  size: 42,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Chưa có dữ liệu calories',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
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

class _DateRange {
  const _DateRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;
}

class _NutritionDay {
  const _NutritionDay({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
    required this.mealPoints,
  });

  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final List<_NutritionChartPoint> mealPoints;
}

class _NutritionChartPoint {
  const _NutritionChartPoint({
    required this.date,
    required this.label,
    required this.shortLabel,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final DateTime date;
  final String label;
  final String shortLabel;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
}

class _NutritionSummary {
  const _NutritionSummary({
    required this.totalCalories,
    required this.avgCalories,
    required this.maxCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
  });

  final double totalCalories;
  final double avgCalories;
  final double maxCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
}

BoxDecoration _cardDecoration(
  BuildContext context, {
  Color? shadowColor,
  Color? borderColor,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: borderColor ?? colorScheme.outline.withOpacity(0.12),
    ),
    boxShadow: [
      BoxShadow(
        color: shadowColor ?? Colors.black.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}


Color _heatmapColor(double? calories, double goal) {
  if (calories == null || calories <= 0) {
    return const Color(0xFFE0E0E0);
  }

  if (calories > goal * 1.10) {
    return const Color(0xFFE53935);
  }

  if (calories >= goal * 0.90) {
    return const Color(0xFF43A047);
  }

  return const Color(0xFF039BE5);
}

Color _calorieColor(double value, double goal) {
  if (value <= 0) return const Color(0xFF9E9E9E);
  if (value < goal * 0.65) return const Color(0xFF039BE5);
  if (value <= goal) return const Color(0xFF43A047);
  if (value <= goal * 1.15) return const Color(0xFFFB8C00);
  return const Color(0xFFE53935);
}

String _calorieLabel(double value, double goal) {
  if (value <= 0) return 'No data';
  if (value < goal * 0.65) return 'Low';
  if (value <= goal) return 'On target';
  if (value <= goal * 1.15) return 'Near high';
  return 'Over';
}
