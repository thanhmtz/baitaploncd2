import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:health_tracker/ui/widgets/cactus_visual_state.dart';

/// Danh sách 5 asset cây mới theo đúng mốc level:
/// 1-4, 5-14, 15-34, 35-69, 70-100.
///
/// Lưu ý: 5 ảnh này đã có bãi đất riêng bên dưới cây.
/// Vì vậy TogetherScreen KHÔNG cần vẽ _MeadowGroundScene/_MeadowGroundPainter nữa.
///
/// Thêm vào pubspec.yaml:
/// flutter:
///   assets:
///     - assets/images/tree/
const List<String> meadowTreeAssetPaths = [
  'assets/images/tree/1.png',
  'assets/images/tree/2.png',
  'assets/images/tree/3.png',
  'assets/images/tree/4.png',
  'assets/images/tree/5.png',
];

/// Image-based Meadow Buddy Tree.
///
/// Giữ nguyên API cũ để TogetherScreen không phải đổi nhiều:
/// EvolvingCactusPet(level, visualState, width, height)
///
/// Bản v2 thêm nhiều hiệu ứng để cây có hồn hơn:
/// - thở / lơ lửng / nghiêng thân
/// - bóng mềm dưới bãi đất co giãn nhẹ
/// - halo, vòng sáng khi tiến hóa
/// - bụi sáng / đom đóm bay quanh cây
/// - bướm bay theo quỹ đạo + vỗ cánh
/// - cánh hoa rơi, lá bay, tim nhỏ khi hoàn thành ngày
/// - giọt nước, zzz, dấu stress theo trạng thái visualState
class EvolvingCactusPet extends StatefulWidget {
  final int level;
  final CactusVisualState visualState;
  final double width;
  final double height;

  const EvolvingCactusPet({
    super.key,
    required this.level,
    this.visualState = const CactusVisualState.neutral(),
    this.width = 300,
    this.height = 390,
  });

  @override
  State<EvolvingCactusPet> createState() => _EvolvingCactusPetState();
}

