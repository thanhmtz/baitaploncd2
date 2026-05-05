import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FoodDetailsFullScreen extends StatefulWidget {
  const FoodDetailsFullScreen({
    Key? key,
    required this.food,
    required this.meal,
  }) : super(key: key);

  final Map<String, dynamic> food;
  final String meal;

  @override
  State<FoodDetailsFullScreen> createState() => _FoodDetailsFullScreenState();
}

class _FoodDetailsFullScreenState extends State<FoodDetailsFullScreen> {
  static const Color greenColor = Color(0xFF58B40B);

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final calories = _toDouble(widget.food['calories']);
    final carbs = _toDouble(widget.food['carbs']);
    final protein = _toDouble(widget.food['protein']);
    final fat = _toDouble(widget.food['fat']);
    final nutrients = widget.food['nutrients'] is List ? widget.food['nutrients'] as List : [];
    final imageUrl = widget.food['imageUrl']?.toString();
    final name = widget.food['name']?.toString() ?? 'Unknown';

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subTextColor = textColor.withOpacity(0.58);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa món ăn'),
                    content: Text('Bạn có muốn xóa "$name" không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  Navigator.pop(context);
                  _deleteFood();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.fastfood_rounded,
                        size: 72,
                        color: greenColor,
                      ),
                    )
                  : const Icon(
                      Icons.fastfood_rounded,
                      size: 72,
                      color: greenColor,
                    ),
            ),
            const SizedBox(height: 18),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    '${calories.toInt()}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: TextStyle(
                      color: subTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _nutrientPill('Carbs', carbs, 'g', cardColor, textColor),
                      _nutrientPill('Protein', protein, 'g', cardColor, textColor),
                      _nutrientPill('Fat', fat, 'g', cardColor, textColor),
                    ],
                  ),
                ],
              ),
            ),
            if (nutrients.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiết thành phần',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...nutrients.take(15).map<Widget>((n) {
                      final nutrient = n is Map
                          ? Map<String, dynamic>.from(n)
                          : <String, dynamic>{};

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                nutrient['nutrientName']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: textColor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${nutrient['value'] ?? 0} ${nutrient['unitName'] ?? ''}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _nutrientPill(String label, double value, String unit, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: greenColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        children: [
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              color: greenColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)}$unit',
            style: const TextStyle(
              color: greenColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFood() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final dateStr = DateFormat('d-M-y').format(DateTime.now());
      final mealKey = widget.food['_mealKey']?.toString() ?? widget.meal;

      debugPrint('Deleting food: ${widget.food['name']} from $mealKey at $dateStr');

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('diary')
          .doc(dateStr);

      final doc = await docRef.get();
      if (!doc.exists) {
        debugPrint('Document does not exist');
        return;
      }

      final data = doc.data()!;
      final mealData = data[mealKey];

      if (mealData is Map && mealData['foods'] is List) {
        final foods = List<Map<String, dynamic>>.from(
          mealData['foods'].map((f) => Map<String, dynamic>.from(f as Map)),
        );
        
        int? foodIndex;
        for (int i = 0; i < foods.length; i++) {
          if (foods[i]['name'] == widget.food['name']) {
            foodIndex = i;
            break;
          }
        }
        
        if (foodIndex != null) {
          debugPrint('Found food at index: $foodIndex, removing...');
          foods.removeAt(foodIndex);
          await docRef.update({mealKey: {'foods': foods}});
          debugPrint('Food deleted successfully');
        }
      }
    } catch (e) {
      debugPrint('Error deleting food: $e');
    }
  }
}