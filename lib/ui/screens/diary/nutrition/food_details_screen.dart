import 'package:flutter/material.dart';
import 'package:health_tracker/data/models/food_model.dart';
import 'package:health_tracker/data/repositories/firestore.dart';
import 'package:pie_chart/pie_chart.dart' as pie;

class FoodDetailsScreen extends StatefulWidget {
  const FoodDetailsScreen({Key? key, required this.food, required this.meal})
      : super(key: key);
  final Food food;
  final String meal;

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  late String meal, servingUnit;
  TimeOfDay time = TimeOfDay.now();
  late TextEditingController servingsController;
  late TextEditingController servingUnitController;
  late double servings, servingSize;
  late Map<String, dynamic> protein, fat, carbs, calories;

  @override
  void initState() {
    super.initState();
    servingUnitController = TextEditingController();
    servingsController = TextEditingController(text: '1');
    meal = widget.meal;
    servingSize = widget.food.servingSize ?? 100;
    servingUnit = widget.food.servingSizeUnit ?? 'g';
    servings = widget.food.numberOfServings ?? 1;
    
    if (widget.food.nutrients.isNotEmpty) {
      protein = widget.food.nutrientFromMap(1003);
      fat = widget.food.nutrientFromMap(1004);
      carbs = widget.food.nutrientFromMap(1005);
      calories = widget.food.nutrientFromMap(1008);
    } else {
      protein = {'value': widget.food.protein ?? 0, 'unitName': 'g'};
      fat = {'value': widget.food.fat ?? 0, 'unitName': 'g'};
      carbs = {'value': widget.food.carbs ?? 0, 'unitName': 'g'};
      calories = {'value': widget.food.calories ?? 0, 'unitName': 'kcal'};
    }
  }

  @override
  void dispose() {
    servingUnitController.dispose();
    servingsController.dispose();
    super.dispose();
  }

  dynamic macroPercentage(double value, int type) {
    double calories =
        (protein['value'] * 4 + carbs['value'] * 4 + fat['value'] * 9)
            .toDouble();
    if (calories == 0) {
      return 0.toDouble();
    } else if (type == 1) {
      return ((value * 4 / calories) * 100).round();
    } else {
      return ((value * 9 / calories) * 100).round();
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalCalories = (calories['value'] ?? widget.food.calories ?? 0) * servings;
    double totalCarbs = (carbs['value'] ?? widget.food.carbs ?? 0) * servings;
    double totalFat = (fat['value'] ?? widget.food.fat ?? 0) * servings;
    double totalProtein = (protein['value'] ?? widget.food.protein ?? 0) * servings;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: widget.food.imageUrl != null ? 200 : 0,
            pinned: true,
            flexibleSpace: widget.food.imageUrl != null
                ? FlexibleSpaceBar(
                    background: Image.network(
                      widget.food.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood, size: 80),
                      ),
                    ),
                  )
                : null,
            title: Text(widget.food.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                onPressed: () {
                  FireStoreCrud().updateDiaryMeal(
                    meal,
                    widget.food.id,
                    'fdc',
                    widget.food.name,
                    totalCalories,
                    totalCarbs,
                    totalFat,
                    totalProtein,
                    imageUrl: widget.food.imageUrl,
                    nutrients: widget.food.nutrients,
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add))
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant, color: Colors.red),
                          const SizedBox(width: 12),
                          const Text('Meal: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: ['Breakfast', 'Lunch', 'Dinner', 'Snacks'].map((m) => 
                                ChoiceChip(
                                  label: Text(m),
                                  selected: meal == m,
                                  onSelected: (_) => setState(() => meal = m),
                                )
                              ).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Servings & Time
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Servings', style: TextStyle(fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: servings > 0.5 
                                          ? () => setState(() => servings -= 0.5) 
                                          : null,
                                    ),
                                    Text('$servings', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => setState(() => servings += 0.5),
                                    ),
                                    Text('x ${servingSize.toInt()}$servingUnit'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextButton.icon(
                                  onPressed: () async {
                                    final newTime = await showTimePicker(
                                      context: context, initialTime: time);
                                    if (newTime != null) {
                                      setState(() => time = newTime);
                                    }
                                  },
                                  icon: const Icon(Icons.access_time),
                                  label: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Calories ring chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 100,
                                    width: 100,
                                    child: pie.PieChart(
                                      dataMap: {
                                        'Carbs': totalCarbs,
                                        'Fat': totalFat,
                                        'Protein': totalProtein,
                                      },
                                      chartType: pie.ChartType.ring,
                                      baseChartColor: Colors.grey.shade200,
                                      colorList: const [
                                        Color.fromARGB(255, 0, 210, 124),
                                        Color.fromARGB(255, 128, 71, 246),
                                        Color.fromARGB(255, 254, 164, 44)
                                      ],
                                      legendOptions: const pie.LegendOptions(showLegends: false),
                                      chartValuesOptions: const pie.ChartValuesOptions(showChartValues: false),
                                      ringStrokeWidth: 10,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${totalCalories.toInt()}', 
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                      const Text('kcal', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _macroRow('Carbs', totalCarbs, const Color.fromARGB(255, 0, 210, 124)),
                                  const SizedBox(height: 8),
                                  _macroRow('Fat', totalFat, const Color.fromARGB(255, 128, 71, 246)),
                                  const SizedBox(height: 8),
                                  _macroRow('Protein', totalProtein, const Color.fromARGB(255, 254, 164, 44)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Detailed nutrients
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nutritional Information', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Divider(),
                          if (widget.food.nutrients.isNotEmpty)
                            ...widget.food.nutrients.take(15).map<Widget>((n) => 
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(n['nutrientName'] ?? ''),
                                    Text('${n['value'] ?? 0} ${n['unitName'] ?? ''}'),
                                  ],
                                ),
                              )
                            )
                          else
                            Column(
                              children: [
                                _nutrientRow('Calories', totalCalories, 'kcal'),
                                _nutrientRow('Carbohydrates', totalCarbs, 'g'),
                                _nutrientRow('Fat', totalFat, 'g'),
                                _nutrientRow('Protein', totalProtein, 'g'),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroRow(String label, double value, Color color) => Row(
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text('$label: ${value.toStringAsFixed(1)}g'),
    ],
  );

  Widget _nutrientRow(String name, double value, String unit) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name),
        Text('${value.toStringAsFixed(1)} $unit'),
      ],
    ),
  );

  Future<dynamic> _servingsDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            contentPadding: const EdgeInsets.all(16),
            title: const Text('How Much?'),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: servingsController,
                    ),
                  ),
                  const Text('Serving(s) of')
                ],
              ),
              DropdownButton<double>(
                  value: servingSize,
                  items: [
                    DropdownMenuItem(
                      value: widget.food.servingSize,
                      child: Text('${widget.food.servingSize} g'),
                    ),
                    const DropdownMenuItem(
                      value: 100,
                      child: Text('100 g'),
                    ),
                    const DropdownMenuItem(
                      value: 1,
                      child: Text('1 g'),
                    ),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      servingSize = newValue!;
                    });
                  }),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (servingsController.text.isNotEmpty) {
                        setState(() {
                          servings = double.parse(servingsController.text);
                        });
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('save'),
                  )
                ],
              )
            ],
          );
        });
  }
}