class _EvolvingCactusPetState extends State<EvolvingCactusPet>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _evolveController;
  late final AnimationController _auraController;

  @override
  void initState() {
    super.initState();

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();

    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();

    _evolveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    )..value = 1.0;
  }

  @override
  void didUpdateWidget(covariant EvolvingCactusPet oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldLevel = oldWidget.level.clamp(1, 100).toInt();
    final newLevel = widget.level.clamp(1, 100).toInt();
    final oldStage = MeadowTreeStage.fromLevel(oldLevel);
    final newStage = MeadowTreeStage.fromLevel(newLevel);

    // Tăng level hoặc đổi mốc tiến hóa thì bật burst animation.
    if (newLevel > oldLevel || newStage != oldStage) {
      _evolveController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _evolveController.dispose();
    _auraController.dispose();
    super.dispose();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _stageScale(MeadowTreeStage stage, double progress) {
    // Ảnh mới đã có bãi đất, nên scale nhẹ để giữ chân cây đúng vị trí.
    return switch (stage) {
      MeadowTreeStage.seed => _lerp(0.76, 0.82, progress),
      MeadowTreeStage.sprout => _lerp(0.84, 0.90, progress),
      MeadowTreeStage.buddy => _lerp(0.92, 0.99, progress),
      MeadowTreeStage.garden => _lerp(1.00, 1.06, progress),
      MeadowTreeStage.festival => _lerp(1.05, 1.12, progress),
    };
  }

  Offset _idleOffset(double t) {
    final visual = widget.visualState;

    if (visual.isVeryStressed) {
      return Offset(
        math.sin(t * math.pi * 38) * 1.35,
        math.cos(t * math.pi * 26) * 0.55,
      );
    }

    if (visual.isExhausted) {
      return Offset(
        math.sin(t * math.pi * 2) * 0.25,
        3.4 + math.sin(t * math.pi * 2) * 0.6,
      );
    }

    final floatPower = 1.2 + visual.floatPower * 5.0;

    return Offset(
      math.sin(t * math.pi * 2) * 0.55,
      math.sin(t * math.pi * 2) * -floatPower,
    );
  }

  double _idleAngle(double t) {
    final visual = widget.visualState;

    if (visual.isVeryStressed) return math.sin(t * math.pi * 34) * 0.010;
    if (visual.isExhausted) return -0.020;
    if (visual.isSleepy) return -0.012 + math.sin(t * math.pi * 2) * 0.004;
    if (visual.isEnergetic) return math.sin(t * math.pi * 2) * 0.018;

    return math.sin(t * math.pi * 2) * (0.004 + visual.swayPower * 0.014);
  }

  double _idleScale(double t) {
    final visual = widget.visualState;
    if (visual.isExhausted) return 0.985;

    final breath = 0.006 + visual.breathPower * 0.018;
    return 1.0 + math.sin(t * math.pi * 2).abs() * breath;
  }
  bool _showButterflies(MeadowTreeStage stage) {
    final visual = widget.visualState;

    return visual.butterflyCount > 0 ||
        visual.butterflyPower > 0.05 ||
        stage.index >= MeadowTreeStage.buddy.index ||
        visual.isLegendary;
  }
  bool _showMagic(MeadowTreeStage stage) {
  final visual = widget.visualState;

  return visual.shouldAnimate ||
      _evolveController.isAnimating ||
      visual.auraPower > 0.08 ||
      visual.sparklePower > 0.08 ||
      visual.fireflyPower > 0.08 ||
      visual.petalPower > 0.08 ||
      visual.heartPower > 0.08 ||
      stage.index >= MeadowTreeStage.buddy.index;
}

  @override
  Widget build(BuildContext context) {
    final safeLevel = widget.level.clamp(1, 100).toInt();
    final stage = MeadowTreeStage.fromLevel(safeLevel);
    final progress = stage.progressOf(safeLevel);
    final baseScale = _stageScale(stage, progress);

    final treeImage = AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: Image.asset(
        stage.assetPath,
        key: ValueKey<String>(stage.assetPath),
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );

    final mergedAnimation = Listenable.merge([
      _idleController,
      _auraController,
      _evolveController,
    ]);

    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: mergedAnimation,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _MeadowTreeBackFxPainter(
                        time: _idleController.value,
                        auraTime: _auraController.value,
                        level: safeLevel,
                        stage: stage,
                        visualState: widget.visualState,
                        showMagic: _showMagic(stage),
                        evolveProgress: _evolveController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
            AnimatedBuilder(
              animation: mergedAnimation,
              child: treeImage,
              builder: (context, child) {
                final t = _idleController.value;
                final evolveValue = _evolveController.value.clamp(0.0, 1.0).toDouble();
                final evolveEase = Curves.easeOutBack.transform(evolveValue);
                final evolveScale = 0.90 + evolveEase * 0.10;
                final evolveOpacity = (0.38 + Curves.easeOut.transform(evolveValue) * 0.62)
                    .clamp(0.0, 1.0)
                    .toDouble();

                return Transform.translate(
                  offset: _idleOffset(t),
                  child: Transform.rotate(
                    angle: _idleAngle(t),
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scale: baseScale * _idleScale(t) * evolveScale,
                      alignment: Alignment.bottomCenter,
                      child: Opacity(
                        opacity: evolveOpacity,
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: mergedAnimation,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _MeadowTreeFrontFxPainter(
                        time: _idleController.value,
                        auraTime: _auraController.value,
                        level: safeLevel,
                        stage: stage,
                        visualState: widget.visualState,
                        showMagic: _showMagic(stage),
                        showButterflies: _showButterflies(stage),
                        evolveProgress: _evolveController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum MeadowTreeStage {
  seed(1, 4, 'Seed', 'assets/images/tree/1.png'),
  sprout(5, 14, 'Sprout', 'assets/images/tree/2.png'),
  buddy(15, 34, 'Buddy Tree', 'assets/images/tree/3.png'),
  garden(35, 69, 'Garden Tree', 'assets/images/tree/4.png'),
  festival(70, 100, 'Festival Tree', 'assets/images/tree/5.png');

  final int minLevel;
  final int maxLevel;
  final String label;
  final String assetPath;

  const MeadowTreeStage(this.minLevel, this.maxLevel, this.label, this.assetPath);

  static MeadowTreeStage fromLevel(int level) {
    if (level >= 70) return MeadowTreeStage.festival;
    if (level >= 35) return MeadowTreeStage.garden;
    if (level >= 15) return MeadowTreeStage.buddy;
    if (level >= 5) return MeadowTreeStage.sprout;
    return MeadowTreeStage.seed;
  }

  double progressOf(int level) {
    if (maxLevel <= minLevel) return 1.0;

    return ((level - minLevel) / (maxLevel - minLevel))
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

class _MeadowTreeBackFxPainter extends CustomPainter {
  final double time;
  final double auraTime;
  final int level;
  final MeadowTreeStage stage;
  final CactusVisualState visualState;
  final bool showMagic;
  final double evolveProgress;

  const _MeadowTreeBackFxPainter({
    required this.time,
    required this.auraTime,
    required this.level,
    required this.stage,
    required this.visualState,
    required this.showMagic,
    required this.evolveProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final glowPower = visualState.glowPower.clamp(0.0, 1.0).toDouble();
    final evolveBurst = (1.0 - evolveProgress).clamp(0.0, 1.0).toDouble();

    _drawBreathingShadow(canvas, w, h);

    if (glowPower > 0.05 || stage.index >= MeadowTreeStage.buddy.index || evolveBurst > 0.01) {
      _drawHalo(canvas, w, h, glowPower, evolveBurst);
    }

    if (stage.index >= MeadowTreeStage.garden.index || visualState.isLegendary) {
      _drawLightWisps(canvas, w, h, glowPower);
    }

    if (showMagic) {
      _drawFireflies(canvas, w, h, glowPower, evolveBurst);
    }

    if (evolveBurst > 0.01) {
      _drawEvolveRings(canvas, w, h, evolveBurst);
    }
  }

  void _drawBreathingShadow(Canvas canvas, double w, double h) {
    final breath = 0.85 + math.sin(time * math.pi * 2).abs() * 0.15;
    final sleepyDrop = visualState.isExhausted ? 1.20 : 1.0;
    final rect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.835),
      width: w * (0.46 + breath * 0.04) * sleepyDrop,
      height: h * (0.045 + breath * 0.012),
    );

    canvas.drawOval(
      rect,
      Paint()..color = const Color(0xFF2B5F55).withOpacity(0.10 + breath * 0.055),
    );
  }

  void _drawHalo(Canvas canvas, double w, double h, double glowPower, double evolveBurst) {
    final pulse = 0.5 + math.sin(auraTime * math.pi * 2).abs() * 0.5;
    final center = Offset(w * 0.50, h * 0.49);
    final radius = w * (0.26 + glowPower * 0.17 + evolveBurst * 0.12 + pulse * 0.025);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF4A8).withOpacity(0.08 + glowPower * 0.13 + evolveBurst * 0.18),
            const Color(0xFFCFFFE4).withOpacity(0.04 + glowPower * 0.08),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _drawLightWisps(Canvas canvas, double w, double h, double glowPower) {
    final paint = Paint()
      ..color = const Color(0xFFFFF4A8).withOpacity(0.10 + glowPower * 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final phase = (auraTime + i * 0.29) % 1.0;
      final y = h * (0.70 - phase * 0.44);
      final x = w * (0.38 + i * 0.12 + math.sin(phase * math.pi * 2) * 0.04);
      final path = Path()
        ..moveTo(x - w * 0.040, y + h * 0.035)
        ..cubicTo(
          x - w * 0.075,
          y,
          x + w * 0.060,
          y - h * 0.020,
          x + w * 0.015,
          y - h * 0.060,
        );

      canvas.drawPath(path, paint..color = paint.color.withOpacity((1 - phase) * 0.13 + 0.035));
    }
  }

  void _drawFireflies(Canvas canvas, double w, double h, double glowPower, double evolveBurst) {
    final count = switch (stage) {
      MeadowTreeStage.seed => 4,
      MeadowTreeStage.sprout => 5,
      MeadowTreeStage.buddy => 7,
      MeadowTreeStage.garden => 10,
      MeadowTreeStage.festival => 14,
    };

    for (int i = 0; i < count; i++) {
      final phase = (auraTime * (0.45 + i * 0.025) + i * 0.173) % 1.0;
      final orbit = phase * math.pi * 2;
      final rx = w * (0.20 + (i % 4) * 0.035);
      final ry = h * (0.15 + (i % 3) * 0.025);
      final center = Offset(w * 0.50, h * (0.48 + math.sin(i) * 0.025));
      final p = Offset(
        center.dx + math.cos(orbit) * rx,
        center.dy + math.sin(orbit * 1.35) * ry,
      );
      final twinkle = 0.35 + math.sin((phase + i * 0.19) * math.pi * 2).abs() * 0.65;
      final r = 1.3 + twinkle * 1.7 + evolveBurst * 2.2;

      canvas.drawCircle(
        p,
        r * 2.2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF7B1).withOpacity((0.18 + glowPower * 0.18) * twinkle),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: p, radius: r * 2.3)),
      );
      canvas.drawCircle(
        p,
        r,
        Paint()..color = const Color(0xFFFFF7B1).withOpacity(0.32 + twinkle * 0.38),
      );
    }
  }

  void _drawEvolveRings(Canvas canvas, double w, double h, double evolveBurst) {
    final progress = 1.0 - evolveBurst;
    final center = Offset(w * 0.50, h * 0.62);
    final paint = Paint()
      ..color = const Color(0xFFFFE58A).withOpacity(evolveBurst * 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 2; i++) {
      final r = w * (0.14 + progress * 0.25 + i * 0.055);
      canvas.drawCircle(center, r, paint..strokeWidth = 1.8 - i * 0.35);
    }
  }

  @override
  bool shouldRepaint(covariant _MeadowTreeBackFxPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.auraTime != auraTime ||
        oldDelegate.level != level ||
        oldDelegate.stage != stage ||
        oldDelegate.visualState != visualState ||
        oldDelegate.showMagic != showMagic ||
        oldDelegate.evolveProgress != evolveProgress;
  }
}

class _MeadowTreeFrontFxPainter extends CustomPainter {
  final double time;
  final double auraTime;
  final int level;
  final MeadowTreeStage stage;
  final CactusVisualState visualState;
  final bool showMagic;
  final bool showButterflies;
  final double evolveProgress;

  const _MeadowTreeFrontFxPainter({
    required this.time,
    required this.auraTime,
    required this.level,
    required this.stage,
    required this.visualState,
    required this.showMagic,
    required this.showButterflies,
    required this.evolveProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final glowPower = visualState.glowPower.clamp(0.0, 1.0).toDouble();
    final evolveBurst = (1.0 - evolveProgress).clamp(0.0, 1.0).toDouble();

    if (showMagic) {
      _drawSparkles(canvas, w, h, glowPower, evolveBurst);
      _drawFloatingLeaves(canvas, w, h);
    }

    if (stage.index >= MeadowTreeStage.garden.index || visualState.completedToday || visualState.isLegendary) {
      _drawPetals(canvas, w, h);
    }

    if (visualState.completedToday || visualState.isLegendary) {
      _drawHeartBubbles(canvas, w, h);
    }

    if (visualState.waterDropPower > 0.12) {
      _drawWaterDrops(canvas, w, h);
    }

    if (visualState.isSleepy) {
      _drawZzz(canvas, w, h);
    }

    if (visualState.isVeryStressed) {
      _drawStressMarks(canvas, w, h);
    }

    if (showButterflies) {
      _drawButterflies(canvas, w, h);
    }
  }

  void _drawSparkles(Canvas canvas, double w, double h, double glowPower, double evolveBurst) {
    final stageLift = switch (stage) {
      MeadowTreeStage.seed => 0.13,
      MeadowTreeStage.sprout => 0.08,
      MeadowTreeStage.buddy => 0.04,
      MeadowTreeStage.garden => 0.00,
      MeadowTreeStage.festival => -0.03,
    };

    const points = [
      Offset(0.22, 0.43),
      Offset(0.78, 0.36),
      Offset(0.58, 0.22),
      Offset(0.34, 0.28),
      Offset(0.68, 0.62),
      Offset(0.29, 0.66),
      Offset(0.50, 0.18),
      Offset(0.82, 0.54),
    ];

    for (int i = 0; i < points.length; i++) {
      final phase = (auraTime + i * 0.137) % 1.0;
      final blink = 0.50 + math.sin(phase * math.pi * 2).abs() * 0.50;
      final p = Offset(
        w * points[i].dx,
        h * (points[i].dy + stageLift + math.sin(phase * math.pi * 2) * 0.008),
      );
      final r = (2.6 + (i.isEven ? 1.5 : 0.7) + evolveBurst * 3.0) * blink;
      final paint = Paint()
        ..color = const Color(0xFFFFF4A8).withOpacity(
          (0.28 + glowPower * 0.28 + evolveBurst * 0.34) * blink,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(p.dx - r, p.dy), Offset(p.dx + r, p.dy), paint);
      canvas.drawLine(Offset(p.dx, p.dy - r), Offset(p.dx, p.dy + r), paint);
    }
  }

  void _drawFloatingLeaves(Canvas canvas, double w, double h) {
    final leafPaint = Paint()..color = const Color(0xFF8EE6A9).withOpacity(0.56);
    final stroke = Paint()
      ..color = const Color(0xFF4E9D7B).withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    final count = stage.index >= MeadowTreeStage.garden.index ? 5 : 3;
    for (int i = 0; i < count; i++) {
      final phase = (auraTime * (0.35 + i * 0.03) + i * 0.21) % 1.0;
      final p = Offset(
        w * (0.18 + i * 0.15 + math.sin(phase * math.pi * 2) * 0.025),
        h * (0.76 - phase * 0.38 + math.cos(phase * math.pi * 2) * 0.012),
      );
      final angle = phase * math.pi * 2 + i;
      _drawLeaf(canvas, p, w * (0.020 + i % 2 * 0.004), angle, leafPaint, stroke);
    }
  }

  void _drawPetals(Canvas canvas, double w, double h) {
    final count = stage == MeadowTreeStage.festival ? 12 : 7;
    final petalPaint = Paint()..color = const Color(0xFFFFB9D2).withOpacity(0.50);
    final petalPaint2 = Paint()..color = const Color(0xFFFFE6A1).withOpacity(0.38);

    for (int i = 0; i < count; i++) {
      final phase = (auraTime * (0.48 + i * 0.015) + i * 0.092) % 1.0;
      final sway = math.sin(phase * math.pi * 2 + i) * w * 0.035;
      final p = Offset(
        w * (0.16 + (i * 0.067) % 0.70) + sway,
        h * (0.12 + phase * 0.68),
      );
      final paint = i.isEven ? petalPaint : petalPaint2;
      _drawPetal(canvas, p, 0.72 + (i % 3) * 0.12, phase * math.pi * 2, paint);
    }
  }

  void _drawHeartBubbles(Canvas canvas, double w, double h) {
    final paint = Paint()..color = const Color(0xFFFF8DB8).withOpacity(0.34);

    for (int i = 0; i < 5; i++) {
      final phase = (auraTime * 0.55 + i * 0.18) % 1.0;
      final p = Offset(
        w * (0.30 + i * 0.10 + math.sin(phase * math.pi * 2) * 0.018),
        h * (0.72 - phase * 0.44),
      );
      _drawHeart(canvas, p, 4.5 + i % 2 * 1.4, paint..color = paint.color.withOpacity((1 - phase) * 0.30 + 0.04));
    }
  }

  void _drawWaterDrops(Canvas canvas, double w, double h) {
    final power = visualState.waterDropPower.clamp(0.0, 1.0).toDouble();
    final paint = Paint()..color = const Color(0xFF79DDF2).withOpacity(0.30 + power * 0.42);
    final stroke = Paint()
      ..color = const Color(0xFF4EAEC2).withOpacity(0.26 + power * 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final drift = math.sin(time * math.pi * 2) * 2.0;
    final points = [
      Offset(w * 0.32, h * 0.48 + drift),
      Offset(w * 0.70, h * 0.43 - drift * 0.6),
      Offset(w * 0.55, h * 0.63 + drift * 0.35),
    ];

    for (final p in points) {
      final path = Path()
        ..moveTo(p.dx, p.dy - 5)
        ..quadraticBezierTo(p.dx + 5, p.dy + 2, p.dx, p.dy + 7)
        ..quadraticBezierTo(p.dx - 5, p.dy + 2, p.dx, p.dy - 5)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawPath(path, stroke);
    }
  }

  void _drawZzz(Canvas canvas, double w, double h) {
    final painter = TextPainter(textDirection: TextDirection.ltr);
    final opacity = 0.42 + math.sin(time * math.pi * 2).abs() * 0.30;
    final style = TextStyle(
      color: const Color(0xFF8B83D8).withOpacity(opacity),
      fontSize: w * 0.040,
      fontWeight: FontWeight.w800,
    );

    final zeds = [
      _TextParticle('Z', 0.650, 0.320, 1.00),
      _TextParticle('z', 0.705, 0.292, 0.82),
      _TextParticle('z', 0.750, 0.268, 0.66),
    ];

    for (final z in zeds) {
      painter.text = TextSpan(
        text: z.text,
        style: style.copyWith(fontSize: w * 0.038 * z.scale),
      );
      painter.layout();
      painter.paint(canvas, Offset(w * z.x, h * z.y));
    }
  }

  void _drawStressMarks(Canvas canvas, double w, double h) {
    final jitter = math.sin(time * math.pi * 36) * 1.2;
    final paint = Paint()
      ..color = const Color(0xFFFF8A8A).withOpacity(0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.275 + jitter, h * 0.580), Offset(w * 0.235 + jitter, h * 0.548), paint);
    canvas.drawLine(Offset(w * 0.268 - jitter, h * 0.622), Offset(w * 0.232 - jitter, h * 0.654), paint);
    canvas.drawLine(Offset(w * 0.735 + jitter, h * 0.500), Offset(w * 0.775 + jitter, h * 0.468), paint);
  }

  void _drawButterflies(Canvas canvas, double w, double h) {
    final power = visualState.butterflyPower.clamp(0.0, 1.0).toDouble();
    final festivalBoost = stage == MeadowTreeStage.festival ? 1.0 : 0.0;
    final count = stage == MeadowTreeStage.festival
        ? 4
        : stage.index >= MeadowTreeStage.garden.index
            ? 3
            : 2;

    for (int i = 0; i < count; i++) {
      final phase = (auraTime * (0.52 + i * 0.06) + i * 0.23) % 1.0;
      final orbit = phase * math.pi * 2;
      final center = Offset(w * 0.50, h * (0.47 + i * 0.025));
      final rx = w * (0.22 + i * 0.030 + festivalBoost * 0.035);
      final ry = h * (0.13 + (i % 2) * 0.035);
      final p = Offset(
        center.dx + math.cos(orbit + i) * rx,
        center.dy + math.sin(orbit * 1.10 + i * 0.7) * ry,
      );
      final flap = math.sin((auraTime * 10 + i * 0.21) * math.pi * 2).abs();
      final angle = math.atan2(
        math.cos(orbit * 1.10 + i * 0.7) * ry,
        -math.sin(orbit + i) * rx,
      );

      _drawButterfly(
        canvas,
        p,
        scale: 0.62 + power * 0.18 + i * 0.035,
        angle: angle,
        flap: flap,
        blue: i.isOdd,
      );
    }
  }

  void _drawButterfly(
    Canvas canvas,
    Offset center, {
    required double scale,
    required double angle,
    required double flap,
    required bool blue,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final wingColor = blue ? const Color(0xFF9EDBFF) : const Color(0xFFFFC0D8);
    final wingInnerColor = blue ? const Color(0xFFD5FFF8) : const Color(0xFFFFF0A3);
    final wingPaint = Paint()..color = wingColor.withOpacity(0.82);
    final wingInner = Paint()..color = wingInnerColor.withOpacity(0.66);
    final bodyPaint = Paint()
      ..color = const Color(0xFF526B73).withOpacity(0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale
      ..strokeCap = StrokeCap.round;

    final wingHeight = (10.0 + flap * 3.2) * scale;
    final wingWidth = (7.6 + flap * 1.4) * scale;
    final left = Rect.fromCenter(
      center: Offset(-4.3 * scale, -1.1 * scale),
      width: wingWidth,
      height: wingHeight,
    );
    final right = Rect.fromCenter(
      center: Offset(4.3 * scale, -1.1 * scale),
      width: wingWidth,
      height: wingHeight,
    );

    canvas.drawOval(left, wingPaint);
    canvas.drawOval(right, wingPaint);
    canvas.drawOval(left.deflate(2.2 * scale), wingInner);
    canvas.drawOval(right.deflate(2.2 * scale), wingInner);
    canvas.drawLine(Offset(0, -5 * scale), Offset(0, 5 * scale), bodyPaint);

    canvas.restore();
  }

  void _drawLeaf(Canvas canvas, Offset center, double size, double angle, Paint fill, Paint stroke) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(-size, 0)
      ..quadraticBezierTo(0, -size * 1.25, size, 0)
      ..quadraticBezierTo(0, size * 1.25, -size, 0)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.restore();
  }

  void _drawPetal(Canvas canvas, Offset center, double scale, double angle, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 7.0 * scale, height: 12.0 * scale),
      paint,
    );
    canvas.restore();
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.45);
    path.cubicTo(
      center.dx - size * 1.20,
      center.dy - size * 0.25,
      center.dx - size * 0.62,
      center.dy - size * 1.10,
      center.dx,
      center.dy - size * 0.45,
    );
    path.cubicTo(
      center.dx + size * 0.62,
      center.dy - size * 1.10,
      center.dx + size * 1.20,
      center.dy - size * 0.25,
      center.dx,
      center.dy + size * 0.45,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MeadowTreeFrontFxPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.auraTime != auraTime ||
        oldDelegate.level != level ||
        oldDelegate.stage != stage ||
        oldDelegate.visualState != visualState ||
        oldDelegate.showMagic != showMagic ||
        oldDelegate.showButterflies != showButterflies ||
        oldDelegate.evolveProgress != evolveProgress;
  }
}

class _TextParticle {
  final String text;
  final double x;
  final double y;
  final double scale;

  const _TextParticle(this.text, this.x, this.y, this.scale);
}
