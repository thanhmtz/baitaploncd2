import 'package:flutter/material.dart';
import 'package:health_tracker/data/repositories/firestore.dart';
import 'package:health_tracker/data/repositories/gemini_food_service.dart';

class AIFoodResultScreen extends StatefulWidget {
  final String mealTitle;
  final String foodInput;
  final List<AIFoodResult> results;

  const AIFoodResultScreen({
    super.key,
    required this.mealTitle,
    required this.foodInput,
    required this.results,
  });

  @override
  State<AIFoodResultScreen> createState() => _AIFoodResultScreenState();
}

class _AIFoodResultScreenState extends State<AIFoodResultScreen> {
  static const Color _green = Color(0xFF58B40B);

  bool _isSaving = false;
  String? _error;

  Color get bgColor => Theme.of(context).scaffoldBackgroundColor;
  Color get textColor => Theme.of(context).colorScheme.onSurface;

  Color get subTextColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white38 : const Color(0xFF9BA3B4);
  }

  Color get cardColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E1E1E) : Colors.white;
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  double get totalCal =>
      widget.results.fold<double>(0, (s, r) => s + r.totalCalories);

  double get totalProtein =>
      widget.results.fold<double>(0, (s, r) => s + r.totalProtein);

  double get totalCarbs =>
      widget.results.fold<double>(0, (s, r) => s + r.totalCarbs);

  double get totalFat =>
      widget.results.fold<double>(0, (s, r) => s + r.totalFat);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'Kết quả phân tích',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  _buildTotalCard(),
                  const SizedBox(height: 14),
                  ...List.generate(widget.results.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildFoodItemCard(widget.results[index]),
                    );
                  }),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorCard(),
                  ],
                ],
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    final calByProtein = totalProtein * 4;
    final calByCarbs = totalCarbs * 4;
    final calByFat = totalFat * 9;
    final total = calByProtein + calByCarbs + calByFat;
    final pPct = totalCal > 0 ? (calByProtein / totalCal * 100).round() : 0;
    final cPct = totalCal > 0 ? (calByCarbs / totalCal * 100).round() : 0;
    final fPct = totalCal > 0 ? (calByFat / totalCal * 100).round() : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _green.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          const Text(
            'TỔNG DINH DƯỠNG',
            style: TextStyle(
              color: _green,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: totalCal),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return Text(
                '${value.round()} kcal',
                style: const TextStyle(
                  color: _green,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _macroChip('Đạm: ${totalProtein.round()}g · ${calByProtein.round()} kcal', totalProtein.round(), _green),
              _macroChip('T.bột: ${totalCarbs.round()}g · ${calByCarbs.round()} kcal', totalCarbs.round(), Colors.orange),
              _macroChip('Béo: ${totalFat.round()}g · ${calByFat.round()} kcal', totalFat.round(), Colors.blue),
            ],
          ),
          if (totalCal > 0 && total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (pPct > 0)
                      Flexible(
                        flex: pPct,
                        child: Container(color: _green),
                      ),
                    if (cPct > 0)
                      Flexible(
                        flex: cPct,
                        child: Container(color: Colors.orange),
                      ),
                    if (fPct > 0)
                      Flexible(
                        flex: fPct,
                        child: Container(color: Colors.blue),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (pPct > 0) _pctLabel('P', pPct, _green),
                if (cPct > 0) ...[const SizedBox(width: 12), _pctLabel('C', cPct, Colors.orange)],
                if (fPct > 0) ...[const SizedBox(width: 12), _pctLabel('F', fPct, Colors.blue)],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodItemCard(AIFoodResult item) {
    final qty = item.quantity;
    final qtyText = qty == qty.roundToDouble()
        ? qty.round().toString()
        : qty.toStringAsFixed(1);

    final pCal = item.totalProtein * 4;
    final cCal = item.totalCarbs * 4;
    final fCal = item.totalFat * 9;
    final calFromMacro = pCal + cCal + fCal;
    final totalCalories = item.totalCalories;

    final pPct = totalCalories > 0 ? (pCal / totalCalories * 100).round() : 0;
    final cPct = totalCalories > 0 ? (cCal / totalCalories * 100).round() : 0;
    final fPct = totalCalories > 0 ? (fCal / totalCalories * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _foodIconBox(),
                      )
                    : _foodIconBox(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$qtyText ${item.unit} · ${item.calories.round()} kcal/${item.unit}',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.totalCalories.round()} kcal',
                style: const TextStyle(
                  color: _green,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _macroDetail('Đạm', item.protein, item.totalProtein, pCal, _green, isDark),
                    const SizedBox(width: 6),
                    _macroDetail('T.bột', item.carbs, item.totalCarbs, cCal, Colors.orange, isDark),
                    const SizedBox(width: 6),
                    _macroDetail('Béo', item.fat, item.totalFat, fCal, Colors.blue, isDark),
                  ],
                ),
                if (totalCalories > 0 && calFromMacro > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          if (pPct > 0)
                            Flexible(
                              flex: pPct,
                              child: Container(color: _green),
                            ),
                          if (cPct > 0)
                            Flexible(
                              flex: cPct,
                              child: Container(color: Colors.orange),
                            ),
                          if (fPct > 0)
                            Flexible(
                              flex: fPct,
                              child: Container(color: Colors.blue),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (pPct > 0)
                        _pctLabel('P', pPct, _green),
                      if (cPct > 0) ...[
                        const SizedBox(width: 10),
                        _pctLabel('C', cPct, Colors.orange),
                      ],
                      if (fPct > 0) ...[
                        const SizedBox(width: 10),
                        _pctLabel('F', fPct, Colors.blue),
                      ],
                      const Spacer(),
                      Text(
                        '${calFromMacro.round()} / ${totalCalories.round()} kcal',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroDetail(String label, double perUnit, double total, double cal,
      Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${perUnit.toStringAsFixed(1)}g',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '→ ${total.toStringAsFixed(1)}g',
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (cal > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${cal.round()} kcal',
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pctLabel(String label, int pct, Color color) {
    return Text(
      '$label: $pct%',
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _foodIconBox() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.restaurant_rounded,
        color: _green,
        size: 24,
      ),
    );
  }

  Widget _macroChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value g',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveToDiary,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            _isSaving ? 'Đang lưu...' : 'Thêm vào ${widget.mealTitle}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Future<void> _saveToDiary() async {
    if (widget.results.isEmpty) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final combinedName = widget.results.map((r) {
      final qty = r.quantity == r.quantity.roundToDouble()
          ? r.quantity.round().toString()
          : r.quantity.toStringAsFixed(1);

      return '$qty ${r.name}';
    }).join(', ');

    final aiImageUrl = widget.results.first.imageUrl;
    final foodId = 'ai_food_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await FireStoreCrud().updateDiaryMeal(
        widget.mealTitle,
        foodId,
        'ai',
        combinedName,
        totalCal,
        totalCarbs,
        totalFat,
        totalProtein,
        imageUrl: aiImageUrl.isNotEmpty ? aiImageUrl : null,
      );

      await FireStoreCrud().addMyDish(
        name: combinedName,
        calories: totalCal,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
        mealType: widget.mealTitle,
        diaryFoodId: foodId,
        imageUrl: aiImageUrl.isNotEmpty ? aiImageUrl : null,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _error = 'Lỗi khi lưu: $e';
      });
    }
  }
}