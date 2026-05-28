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
import 'package:health_tracker/data/repositories/firestore.dart';
import 'package:health_tracker/data/repositories/off_api.dart';
import 'package:health_tracker/shared/services/user_provider.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/challenge_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/coin_shop_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/streak_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/food_details_full_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/food_details_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/quick_add_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/ai_food_input_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/upc_details_screen.dart';
import 'package:health_tracker/ui/widgets/indicator_widget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> with WidgetsBindingObserver {
  static const Color greenColor = Color(0xFF58B40B);

  int _goalCaloriesValue = 1851;
  int _goalProteinPctValue = 25;
  int _goalFatPctValue = 25;
  int _goalCarbsPctValue = 50;
  bool _isReloadingGoals = false;

  double get _goalCalories => _goalCaloriesValue.toDouble();

  double get _goalCarbs {
    return _goalCalories * _goalCarbsPctValue / 100 / 4;
  }

  double get _goalProtein {
    return _goalCalories * _goalProteinPctValue / 100 / 4;
  }

  double get _goalFat {
    return _goalCalories * _goalFatPctValue / 100 / 9;
  }

  final PageController _macroPageController = PageController();
  static const int _calendarInitialPage = 1000;
final PageController _calendarPageController = PageController(
  initialPage: _calendarInitialPage,
);

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
CustomPainter _getAvatarPainter([String? avatarId]) {
  final id = avatarId ?? _selectedAvatarId;

  switch (id) {
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
    WidgetsBinding.instance.addObserver(this);
    _loadGoals();
    _loadUserAvatar();
  }

  Future<void> _loadGoals() async {
    if (_isReloadingGoals) return;

    _isReloadingGoals = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data() ?? <String, dynamic>{};

      if (!mounted) return;

      _setGoalsFromData(data);

      try {
        await context.read<UserProvider>().refreshUser();
      } catch (e) {
        debugPrint('Provider goal refresh skipped: $e');
      }
    } catch (e) {
      debugPrint('Error loading nutrition goals: $e');
    } finally {
      _isReloadingGoals = false;
    }
  }

  void _syncGoalsFromUserData(Map<String, dynamic> data) {
    final nextCalories = _readGoalInt(data['goalCalories'], _goalCaloriesValue);
    final nextProtein = _readGoalInt(data['goalProteinPct'], _goalProteinPctValue);
    final nextFat = _readGoalInt(data['goalFatPct'], _goalFatPctValue);
    final nextCarbs = _readGoalInt(data['goalCarbsPct'], _goalCarbsPctValue);

    if (nextCalories == _goalCaloriesValue &&
        nextProtein == _goalProteinPctValue &&
        nextFat == _goalFatPctValue &&
        nextCarbs == _goalCarbsPctValue) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _goalCaloriesValue = nextCalories;
        _goalProteinPctValue = nextProtein;
        _goalFatPctValue = nextFat;
        _goalCarbsPctValue = nextCarbs;
      });
    });
  }

  void _setGoalsFromData(Map<String, dynamic> data) {
    final nextCalories = _readGoalInt(data['goalCalories'], _goalCaloriesValue);
    final nextProtein = _readGoalInt(data['goalProteinPct'], _goalProteinPctValue);
    final nextFat = _readGoalInt(data['goalFatPct'], _goalFatPctValue);
    final nextCarbs = _readGoalInt(data['goalCarbsPct'], _goalCarbsPctValue);

    if (nextCalories == _goalCaloriesValue &&
        nextProtein == _goalProteinPctValue &&
        nextFat == _goalFatPctValue &&
        nextCarbs == _goalCarbsPctValue) {
      return;
    }

    setState(() {
      _goalCaloriesValue = nextCalories;
      _goalProteinPctValue = nextProtein;
      _goalFatPctValue = nextFat;
      _goalCarbsPctValue = nextCarbs;
    });
  }

  int _readGoalInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadGoals();
    }
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
  WidgetsBinding.instance.removeObserver(this);
  _macroPageController.dispose();
  _calendarPageController.dispose();
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

    if (url.startsWith('assets/')) {
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
          ? (url.startsWith('assets/')
              ? Image.asset(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Text(
                      emoji,
                      style: TextStyle(fontSize: size * 0.52),
                    );
                  },
                )
              : Image.network(
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
                ))
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tìm thấy sản phẩm với mã: $_scanBarcode'),
          backgroundColor: Colors.red,
        ),
      );
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

                _syncGoalsFromUserData(userData);

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
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: textColor,
              size: 24,
            ),
          ),
        ),
        if (!isToday)
          GestureDetector(
                    onTap: () {
            setState(() {
              date = DateTime.now();
            });

            _calendarPageController.animateToPage(
              _calendarInitialPage,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            );
          },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: greenColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Hôm nay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StreakScreen(date: date),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: Color(0xFFFFC21A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$starCount',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CoinShopScreen(),
                    ),
                  );
                },
                child: Icon(
                  Icons.storefront_outlined,
                  size: 26,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _shareMeal(data),
                child: Icon(
                  Icons.share_outlined,
                  size: 26,
                  color: textColor,
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _shareMeal(Map<String, dynamic> data) {
    final totalCal = _toDouble(data['totalCalories']);
    final totalCarbs = _toDouble(data['totalCarbs']);
    final totalProtein = _toDouble(data['totalProtein']);
    final totalFat = _toDouble(data['totalFat']);

    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    final mealName = widget.title;
    final text = [
      '🍽 $mealName - $dateStr',
      if (totalCal > 0) '🔥 $totalCal kcal',
      if (totalProtein > 0) '🥩 Protein: ${totalProtein.toStringAsFixed(1)}g',
      if (totalCarbs > 0) '🍚 Carbs: ${totalCarbs.toStringAsFixed(1)}g',
      if (totalFat > 0) '🧈 Fat: ${totalFat.toStringAsFixed(1)}g',
      '',
      '📊 Health Tracker',
    ].join('\n');

    Share.share(text, subject: 'Bữa ăn của tôi - $mealName');
  }

  int _getCompletedTasks(Map<String, dynamic> data) {
    int count = 0;

    final totalCal = _toDouble(data['totalCalories']);
    final totalCarbs = _toDouble(data['totalCarbs']);
    final totalProtein = _toDouble(data['totalProtein']);
    final totalFat = _toDouble(data['totalFat']);
    final totalWater = _toDouble(data['totalWater'] ?? data['water'] ?? 0);

    if (totalCal >= _goalCalories * 0.8) count++;
    if (totalCal <= _goalCalories * 1.2) count++;
    if (totalCarbs >= _goalCarbs * 0.7) count++;
    if (totalProtein >= _goalProtein * 0.7) count++;
    if (totalFat <= _goalFat * 1.2) count++;
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
        'desc': '${totalCal.toInt()}/$_goalCalories kcal',
        'completed':
            totalCal >= _goalCalories * 0.8 && totalCal <= _goalCalories * 1.2,
        'emoji': '🔥',
      },
      {
        'title': 'Tinh bột',
        'desc': '${totalCarbs.toInt()}/$_goalCarbs g',
        'completed': totalCarbs >= _goalCarbs * 0.7,
        'emoji': '🍚',
      },
      {
        'title': 'Chất đạm',
        'desc': '${totalProtein.toInt()}/$_goalProtein g',
        'completed': totalProtein >= _goalProtein * 0.7,
        'emoji': '🥩',
      },
      {
        'title': 'Chất béo',
        'desc': '${totalFat.toInt()}/$_goalFat g',
        'completed': totalFat <= _goalFat * 1.2,
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
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final currentWeekStart = today.subtract(
    Duration(days: today.weekday - 1),
  );

  const dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  return SizedBox(
    height: 82,
    child: PageView.builder(
      controller: _calendarPageController,

      // Cho xem lại các tuần cũ, nhưng không cho lướt sang tuần tương lai
      itemCount: _calendarInitialPage + 1,
      physics: const BouncingScrollPhysics(),

      itemBuilder: (context, pageIndex) {
        final weekOffset = pageIndex - _calendarInitialPage;

        final monday = currentWeekStart.add(
          Duration(days: weekOffset * 7),
        );

        final days = List.generate(
          7,
          (index) => monday.add(Duration(days: index)),
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final day = days[index];
            final normalizedDay = DateTime(day.year, day.month, day.day);
            final selectedDate = DateTime(date.year, date.month, date.day);

            final isSelected = normalizedDay.year == selectedDate.year &&
                normalizedDay.month == selectedDate.month &&
                normalizedDay.day == selectedDate.day;

            final isToday = normalizedDay.year == today.year &&
                normalizedDay.month == today.month &&
                normalizedDay.day == today.day;

            final isFuture = normalizedDay.isAfter(today);

            return FutureBuilder<_DailyCalorieInfo>(
              future: _getDayCalorieInfo(day),
              builder: (context, snapshot) {
                final info = snapshot.data ?? _DailyCalorieInfo.empty(day);

                final ringColor = _getDailyRingColor(
                  info: info,
                  isFuture: isFuture,
                );

                return GestureDetector(
                  onTap: isFuture
                      ? () {
                          HapticFeedback.lightImpact();
                          _showToast('Ngày này chưa đến');
                        }
                      : () {
                          setState(() {
                            date = day;
                          });
                        },
                  child: Opacity(
                    opacity: isFuture ? 0.45 : 1,
                    child: Column(
                      children: [
                        Text(
                          dayNames[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? textColor : subTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 50,
                          height: 52,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isToday)
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: greenColor.withOpacity(0.10),
                                  ),
                                ),

                              CustomPaint(
                                size: const Size(46, 46),
                                painter: DailyCalorieRingPainter(
                                  progress: info.progress,
                                  color: ringColor,
                                  backgroundColor: progressBgColor,
                                  hasData: info.hasData,
                                ),
                              ),

                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: isSelected ? 38 : 34,
                                height: isSelected ? 38 : 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? textColor
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.16),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: isSelected ? bgColor : textColor,
                                    fontSize: isSelected ? 18 : 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),

                              if (isFuture)
                                Positioned(
                                  right: 1,
                                  bottom: 4,
                                  child: Icon(
                                    Icons.lock_rounded,
                                    size: 12,
                                    color: subTextColor,
                                  ),
                                ),

                              if (isSelected)
                                Positioned(
                                  top: 0,
                                  child: Container(
                                    width: 18,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: textColor,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        );
      },
    ),
  );
}
Future<_DailyCalorieInfo> _getDayCalorieInfo(DateTime day) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return _DailyCalorieInfo.empty(day);
  }

  final dateKey = _getDateKey(day);

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diary')
        .doc(dateKey)
        .get();

    final data = doc.data();

    if (data == null || data.isEmpty) {
      return _DailyCalorieInfo.empty(day);
    }

    double totalCal = _toDouble(data['totalCalories']);

    if (totalCal <= 0) {
      final foods = _extractRecentFoods(data);

      if (foods.isNotEmpty) {
        totalCal = foods.fold<double>(
          0,
          (sum, food) => sum + _toDouble(food['calories']),
        );
      }
    }

    final goal = _goalCalories <= 0 ? 1.0 : _goalCalories;
    final ratio = totalCal / goal;

    return _DailyCalorieInfo(
      date: day,
      totalCalories: totalCal,
      goalCalories: goal,
      ratio: ratio,
    );
  } catch (e) {
    log('Error loading daily calorie ring: $e');
    return _DailyCalorieInfo.empty(day);
  }
}

Color _getDailyRingColor({
  required _DailyCalorieInfo info,
  required bool isFuture,
}) {
  if (isFuture || !info.hasData) {
    return progressBgColor;
  }

  if (info.ratio > 1.0) {
    return const Color(0xFFFF5A5F); // đỏ: vượt calories
  }

  if (info.ratio >= 0.90) {
    return const Color(0xFFFFA726); // cam: gần vượt mục tiêu
  }

  return greenColor; // xanh: trong mục tiêu
}

String _getDateKey(DateTime value) {
  return DateFormat('d-M-y').format(value);
}

  Widget _buildSummaryCard(Map<String, dynamic> data) {
    final foods = _extractRecentFoods(data);
    final selectedAvatarId = data['selectedAvatar']?.toString() ??
    data['avatar']?.toString() ??'avocado';
    double totalCal = _toDouble(data['totalCalories']);
    double burnedCal = _toDouble(data['burnedCalories']);

    if (totalCal == 0 && foods.isNotEmpty) {
      totalCal = foods.fold<double>(
        0,
        (sum, food) => sum + _toDouble(food['calories']),
      );
    }

    final steps = _toDouble(data['totalSteps'] ?? 0);
    final stepCalories = (steps * 0.04).round();

    final exerciseCal = _toDouble(data['exerciseCalories'] ?? 0);
    final waterCal = _toDouble(data['waterCalories'] ?? 0);
    final activityCalories = (exerciseCal + waterCal).round();

    final totalBurned = (burnedCal + stepCalories + activityCalories).toInt();

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
                    painter: _getAvatarPainter(selectedAvatarId),
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
                  value: _goalCalories.toInt(),
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
                  value: totalBurned,
                  unit: 'kcal',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieDetails(Map<String, dynamic> data) {
    double totalCal = _toDouble(data['totalCalories']);
    double burnedCal = _toDouble(data['burnedCalories']);

    final breakfastCal = _toDouble(data['breakfastCalories']);
    final lunchCal = _toDouble(data['lunchCalories']);
    final dinnerCal = _toDouble(data['dinnerCalories']);
    final snacksCal = _toDouble(data['snacksCalories']);
    final mealCalories = breakfastCal + lunchCal + dinnerCal + snacksCal;

    final steps = _toDouble(data['totalSteps'] ?? 0);
    final stepCalories = (steps * 0.04).round();

    final exerciseCal = _toDouble(data['exerciseCalories'] ?? 0);
    final waterCal = _toDouble(data['waterCalories'] ?? 0);
    final activityCalories = exerciseCal + waterCal;

    final netCalories = totalCal - burnedCal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết Calo',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _calorieDetailTile(
                  emoji: '🍴',
                  label: 'Bữa ăn',
                  value: mealCalories.toInt(),
                  color: const Color(0xFFFFC947),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _calorieDetailTile(
                  emoji: '👟',
                  label: 'Bước chân',
                  value: stepCalories,
                  color: const Color(0xFF58B40B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _calorieDetailTile(
                  emoji: '💪',
                  label: 'Tập luyện',
                  value: activityCalories.toInt(),
                  color: const Color(0xFFFF6B75),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _calorieDetailTile(
                  emoji: '📊',
                  label: 'Tổng ròng',
                  value: netCalories.toInt(),
                  color: netCalories >= 0
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF58B40B),
                  isBold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calorieDetailTile({
    required String emoji,
    required String label,
    required int value,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: subTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: isBold ? 20 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'kcal',
            style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
                  goal: _goalCarbs,
                  color: const Color(0xFFFFC947),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macroCard(
                  title: 'Chất đạm',
                  value: totalProtein,
                  goal: _goalProtein,
                  color: const Color(0xFFFF6B75),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macroCard(
                  title: 'Chất béo',
                  value: totalFat,
                  goal: _goalFat,
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
        dynamic mealData = data[key];

        if (mealData is! Map) {
          final lowerKey = key.toLowerCase();
          mealData = data[lowerKey];
        }

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

    final newFoods = <Map<String, dynamic>>[];
    final oldFoods = <Map<String, dynamic>>[];
    
    for (final food in foods) {
      final ts = _getFoodTimestamp(food);
      if (ts > 0) {
        newFoods.add(food);
      } else {
        oldFoods.add(food);
      }
    }
    
    newFoods.sort((a, b) => _getFoodTimestamp(b).compareTo(_getFoodTimestamp(a)));
    
    return [...newFoods, ...oldFoods].take(20).toList();
  }

  static DateTime _getFoodDateTime(Map<String, dynamic> food) {
    final rawCreatedAt = food['createdAt'] ?? food['timeStamp'] ?? food['date'];

    if (rawCreatedAt is Timestamp) {
      return rawCreatedAt.toDate();
    }

    if (rawCreatedAt is DateTime) {
      return rawCreatedAt;
    }

    if (rawCreatedAt is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    }

    if (rawCreatedAt is double) {
      return DateTime.fromMillisecondsSinceEpoch(rawCreatedAt.toInt());
    }

    if (rawCreatedAt is String && rawCreatedAt.isNotEmpty) {
      return DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    return DateTime.now();
  }

  int _getFoodTimestamp(Map<String, dynamic> food) {
    final rawCreatedAt = food['createdAt'];

    if (rawCreatedAt is int) {
      return rawCreatedAt;
    }
    if (rawCreatedAt is Timestamp) {
      return rawCreatedAt.millisecondsSinceEpoch;
    }
    if (rawCreatedAt is double) {
      return rawCreatedAt.toInt();
    }
    if (rawCreatedAt is String && rawCreatedAt.isNotEmpty) {
      return int.tryParse(rawCreatedAt) ?? 0;
    }

    return 0;
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
              size: 48,
            ),
            const SizedBox(width: 10),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${calories.toInt()}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          ' kcal',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _miniMacro(icon: '🌾', value: carbs),
                        const SizedBox(width: 5),
                        _miniMacro(icon: '🥩', value: protein),
                        const SizedBox(width: 5),
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
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 2),
        Text(
          '${value.toInt()}',
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
                emoji: '🤖',
                title: 'AI Phân tích',
                subtitle: 'Nhập hoặc nói món ăn, AI tự tính dinh dưỡng',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AIFoodInputScreen(
                        mealTitle: widget.title,
                      ),
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
                  _showMyDishesSheet();
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

  void _showToast(String text) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 450),
          tween: Tween(begin: -120, end: 40),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Positioned(
              top: value,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: greenColor.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: greenColor.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: const Center(
                            child: Icon(Icons.check_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  Widget _dishPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.restaurant_rounded, color: Colors.grey.withOpacity(0.5), size: 24),
    );
  }

  void _showMyDishesSheet() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
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
              const SizedBox(height: 12),
              Text(
                '🍱  Món của tôi',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chạm vào món ăn để thêm vào nhật ký',
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('myDishes')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Có lỗi xảy ra',
                          style: TextStyle(color: subTextColor),
                        ),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🍽️', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có món ăn nào',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Thêm món ăn từ công thức để lưu lại',
                              style: TextStyle(color: subTextColor, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? '';
                        final calories = (data['calories'] ?? 0).toDouble();
                        final protein = (data['protein'] ?? 0).toDouble();
                        final carbs = (data['carbs'] ?? 0).toDouble();
                        final fat = (data['fat'] ?? 0).toDouble();
                        final imageUrl = data['imageUrl'] ?? '';

                        return Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.endToStart,
                          dismissThresholds: const {
                            DismissDirection.endToStart: 0.35,
                          },
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Xóa món ăn',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (direction) async {
                            final saved = Map<String, dynamic>.from(data);
                            final docId = doc.id;
                            final mType = (saved['mealType'] ?? '') as String;
                            final dFoodId =
                                (saved['diaryFoodId'] ?? '') as String;

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('myDishes')
                                .doc(docId)
                                .delete();

                            if (mType.isNotEmpty && dFoodId.isNotEmpty) {
                              await FireStoreCrud().removeDiaryMealFood(
                                mType,
                                dFoodId,
                                saved['name'] ?? '',
                                (saved['calories'] ?? 0).toDouble(),
                                (saved['carbs'] ?? 0).toDouble(),
                                (saved['fat'] ?? 0).toDouble(),
                                (saved['protein'] ?? 0).toDouble(),
                                'myDish',
                                fiber: _toDouble(saved['fiber']),
                                sugar: _toDouble(saved['sugar']),
                                sodium: _toDouble(saved['sodium']),
                              );
                            }

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã xóa "${saved['name']}"'),
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: 'HOÀN TÁC',
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .collection('myDishes')
                                        .doc(docId)
                                        .set(saved);

                                    if (mType.isNotEmpty &&
                                        dFoodId.isNotEmpty) {
                                      await FireStoreCrud().updateDiaryMeal(
                                        mType,
                                        dFoodId,
                                        'myDish',
                                        saved['name'] ?? '',
                                        (saved['calories'] ?? 0).toDouble(),
                                        (saved['carbs'] ?? 0).toDouble(),
                                        (saved['fat'] ?? 0).toDouble(),
                                        (saved['protein'] ?? 0).toDouble(),
                                        imageUrl: saved['imageUrl'] ?? '',
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl.isNotEmpty
                                    ? (imageUrl.startsWith('assets/')
                                        ? Image.asset(
                                            imageUrl,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _dishPlaceholder(),
                                          )
                                        : Image.network(
                                            imageUrl,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _dishPlaceholder(),
                                          ))
                                    : _dishPlaceholder(),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${calories.round()} kcal · P: ${protein.round()}g · C: ${carbs.round()}g · F: ${fat.round()}g',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                Icons.add_circle_outline_rounded,
                                color: greenColor,
                                size: 28,
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                final foodId =
                                    'my_dish_${doc.id}_${DateTime.now().millisecondsSinceEpoch}';

                                await FireStoreCrud().updateDiaryMeal(
                                  widget.title,
                                  foodId,
                                  'myDish',
                                  name,
                                  calories,
                                  carbs,
                                  fat,
                                  protein,
                                  imageUrl: imageUrl,
                                );

                                if (!context.mounted) return;
                                _showToast(
                                    'Đã thêm vào ${widget.title}');
                              },
                            ),
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
  }

  Future<void> _showSearchDialog() async {
    final searchController = TextEditingController();

    String localQuery = '';

    await showModalBottomSheet(
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
                    controller: searchController,
                    autofocus: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Tìm món ăn...',
                      hintStyle: TextStyle(color: subTextColor),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: subTextColor,
                      ),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
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
                        : localQuery.length < 2
                            ? Center(
                                child: Text(
                                  'Nhập ít nhất 2 ký tự để tìm kiếm',
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

                                  if (food.calories != null) {
                                    calories = food.calories!.toInt().toString();
                                  } else {
                                    for (final nutrient in food.nutrients) {
                                      if (nutrient['nutrientId'] == 1008 ||
                                          nutrient['nutrientName'] == 'Calories' ||
                                          nutrient['nutrientName'] == 'Energy') {
                                        calories = nutrient['value'].toString();
                                        break;
                                      }
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

    searchController.dispose();
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
                            ? (imageUrl.startsWith('assets/')
                                ? Image.asset(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return const Icon(
                                        Icons.fastfood_rounded,
                                        size: 72,
                                        color: greenColor,
                                      );
                                    },
                                  )
                                : Image.network(
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
                                  ))
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
class _DailyCalorieInfo {
  const _DailyCalorieInfo({
    required this.date,
    required this.totalCalories,
    required this.goalCalories,
    required this.ratio,
  });

  final DateTime date;
  final double totalCalories;
  final double goalCalories;
  final double ratio;

  bool get hasData => totalCalories > 0;

  double get progress {
    if (!hasData || goalCalories <= 0) return 0;
    return ratio.clamp(0.0, 1.0);
  }

  factory _DailyCalorieInfo.empty(DateTime date) {
    return _DailyCalorieInfo(
      date: date,
      totalCalories: 0,
      goalCalories: 1,
      ratio: 0,
    );
  }
}
class DailyCalorieRingPainter extends CustomPainter {
  DailyCalorieRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.hasData,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final bool hasData;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 7) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 4.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (!hasData || progress <= 0) return;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DailyCalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.hasData != hasData;
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

class CalorieStatusCirclePainter extends CustomPainter {
  CalorieStatusCirclePainter({
    required this.status,
    required this.color,
  });

  final String status;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);

    if (status == 'full') {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        (size.width - 6) / 2,
        paint,
      );
    } else if (status == 'partial') {
      final dashCount = 12;
      const gap = 0.15;
      final sweep = (2 * math.pi / dashCount) * 0.5 - gap;

      for (int i = 0; i < dashCount; i++) {
        if (i < 6) {
          final start = i * 2 * math.pi / dashCount;
          canvas.drawArc(rect, start, sweep, false, paint);
        }
      }
    } else {
      final dashCount = 12;
      const gap = 0.15;
      final sweep = (2 * math.pi / dashCount) * 0.25 - gap;

      for (int i = 0; i < dashCount; i++) {
        if (i < 3) {
          final start = i * 2 * math.pi / dashCount;
          canvas.drawArc(rect, start, sweep, false, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CalorieStatusCirclePainter oldDelegate) {
    return oldDelegate.status != status || oldDelegate.color != color;
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