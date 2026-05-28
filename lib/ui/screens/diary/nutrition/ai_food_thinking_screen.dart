import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:health_tracker/data/repositories/gemini_food_service.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/ai_food_result_screen.dart';

class AIFoodThinkingScreen extends StatefulWidget {
  final String mealTitle;
  final String foodInput;

  const AIFoodThinkingScreen({
    super.key,
    required this.mealTitle,
    required this.foodInput,
  });

  @override
  State<AIFoodThinkingScreen> createState() => _AIFoodThinkingScreenState();
}

class _AIFoodThinkingScreenState extends State<AIFoodThinkingScreen>
    with TickerProviderStateMixin {
  static const Color _green = Color(0xFF58B40B);
  static const Color _lime = Color(0xFFB8F35C);
  static const Color _deepGreen = Color(0xFF143D1B);

  late final AnimationController _orbitController;
  late final AnimationController _breathController;
  late final AnimationController _shineController;

  Timer? _stepTimer;

  int _activeStep = 0;
  bool _isDone = false;
  bool _isAnalyzing = false;
  String? _error;

  final List<_AiStepData> _steps = const [
    _AiStepData(
      icon: Icons.restaurant_menu_rounded,
      title: 'Đọc mô tả món ăn',
      subtitle: 'AI đang hiểu khẩu phần và tên món',
    ),
    _AiStepData(
      icon: Icons.science_rounded,
      title: 'Ước tính dinh dưỡng',
      subtitle: 'Phân tích calories, protein, carb và fat',
    ),
    _AiStepData(
      icon: Icons.auto_graph_rounded,
      title: 'Tạo kết quả',
      subtitle: 'Chuẩn bị bảng phân tích cho bữa ăn',
    ),
  ];

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get textColor => Theme.of(context).colorScheme.onSurface;

  Color get subTextColor {
    return isDark ? Colors.white60 : const Color(0xFF667085);
  }

  @override
  void initState() {
    super.initState();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.94,
      upperBound: 1.06,
    )..repeat(reverse: true);

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _startStepTimer();
    _analyzeFood();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _orbitController.dispose();
    _breathController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  void _startStepTimer() {
    _stepTimer?.cancel();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 1150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_activeStep < _steps.length - 1) {
        setState(() {
          _activeStep++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _analyzeFood() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _isDone = false;
    });

    try {
      final results = await GeminiFoodService.analyzeFood(widget.foodInput);

      if (!mounted) return;

      if (results.isEmpty) {
        _stepTimer?.cancel();
        setState(() {
          _isAnalyzing = false;
          _error =
              'AI chưa phân tích được món ăn này. Hãy thử nhập rõ hơn, ví dụ: 1 tô phở bò, 1 ly sữa không đường.';
        });
        return;
      }

      _stepTimer?.cancel();

      setState(() {
        _activeStep = _steps.length - 1;
        _isDone = true;
        _isAnalyzing = false;
      });

      await Future.delayed(const Duration(milliseconds: 650));

      if (!mounted) return;

      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => AIFoodResultScreen(
            mealTitle: widget.mealTitle,
            foodInput: widget.foodInput,
            results: results,
          ),
        ),
      );

      if (!mounted) return;

      Navigator.pop(context, saved == true);
    } catch (e) {
      if (!mounted) return;

      _stepTimer?.cancel();

      setState(() {
        _isAnalyzing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _retry() {
    setState(() {
      _activeStep = 0;
      _error = null;
      _isDone = false;
    });

    _startStepTimer();
    _analyzeFood();
  }

  double get _progress {
    if (_isDone) return 1;
    return (_activeStep + 1) / _steps.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _error == null
                        ? _buildThinkingView()
                        : _buildErrorView(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF061108),
                  Color(0xFF0E1711),
                  Color(0xFF111111),
                ]
              : const [
                  Color(0xFFEFFFF0),
                  Color(0xFFF8FFF3),
                  Color(0xFFFFFFFF),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _blurCircle(220, _lime.withOpacity(isDark ? 0.14 : 0.28)),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _blurCircle(240, _green.withOpacity(isDark ? 0.12 : 0.18)),
          ),
          Positioned(
            top: 150,
            left: -45,
            child: _blurCircle(120, Colors.orange.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _circleButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context, false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI Nutrition Lab',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _green.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: _green,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(
                  'AI',
                  style: TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
          ],
        ),
        child: Icon(
          icon,
          color: textColor,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildThinkingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
      child: Column(
        children: [
          const SizedBox(height: 18),
          _buildFoodPreview(),
          const SizedBox(height: 34),
          _buildHero(),
          const SizedBox(height: 34),
          _buildTitle(),
          const SizedBox(height: 22),
          _buildProgressCard(),
          const SizedBox(height: 18),
          _buildSmartHint(),
        ],
      ),
    );
  }

  Widget _buildFoodPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.white.withOpacity(0.9),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.fastfood_rounded,
              color: _green,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.foodInput,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _shineController,
            builder: (context, _) {
              return Transform.rotate(
                angle: _shineController.value * math.pi * 2,
                child: Container(
                  width: 218,
                  height: 218,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        _green.withOpacity(0.0),
                        _green.withOpacity(0.5),
                        _lime.withOpacity(0.8),
                        _green.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 204,
            height: 204,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF111A13) : const Color(0xFFF8FFF4),
            ),
          ),
          _buildOrbitingFoods(),
          ScaleTransition(
            scale: _breathController,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF294D25),
                          Color(0xFF0C2412),
                        ]
                      : const [
                          Color(0xFFFFFFFF),
                          Color(0xFFE9FFD8),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _green.withOpacity(0.35),
                    blurRadius: 38,
                    spreadRadius: 8,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.08 : 0.9),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text(
                  '🥗',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? _deepGreen : Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _green.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      value: _isDone ? 1 : null,
                      strokeWidth: 2,
                      color: _green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isDone ? 'Hoàn tất' : 'Đang phân tích',
                    style: const TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
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

  Widget _buildOrbitingFoods() {
    final foods = ['🍚', '🥩', '🥑', '🥛', '🍳'];

    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(foods.length, (index) {
            final angle = (_orbitController.value * math.pi * 2) +
                (index * math.pi * 2 / foods.length);

            final radius = index.isEven ? 91.0 : 76.0;
            final dx = math.cos(angle) * radius;
            final dy = math.sin(angle) * radius;

            return Transform.translate(
              offset: Offset(dx, dy),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.92),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.white,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.16 : 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    foods[index],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTitle() {
    final currentTitle = _isDone ? 'Đã phân tích xong' : _steps[_activeStep].title;
    final currentSubtitle =
        _isDone ? 'Đang mở màn hình kết quả cho bạn' : _steps[_activeStep].subtitle;

    return Column(
      children: [
        Text(
          currentTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 25,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            currentSubtitle,
            key: ValueKey(currentSubtitle),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const _AnimatedDots(color: _green),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.white,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Tiến trình',
                style: TextStyle(
                  color: _green,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _progress),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  return Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _progress),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  minHeight: 9,
                  value: value,
                  backgroundColor:
                      isDark ? Colors.white10 : const Color(0xFFEAF0E6),
                  color: _green,
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Column(
            children: List.generate(_steps.length, (index) {
              final isCompleted = _isDone || index < _activeStep;
              final isActive = !_isDone && index == _activeStep;
              final isLast = index == _steps.length - 1;

              return _buildStepTile(
                data: _steps[index],
                index: index,
                isCompleted: isCompleted,
                isActive: isActive,
                isLast: isLast,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile({
    required _AiStepData data,
    required int index,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    final iconColor = isCompleted || isActive ? Colors.white : subTextColor;
    final iconBg = isCompleted
        ? _green
        : isActive
            ? _green.withOpacity(0.85)
            : subTextColor.withOpacity(0.12);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: _green.withOpacity(0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : data.icon,
                color: iconColor,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? _green.withOpacity(0.7)
                      : subTextColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive
                  ? _green.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? _green.withOpacity(0.18)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: isActive || isCompleted ? textColor : subTextColor,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _green.withOpacity(isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tips_and_updates_rounded,
            color: _green,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mẹo: mô tả càng rõ khẩu phần thì kết quả calories càng sát hơn.',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF31533A),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red.withOpacity(0.16)),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 52,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa phân tích được',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _error ?? 'Đã có lỗi xảy ra.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFD0D5DD),
                    ),
                  ),
                  child: Text(
                    'Nhập lại',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
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

class _AiStepData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AiStepData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _AnimatedDots extends StatefulWidget {
  final Color color;

  const _AnimatedDots({
    required this.color,
  });

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 520),
      ),
    );

    _animations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0.35, end: 1).animate(
            CurvedAnimation(
              parent: controller,
              curve: Curves.easeInOut,
            ),
          ),
        )
        .toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) {
          return FadeTransition(
            opacity: _animations[index],
            child: Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}