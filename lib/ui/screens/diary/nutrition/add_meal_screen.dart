import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:health_tracker/data/models/food_model.dart';
import 'package:health_tracker/data/repositories/combined_food_service.dart';
import 'package:health_tracker/data/repositories/off_api.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/challenge_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/coin_shop_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/food_details_full_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/food_details_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/quick_add_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/upc_details_screen.dart';
import 'package:health_tracker/ui/widgets/indicator_widget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  static const Color greenColor = Color(0xFF58B40B);

  static const double goalCalories = 1851;
  static const double goalCarbs = 231;
  static const double goalProtein = 93;
  static const double goalFat = 62;

  late TextEditingController _searchController;
  final PageController _macroPageController = PageController();

  String _scanBarcode = 'Unknown';
  DateTime date = DateTime.now();

  String _selectedAvatarId = 'avocado';

  final Map<String, String> _imageCache = {};

  Color get bgColor => Theme.of(context).scaffoldBackgroundColor;

  Color get cardColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E1E1E) : Colors.white;
  }

  Color get softCardColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF0D8);
  }

  Color get textColor => Theme.of(context).colorScheme.onSurface;

  Color get subTextColor {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.58);
  }

  Color get progressBgColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200;
  }

  CustomPainter _getAvatarPainter() {
    switch (_selectedAvatarId) {
      case 'piggy':
        return const PiggyMascotPainter();
      case 'rabbit':
        return const RabbitMascotPainter();
      case 'miu':
        return const MiuMascotPainter();
      case 'bamboo':
        return const BambooMascotPainter();
      case 'diamond_dragon':
        return const DiamondDragonMascotPainter();
      case 'avocado':
      default:
        return const AvocadoMascotPainter();
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadUserAvatar();
  }

  Future<void> _loadUserAvatar() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data() ?? {};
      final avatarId = data['selectedAvatar']?.toString() ??
          data['avatar']?.toString() ??
          'avocado';

      if (!mounted) return;

      setState(() {
        _selectedAvatarId = avatarId;
      });
    } catch (e) {
      debugPrint('Error loading avatar: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: bgColor,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: bgColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _macroPageController.dispose();
    super.dispose();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String? _normalizeImageUrl(dynamic value) {
    final url = value?.toString().trim();

    if (url == null || url.isEmpty || url == 'null') {
      return null;
    }

    if (url.startsWith('//')) {
      return 'https:$url';
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    return null;
  }

  String? _firstUrlFromMap(dynamic mapValue) {
    if (mapValue is! Map) return null;

    final map = Map<dynamic, dynamic>.from(mapValue);

    final preferred = [
      map['vi'],
      map['en'],
      map['fr'],
      map['es'],
    ];

    for (final value in preferred) {
      final url = _normalizeImageUrl(value);
      if (url != null) return url;
    }

    for (final value in map.values) {
      final url = _normalizeImageUrl(value);
      if (url != null) return url;
    }

    return null;
  }

  String? _extractOffImageUrl(Map<String, dynamic> product) {
    final directKeys = [
      'image_url',
      'image_front_url',
      'image_small_url',
      'image_front_small_url',
    ];

    for (final key in directKeys) {
      final url = _normalizeImageUrl(product[key]);
      if (url != null) return url;
    }

    final selectedImages = product['selected_images'];

    if (selectedImages is Map) {
      final front = selectedImages['front'];

      if (front is Map) {
        final displayUrl = _firstUrlFromMap(front['display']);
        if (displayUrl != null) return displayUrl;

        final smallUrl = _firstUrlFromMap(front['small']);
        if (smallUrl != null) return smallUrl;

        final thumbUrl = _firstUrlFromMap(front['thumb']);
        if (thumbUrl != null) return thumbUrl;
      }
    }

    return null;
  }

  Future<String?> _fetchImageForFood(
    String name, {
    String? fallbackImageUrl,
  }) async {
    final fallback = _normalizeImageUrl(fallbackImageUrl);
    if (fallback != null) return fallback;

    final cacheKey = name.trim().toLowerCase();

    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey];
    }

    try {
      final searchName = name.trim();

      if (searchName.isEmpty) return null;

      final uri = Uri.https(
        'world.openfoodfacts.org',
        '/cgi/search.pl',
        {
          'search_terms': searchName,
          'search_simple': '1',
          'action': 'process',
          'json': '1',
          'page_size': '10',
          'fields':
              'product_name,image_url,image_front_url,image_small_url,image_front_small_url,selected_images',
        },
      );

      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'health_tracker/1.0',
        },
      );

      if (response.statusCode != 200) {
        log('Image search failed: ${response.statusCode}');
        return null;
      }

      final decoded = json.decode(response.body);

      final products = decoded['products'] is List
          ? decoded['products'] as List
          : <dynamic>[];

      for (final item in products) {
        if (item is! Map) continue;

        final product = Map<String, dynamic>.from(item);
        final imageUrl = _extractOffImageUrl(product);

        if (imageUrl != null) {
          _imageCache[cacheKey] = imageUrl;
          return imageUrl;
        }
      }
    } catch (e) {
      log('Error fetching image: $e');
    }

    return null;
  }

  Widget _foodImageBox({
    required String? imageUrl,
    required String emoji,
    double size = 50,
  }) {
    final url = _normalizeImageUrl(imageUrl);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: softCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              headers: const {
                'User-Agent': 'health_tracker/1.0',
              },
              errorBuilder: (_, __, ___) {
                return Text(
                  emoji,
                  style: TextStyle(fontSize: size * 0.52),
                );
              },
            )
          : Text(
              emoji,
              style: TextStyle(fontSize: size * 0.52),
            ),
    );
  }

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes = 'Unknown';

    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Hủy',
        true,
        ScanMode.BARCODE,
      );
      log('Barcode scan result: $barcodeScanRes');
    } on PlatformException catch (e) {
      log('Barcode scan error: ${e.message}');
      barcodeScanRes = 'Error: ${e.message}';
    }

    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });
  }

  Future<void> _handleBarcodeScan() async {
    if (!mounted) return;

    log('Starting barcode scan...');
    await scanBarcodeNormal();

    if (!mounted) return;
    log('Barcode result: "$_scanBarcode"');

    if (_scanBarcode == 'Unknown' ||
        _scanBarcode == '-1' ||
        _scanBarcode.startsWith('Error')) {
      log('Scan cancelled or failed: $_scanBarcode');
      return;
    }

    log('Fetching product for UPC: $_scanBarcode');

    final product =
        await OpenFoodFactsAPI.instance.fetchProductByUPC(_scanBarcode);

    log('Product found: ${product.name}');

    if (!mounted) return;

    if (product.name.isEmpty) {
      log('Product not found in database');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          product: product,
          meal: widget.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnapshot) {
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('diary')
                  .doc(DateFormat('d-M-y').format(date))
                  .snapshots(),
              builder: (context, diarySnapshot) {
                if (!diarySnapshot.hasData || !userSnapshot.hasData) {
                  return const Center(child: MyCircularIndicator());
                }

                final diaryData =
                    diarySnapshot.data!.data() ?? <String, dynamic>{};
                final userData =
                    userSnapshot.data!.data() ?? <String, dynamic>{};

                final data = {
                  ...diaryData,
                  ...userData,
                };

                return Stack(
                  children: [
                    _buildMainContent(data),
                    _buildFloatingAddButton(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(data),
          const SizedBox(height: 22),
          _buildCalendar(),
          const SizedBox(height: 22),
          _buildSummaryCard(data),
          const SizedBox(height: 14),
          _buildMacroCards(data),
          const SizedBox(height: 12),
          _buildPageDots(),
          const SizedBox(height: 62),
          _buildRecentSection(data),
        ],
      ),
    );
  }

  int _calculateStars(Map<String, dynamic> data) {
    final completedTasks = data['completedTasks'] is List
        ? List<String>.from(data['completedTasks'])
        : <String>[];

    final completedWeeklyTasks = data['completedWeeklyTasks'] is List
        ? List<String>.from(data['completedWeeklyTasks'])
        : <String>[];

    int stars = 0;

    for (final task in completedTasks) {
      if (task.startsWith('weekly_')) {
        stars += 2;
      } else {
        stars += 1;
      }
    }

    stars += completedWeeklyTasks.length * 2;

    return stars;
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final starCount = _calculateStars(data);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'CalSnap',
          style: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 24,
              color: Color(0xFFFFC21A),
            ),
            const SizedBox(width: 6),
            Text(
              '$starCount',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 13),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChallengeScreen(date: date),
                  ),
                );
              },
              child: _topCircleIcon(Icons.emoji_events_outlined),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoinShopScreen(),
                  ),
                );

                await _loadUserAvatar();
              },
              child: Icon(
                Icons.storefront_outlined,
                size: 31,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _getCompletedTasks(Map<String, dynamic> data) {
    int count = 0;

    final totalCal = _toDouble(data['totalCalories']);
    final totalCarbs = _toDouble(data['totalCarbs']);
    final totalProtein = _toDouble(data['totalProtein']);
    final totalFat = _toDouble(data['totalFat']);
    final totalWater = _toDouble(data['totalWater'] ?? data['water'] ?? 0);

    if (totalCal >= goalCalories * 0.8) count++;
    if (totalCal <= goalCalories * 1.2) count++;
    if (totalCarbs >= goalCarbs * 0.7) count++;
    if (totalProtein >= goalProtein * 0.7) count++;
    if (totalFat <= goalFat * 1.2) count++;
    if (totalWater >= 2000) count++;

    return count;
  }

  void _showChallengeSheet(Map<String, dynamic> data) {
    final tasks = _getTasksList(data);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: subTextColor.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFC21A),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nhiệm vụ hàng ngày',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${tasks.where((t) => t['completed'] == true).length}/6 nhiệm vụ hoàn thành',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ...tasks.map<Widget>((task) => _buildTaskItem(task)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Đóng',
                  style: TextStyle(color: subTextColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getTasksList(Map<String, dynamic> data) {
    final totalCal = _toDouble(data['totalCalories']);
    final totalCarbs = _toDouble(data['totalCarbs']);
    final totalProtein = _toDouble(data['totalProtein']);
    final totalFat = _toDouble(data['totalFat']);
    final totalWater = _toDouble(data['totalWater'] ?? data['water'] ?? 0);

    return [
      {
        'title': 'Đủ calo',
        'desc': '${totalCal.toInt()}/$goalCalories kcal',
        'completed':
            totalCal >= goalCalories * 0.8 && totalCal <= goalCalories * 1.2,
        'emoji': '🔥',
      },
      {
        'title': 'Tinh bột',
        'desc': '${totalCarbs.toInt()}/$goalCarbs g',
        'completed': totalCarbs >= goalCarbs * 0.7,
        'emoji': '🍚',
      },
      {
        'title': 'Chất đạm',
        'desc': '${totalProtein.toInt()}/$goalProtein g',
        'completed': totalProtein >= goalProtein * 0.7,
        'emoji': '🥩',
      },
      {
        'title': 'Chất béo',
        'desc': '${totalFat.toInt()}/$goalFat g',
        'completed': totalFat <= goalFat * 1.2,
        'emoji': '🥑',
      },
      {
        'title': 'Uống nước',
        'desc': '${totalWater.toInt()}/2000 ml',
        'completed': totalWater >= 2000,
        'emoji': '💧',
      },
      {
        'title': 'Ăn đủ bữa',
        'desc': '3 bữa/ngày',
        'completed': _checkMealsCompleted(data),
        'emoji': '🍽️',
      },
    ];
  }

  bool _checkMealsCompleted(Map<String, dynamic> data) {
    final foods = _extractRecentFoods(data);
    if (foods.isEmpty) return false;

    final meals = <String>{};

    for (final food in foods) {
      final mealKey = food['_mealKey']?.toString() ?? '';

      if (mealKey.isNotEmpty) {
        meals.add(mealKey);
      }
    }

    return meals.length >= 3;
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final completed = task['completed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            task['emoji'] ?? '⭐',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'],
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  task['desc'],
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: completed ? greenColor : progressBgColor,
              shape: BoxShape.circle,
            ),
            child: completed
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _topCircleIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: textColor,
          width: 2.5,
        ),
      ),
      child: Icon(
        icon,
        color: textColor,
        size: 24,
      ),
    );
  }

  Widget _buildCalendar() {
    final current = DateTime(date.year, date.month, date.day);
    final monday = current.subtract(Duration(days: current.weekday - 1));

    final days = List.generate(
      7,
      (index) => monday.add(Duration(days: index)),
    );

    const dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = days[index];

        final isSelected = day.year == current.year &&
            day.month == current.month &&
            day.day == current.day;

        final diff = day.difference(current).inDays;
        final isBeforeSelected = diff == -1;
        final isAfterSelected = diff > 0;

        return GestureDetector(
          onTap: () {
            setState(() {
              date = day;
            });
          },
          child: Column(
            children: [
              Text(
                dayNames[index],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? textColor
                      : isAfterSelected
                          ? subTextColor.withOpacity(0.45)
                          : subTextColor,
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: 46,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isBeforeSelected)
                      CustomPaint(
                        size: const Size(44, 44),
                        painter: DashedCirclePainter(
                          color: subTextColor.withOpacity(0.6),
                        ),
                      ),
                    if (isSelected)
                      Positioned(
                        top: 1,
                        child: Container(
                          width: 18,
                          height: 4,
                          decoration: BoxDecoration(
                            color: textColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: isSelected ? 42 : 38,
                      height: isSelected ? 42 : 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? textColor : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).scaffoldBackgroundColor
                              : isAfterSelected
                                  ? subTextColor.withOpacity(0.45)
                                  : textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> data) {
    final foods = _extractRecentFoods(data);

    double totalCal = _toDouble(data['totalCalories']);
    double burnedCal = _toDouble(data['burnedCalories']);

    if (totalCal == 0 && foods.isNotEmpty) {
      totalCal = foods.fold<double>(
        0,
        (sum, food) => sum + _toDouble(food['calories']),
      );
    }

    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.fromLTRB(10, 14, 12, 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: SizedBox(
                  width: 190,
                  height: 155,
                  child: CustomPaint(
                    painter: _getAvatarPainter(),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _summaryRow(
                  emoji: '🏆',
                  title: 'Mục tiêu',
                  value: goalCalories.toInt(),
                  unit: 'kcal',
                ),
                const SizedBox(height: 9),
                _summaryRow(
                  emoji: '🍴',
                  title: 'Đã nạp',
                  value: totalCal.toInt(),
                  unit: 'kcal',
                ),
                const SizedBox(height: 9),
                _summaryRow(
                  emoji: '🔥',
                  title: 'Tiêu hao',
                  value: burnedCal.toInt(),
                  unit: 'kcal',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String emoji,
    required String title,
    required int value,
    required String unit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 31,
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 22),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    text: '${value.toInt()}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                    children: [
                      TextSpan(
                        text: unit,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCards(Map<String, dynamic> data) {
    final foods = _extractRecentFoods(data);

    double totalCarbs = _toDouble(data['totalCarbs']);
    double totalProtein = _toDouble(data['totalProtein']);
    double totalFat = _toDouble(data['totalFat']);
    double totalFiber = _toDouble(data['totalFiber']);
    double totalSugar = _toDouble(data['totalSugar']);
    double totalSodium = _toDouble(data['totalSodium']);

    if (foods.isNotEmpty) {
      if (totalCarbs == 0) {
        totalCarbs = foods.fold<double>(
          0,
          (sum, food) => sum + _toDouble(food['carbs']),
        );
      }

      if (totalProtein == 0) {
        totalProtein = foods.fold<double>(
          0,
          (sum, food) => sum + _toDouble(food['protein']),
        );
      }

      if (totalFat == 0) {
        totalFat = foods.fold<double>(
          0,
          (sum, food) => sum + _toDouble(food['fat']),
        );
      }

      if (totalFiber == 0) {
        totalFiber = foods.fold<double>(
          0,
          (sum, food) => sum + _toDouble(food['fiber']),
        );
      }

      if (totalSugar == 0) {
        totalSugar = foods.fold<double>(
          0,
          (sum, food) => sum + _toDouble(food['sugar']),
        );
      }

      if (totalSodium == 0) {
        totalSodium = foods.fold<double>(
          0,
          (sum, food) => sum + _toDouble(food['sodium']),
        );
      }
    }

    return SizedBox(
      height: 115,
      child: PageView(
        controller: _macroPageController,
        physics: const ClampingScrollPhysics(),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _macroCard(
                  title: 'Tinh bột',
                  value: totalCarbs,
                  goal: goalCarbs,
                  color: const Color(0xFFFFC947),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macroCard(
                  title: 'Chất đạm',
                  value: totalProtein,
                  goal: goalProtein,
                  color: const Color(0xFFFF6B75),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macroCard(
                  title: 'Chất béo',
                  value: totalFat,
                  goal: goalFat,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _macroCard(
                  title: 'Chất xơ',
                  value: totalFiber,
                  goal: 25,
                  color: const Color(0xFF8B4513),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macroCard(
                  title: 'Đường',
                  value: totalSugar,
                  goal: 50,
                  color: const Color(0xFFE91E63),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macroCard(
                  title: 'Natri',
                  value: totalSodium,
                  goal: 2300,
                  unit: 'mg',
                  color: const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroCard({
    required String title,
    required double value,
    required double goal,
    required Color color,
    String unit = 'g',
  }) {
    final percent = goal == 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);

    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              maxLines: 1,
              text: TextSpan(
                text: '${value.toInt()}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
                children: [
                  TextSpan(
                    text: '/${goal.toInt()}$unit',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: progressBgColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                value <= 0 ? progressBgColor : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageDots() {
    return AnimatedBuilder(
      animation: _macroPageController,
      builder: (context, child) {
        final page =
            _macroPageController.hasClients && _macroPageController.page != null
                ? _macroPageController.page!
                : 0.0;

        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(2, (index) {
              final isActive = index == page.round();
              final diff = (page - index).abs();

              final width = isActive
                  ? 34.0
                  : (diff < 0.5 ? 11.0 + (23.0 * (0.5 - diff)) : 11.0);

              final height = isActive
                  ? 9.0
                  : (diff < 0.5 ? 9.0 + (2.0 * (0.5 - diff)) : 11.0);

              final opacity = isActive
                  ? 1.0
                  : (diff < 0.5 ? 0.25 + (0.75 * (0.5 - diff)) : 0.25);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(opacity.clamp(0.0, 1.0)),
                    borderRadius: BorderRadius.circular(isActive ? 999 : 5),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildRecentSection(Map<String, dynamic> data) {
    final foods = _extractRecentFoods(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gần đây',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        if (foods.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: _emptyState(),
          )
        else
          Column(
            children: foods.map((food) => _recentFoodCard(food)).toList(),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _extractRecentFoods(Map<String, dynamic> data) {
    final List<Map<String, dynamic>> foods = [];

    final meals = [
      {
        'keys': ['breakfast', 'Breakfast', 'buaSang', 'morning'],
        'title': 'Bữa sáng',
      },
      {
        'keys': ['lunch', 'Lunch', 'buaTrua', 'noon'],
        'title': 'Bữa trưa',
      },
      {
        'keys': ['dinner', 'Dinner', 'buaToi', 'evening'],
        'title': 'Bữa tối',
      },
      {
        'keys': ['snacks', 'Snacks', 'snack', 'anVat'],
        'title': 'Ăn vặt',
      },
    ];

    for (final meal in meals) {
      final keys = meal['keys'] as List<String>;
      final title = meal['title'] as String;

      for (final key in keys) {
        final mealData = data[key];

        if (mealData is Map && mealData['foods'] is List) {
          final list = mealData['foods'] as List;

          for (final item in list) {
            if (item is Map) {
              final food = Map<String, dynamic>.from(item);
              food['_mealKey'] = key;
              food['_mealTitle'] = title;
              foods.add(food);
            }
          }
        }
      }
    }

    foods.sort((a, b) {
      final aTime = _getFoodDateTime(a);
      final bTime = _getFoodDateTime(b);
      return bTime.compareTo(aTime);
    });

    return foods.take(10).toList();
  }

  static DateTime _getFoodDateTime(Map<String, dynamic> food) {
    final rawCreatedAt = food['createdAt'] ?? food['timeStamp'] ?? food['date'];

    if (rawCreatedAt is Timestamp) {
      return rawCreatedAt.toDate();
    }

    if (rawCreatedAt is DateTime) {
      return rawCreatedAt;
    }

    if (rawCreatedAt is String) {
      return DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    return DateTime.now();
  }

  String _getFoodTimeText(Map<String, dynamic> food) {
    final rawTime = food['time'] ?? food['createdAtText'];

    if (rawTime != null && rawTime.toString().trim().isNotEmpty) {
      return rawTime.toString();
    }

    return DateFormat('HH:mm').format(_getFoodDateTime(food));
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(
            width: 42,
            height: 50,
            child: CustomPaint(
              painter: AppleCorePainter(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có bữa ăn nào!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Nhấn + để thêm bữa ăn đầu tiên trong ngày.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentFoodCard(Map<String, dynamic> food) {
    final name = food['name']?.toString() ?? 'Không rõ món';
    final calories = _toDouble(food['calories']);
    final carbs = _toDouble(food['carbs']);
    final protein = _toDouble(food['protein']);
    final fat = _toDouble(food['fat']);
    final imageUrl = food['imageUrl']?.toString();
    final emoji = food['emoji']?.toString() ?? '🍽️';
    final time = _getFoodTimeText(food);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodDetailsFullScreen(
              food: food,
              meal: food['_mealKey']?.toString() ?? widget.title,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.04,
              ),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            _foodImageBox(
              imageUrl: imageUrl,
              emoji: emoji,
              size: 56,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          '${calories.toInt()}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'kcal',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 1.2,
                          height: 18,
                          color: subTextColor.withOpacity(0.35),
                        ),
                        _miniMacro(icon: '🌾', value: carbs),
                        const SizedBox(width: 7),
                        _miniMacro(icon: '🥩', value: protein),
                        const SizedBox(width: 7),
                        _miniMacro(icon: '🥑', value: fat),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMacro({
    required String icon,
    required double value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 3),
        Text(
          '${value.toInt()}',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingAddButton() {
    final bottom = MediaQuery.of(context).padding.bottom + 24;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: Center(
        child: GestureDetector(
          onTap: _showAddOptionsSheet,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: greenColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: subTextColor.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'THÊM MÓN ĂN',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _optionTile(
                emoji: '🔍',
                title: 'Tìm món ăn',
                subtitle: 'Tìm kiếm món ăn từ API',
                onTap: () {
                  Navigator.pop(context);
                  _showSearchDialog();
                },
              ),
              _optionTile(
                emoji: '📷',
                title: 'Quét mã vạch',
                subtitle: 'Scan barcode bằng OpenFoodFacts',
                onTap: () {
                  Navigator.pop(context);
                  _handleBarcodeScan();
                },
              ),
              _optionTile(
                emoji: '⚡',
                title: 'Thêm nhanh',
                subtitle: 'Nhập calories thủ công',
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuickAddScreen(),
                    ),
                  );
                },
              ),
              _optionTile(
                emoji: '🍱',
                title: 'Món của tôi',
                subtitle: 'Danh sách món ăn đã lưu',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _optionTile({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 2,
        ),
        leading: Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: subTextColor,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: subTextColor,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showSearchDialog() {
    _searchController.clear();

    String localQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: subTextColor.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Tìm món ăn...',
                      hintStyle: TextStyle(color: subTextColor),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: subTextColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.arrow_forward_rounded,
                          color: textColor,
                        ),
                        onPressed: () {
                          setModalState(() {
                            localQuery = _searchController.text.trim();
                          });
                        },
                      ),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (value) {
                      setModalState(() {
                        localQuery = value.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: localQuery.isEmpty
                        ? Center(
                            child: Text(
                              'Nhập tên món ăn để tìm kiếm',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : FutureBuilder<List<Food>>(
                            future: CombinedFoodService.instance.searchFood(
                              localQuery,
                            ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: MyCircularIndicator(),
                                );
                              }

                              final foods = snapshot.data!;

                              if (foods.isEmpty) {
                                return Center(
                                  child: Text(
                                    'Không tìm thấy món ăn',
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: foods.length,
                                itemBuilder: (context, index) {
                                  final food = foods[index];

                                  String calories = '?';

                                  for (final nutrient in food.nutrients) {
                                    if (nutrient['nutrientId'] == 1008) {
                                      calories = nutrient['value'].toString();
                                    }
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ListTile(
                                      leading: _foodImageBox(
                                        imageUrl: food.imageUrl,
                                        emoji: '🍽️',
                                        size: 50,
                                      ),
                                      title: Text(
                                        food.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      trailing: Text(
                                        '$calories kcal',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      onTap: () async {
                                        final imageUrl =
                                            await _fetchImageForFood(
                                          food.name,
                                          fallbackImageUrl: food.imageUrl,
                                        );

                                        final foodWithImage = Food(
                                          id: food.id,
                                          name: food.name,
                                          nutrients: food.nutrients,
                                          imageUrl: imageUrl,
                                        );

                                        if (!mounted) return;

                                        Navigator.pop(context);

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FoodDetailsScreen(
                                              food: foodWithImage,
                                              meal: widget.title,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFoodDetailsDialog(
    BuildContext ctx,
    Map<String, dynamic> food,
    String meal,
  ) {
    final calories = _toDouble(food['calories']);
    final carbs = _toDouble(food['carbs']);
    final protein = _toDouble(food['protein']);
    final fat = _toDouble(food['fat']);

    final nutrients = food['nutrients'] is List ? food['nutrients'] as List : [];
    final imageUrl = food['imageUrl']?.toString();
    final name = food['name']?.toString() ?? 'Unknown';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.76,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: subTextColor.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
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
                                headers: const {
                                  'User-Agent': 'health_tracker/1.0',
                                },
                                errorBuilder: (_, __, ___) {
                                  return const Icon(
                                    Icons.fastfood_rounded,
                                    size: 72,
                                    color: greenColor,
                                  );
                                },
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
                                _nutrientPill('Carbs', carbs, 'g'),
                                _nutrientPill('Protein', protein, 'g'),
                                _nutrientPill('Fat', fat, 'g'),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          nutrient['nutrientName']?.toString() ??
                                              '',
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _nutrientPill(String label, double value, String unit) {
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
}

class DashedCirclePainter extends CustomPainter {
  DashedCirclePainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);

    const dashCount = 12;
    const gap = 0.18;
    final sweep = (2 * math.pi / dashCount) - gap;

    for (int i = 0; i < dashCount; i++) {
      final start = i * 2 * math.pi / dashCount;
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class AppleCorePainter extends CustomPainter {
  const AppleCorePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.35, h * 0.12)
      ..cubicTo(w * 0.18, h * 0.10, w * 0.10, h * 0.28, w * 0.22, h * 0.42)
      ..cubicTo(w * 0.32, h * 0.54, w * 0.33, h * 0.66, w * 0.20, h * 0.80)
      ..cubicTo(w * 0.34, h * 0.92, w * 0.66, h * 0.92, w * 0.80, h * 0.80)
      ..cubicTo(w * 0.67, h * 0.66, w * 0.68, h * 0.54, w * 0.78, h * 0.42)
      ..cubicTo(w * 0.90, h * 0.28, w * 0.82, h * 0.10, w * 0.65, h * 0.12)
      ..cubicTo(w * 0.58, h * 0.20, w * 0.42, h * 0.20, w * 0.35, h * 0.12)
      ..close();

    canvas.drawPath(path, paint);

    final stemPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.50, h * 0.13),
      Offset(w * 0.52, h * 0.02),
      stemPaint,
    );

    final leaf = Path()
      ..moveTo(w * 0.53, h * 0.05)
      ..cubicTo(w * 0.68, h * 0.02, w * 0.78, h * 0.08, w * 0.80, h * 0.18)
      ..cubicTo(w * 0.67, h * 0.18, w * 0.58, h * 0.14, w * 0.53, h * 0.05);

    canvas.drawPath(leaf, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}