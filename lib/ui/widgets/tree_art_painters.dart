import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:health_tracker/providers/tree_provider.dart';

/// File này chỉ chứa các hàm vẽ / CustomPainter.
/// Không chứa AnimationController, GestureDetector, Provider hoặc logic màn hình.
///
/// Cách dùng chính:
/// ```dart
/// TreePotArt(level: provider.treeLevel, stage: provider.currentStage)
/// const MiniPlantAvatarArt()
/// const MiniFlowerArt()
/// const LadybugArt()
/// CustomPaint(painter: Premium3DWorldPainter(progress: value, isDark: isDark))
/// ```

class TreePotArt extends StatelessWidget {
  final int level;
  final TreeStage stage;
  final double width;
  final double height;

  const TreePotArt({
    super.key,
    required this.level,
    required this.stage,
    this.width = 220,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    final scale = _scaleForLevel(stage, level);

    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: TreePotArtPainter(
            stage: stage,
            level: level,
          ),
        ),
      ),
    );
  }

  double _scaleForLevel(TreeStage stage, int level) {
    final p = _stageProgress(stage, level);

    switch (stage) {
      case TreeStage.seed:
        return _lerp(0.68, 0.78, p);
      case TreeStage.sprout:
        return _lerp(0.80, 0.93, p);
      case TreeStage.youngTree:
        return _lerp(0.96, 1.05, p);
      case TreeStage.growingTree:
        return _lerp(1.07, 1.15, p);
      case TreeStage.bigTree:
        return _lerp(1.17, 1.26, p);
    }
  }

  double _stageProgress(TreeStage stage, int level) {
    if (stage.maxLevel <= stage.minLevel) return 1.0;

    return ((level - stage.minLevel) / (stage.maxLevel - stage.minLevel))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

class TreePotArtPainter extends CustomPainter {
  final TreeStage stage;
  final int level;

  const TreePotArtPainter({
    required this.stage,
    required this.level,
  });

  double get stageProgress {
    if (stage.maxLevel <= stage.minLevel) return 1.0;

    return ((level - stage.minLevel) / (stage.maxLevel - stage.minLevel))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  bool get isEarlyStageLevel => stageProgress < 0.34;
  bool get isMiddleStageLevel => stageProgress >= 0.34 && stageProgress < 0.67;
  bool get isLateStageLevel => stageProgress >= 0.67;

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  bool get showLeftArm {
    if (stage == TreeStage.youngTree) return level >= 18;
    return stage == TreeStage.growingTree || stage == TreeStage.bigTree;
  }

  bool get showRightArm {
    if (stage == TreeStage.youngTree) return level >= 28;
    if (stage == TreeStage.growingTree) return level >= 42;
    return stage == TreeStage.bigTree;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawShadow(canvas, w, h);
    _drawPotBody(canvas, w, h);
    _drawPlant(canvas, w, h);
    _drawSoilAndFrontRim(canvas, w, h);
    _drawPotHighlights(canvas, w, h);
  }

  void _drawShadow(Canvas canvas, double w, double h) {
    final grassGlow = Paint()
      ..color = const Color(0xFF77EFA4).withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawOval(
      Rect.fromLTWH(w * 0.15, h * 0.86, w * 0.70, h * 0.12),
      grassGlow,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawOval(
      Rect.fromLTWH(w * 0.21, h * 0.88, w * 0.58, h * 0.10),
      shadowPaint,
    );
  }

  void _drawPotBody(Canvas canvas, double w, double h) {
    final potBodyRect = Rect.fromLTWH(
      w * 0.23,
      h * 0.68,
      w * 0.54,
      h * 0.30,
    );

    final potBodyPath = Path()
      ..moveTo(w * 0.23, h * 0.70)
      ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.77, h * 0.70)
      ..lineTo(w * 0.69, h * 0.96)
      ..quadraticBezierTo(w * 0.50, h * 1.00, w * 0.31, h * 0.96)
      ..close();

    final potPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFA23A),
          Color(0xFFFF8125),
          Color(0xFFE96019),
        ],
      ).createShader(potBodyRect);

    final potStroke = Paint()
      ..color = const Color(0xFFD85B1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    canvas.drawPath(potBodyPath, potPaint);
    canvas.drawPath(potBodyPath, potStroke);

    final curvePaint = Paint()
      ..color = const Color(0xFFCC5418).withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final curve = Path()
      ..moveTo(w * 0.31, h * 0.83)
      ..quadraticBezierTo(w * 0.50, h * 0.87, w * 0.69, h * 0.83);
    canvas.drawPath(curve, curvePaint);
  }

  void _drawPlant(Canvas canvas, double w, double h) {
    final bodyRect = _bodyRect(w, h);
    final cactusPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF66E889),
          Color(0xFF2ED36D),
          Color(0xFF19A957),
        ],
      ).createShader(bodyRect);

    final cactusStroke = Paint()
      ..color = const Color(0xFF118A47)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3;

    if (stage == TreeStage.seed) {
      _drawSeedStage(canvas, w, h, bodyRect, cactusPaint, cactusStroke);
      return;
    }

    // Sprout evolves inside the same stage:
    // Lv5-7: small cactus shoot.
    // Lv8-11: side leaves appear.
    // Lv12-14: taller body and tiny top bud.
    if (stage == TreeStage.sprout) {
      final p = stageProgress;

      if (level >= 8) {
        _drawLeaf(
          canvas,
          center: Offset(
            bodyRect.left + bodyRect.width * 0.18,
            bodyRect.top + bodyRect.height * 0.10,
          ),
          length: w * _lerp(0.095, 0.135, p),
          angle: -2.72,
          color: const Color(0xFF48DE73),
        );
      }

      if (level >= 10) {
        _drawLeaf(
          canvas,
          center: Offset(
            bodyRect.right - bodyRect.width * 0.16,
            bodyRect.top + bodyRect.height * 0.12,
          ),
          length: w * _lerp(0.085, 0.125, p),
          angle: -0.42,
          color: const Color(0xFF5BED88),
        );
      }
    }

    if (showLeftArm) {
      final leftArmTop = stage == TreeStage.youngTree ? 0.49 : 0.44;
      final leftArmHeight = stage == TreeStage.youngTree ? 0.18 : 0.22;

      _drawArm(
        canvas,
        rect: Rect.fromLTWH(
          w * 0.22,
          h * leftArmTop,
          w * 0.19,
          h * leftArmHeight,
        ),
        radius: w * 0.10,
        paint: cactusPaint,
        stroke: cactusStroke,
        isLeft: true,
      );
    }

    if (showRightArm) {
      final rightArmTop = stage == TreeStage.youngTree ? 0.47 : 0.39;
      final rightArmHeight = stage == TreeStage.youngTree ? 0.18 : 0.23;

      _drawArm(
        canvas,
        rect: Rect.fromLTWH(
          w * 0.60,
          h * rightArmTop,
          w * 0.20,
          h * rightArmHeight,
        ),
        radius: w * 0.11,
        paint: cactusPaint,
        stroke: cactusStroke,
        isLeft: false,
      );
    }

    final bodyPath = _softBodyPath(bodyRect);
    canvas.drawPath(bodyPath, cactusPaint);
    _drawCactusHighlight(canvas, w, h, bodyRect);
    _drawBodyLines(canvas, w, h, bodyRect);
    canvas.drawPath(bodyPath, cactusStroke);

    _drawSoftSpines(canvas, w, h, bodyRect);
    _drawFace(canvas, w, h, bodyRect);
    _drawStageDecorations(canvas, w, h, bodyRect);
  }

  void _drawSeedStage(
    Canvas canvas,
    double w,
    double h,
    Rect bodyRect,
    Paint cactusPaint,
    Paint cactusStroke,
  ) {
    // Seed evolves visibly from Lv1 to Lv4.
    if (level >= 2) {
      _drawLeaf(
        canvas,
        center: Offset(w * 0.50, h * 0.46),
        length: w * _lerp(0.09, 0.15, stageProgress),
        angle: -2.55,
        color: const Color(0xFF43D96F),
      );
    }

    if (level >= 3) {
      _drawLeaf(
        canvas,
        center: Offset(w * 0.50, h * 0.46),
        length: w * _lerp(0.08, 0.14, stageProgress),
        angle: -0.60,
        color: const Color(0xFF58E985),
      );
    }

    final seedBody = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(bodyRect.width * 0.50),
    );
    canvas.drawRRect(seedBody, cactusPaint);
    _drawCactusHighlight(canvas, w, h, bodyRect);
    canvas.drawRRect(seedBody, cactusStroke);
    _drawFace(canvas, w, h, bodyRect);

    if (level >= 4) {
      _drawBud(
        canvas,
        Offset(bodyRect.center.dx, bodyRect.top - h * 0.006),
        w * 0.018,
      );
    }
  }

  void _drawArm(
    Canvas canvas, {
    required Rect rect,
    required double radius,
    required Paint paint,
    required Paint stroke,
    required bool isLeft,
  }) {
    final arm = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(arm, paint);

    final innerLine = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final x = isLeft
        ? rect.left + rect.width * 0.60
        : rect.left + rect.width * 0.38;
    canvas.drawLine(
      Offset(x, rect.top + rect.height * 0.18),
      Offset(x, rect.bottom - rect.height * 0.18),
      innerLine,
    );
    canvas.drawRRect(arm, stroke);
  }

  Rect _bodyRect(double w, double h) {
    // The body changes within every stage, so the tree feels like it is
    // evolving level by level, not only when TreeStage changes.
    final p = stageProgress;

    late final double widthFactor;
    late final double heightFactor;
    late final double bottomFactor;

    switch (stage) {
      case TreeStage.seed:
        widthFactor = _lerp(0.145, 0.205, p);
        heightFactor = _lerp(0.150, 0.270, p);
        bottomFactor = 0.720;
        break;

      case TreeStage.sprout:
        widthFactor = _lerp(0.225, 0.305, p);
        heightFactor = _lerp(0.330, 0.500, p);
        bottomFactor = 0.758;
        break;

      case TreeStage.youngTree:
        widthFactor = _lerp(0.305, 0.345, p);
        heightFactor = _lerp(0.520, 0.610, p);
        bottomFactor = 0.765;
        break;

      case TreeStage.growingTree:
        widthFactor = _lerp(0.340, 0.370, p);
        heightFactor = _lerp(0.620, 0.700, p);
        bottomFactor = 0.770;
        break;

      case TreeStage.bigTree:
        widthFactor = _lerp(0.365, 0.395, p);
        heightFactor = _lerp(0.720, 0.790, p);
        bottomFactor = 0.775;
        break;
    }

    final bodyWidth = w * widthFactor;
    final bodyHeight = h * heightFactor;

    return Rect.fromLTWH(
      (w - bodyWidth) / 2,
      h * bottomFactor - bodyHeight,
      bodyWidth,
      bodyHeight,
    );
  }

  Path _softBodyPath(Rect rect) {
    final cx = rect.center.dx;
    final top = rect.top;
    final bottom = rect.bottom;
    final left = rect.left;
    final right = rect.right;
    final h = rect.height;

    return Path()
      ..moveTo(cx, top)
      ..cubicTo(
        right - rect.width * 0.08,
        top,
        right,
        top + h * 0.12,
        right,
        top + h * 0.28,
      )
      ..lineTo(right, bottom - h * 0.17)
      ..cubicTo(
        right,
        bottom + h * 0.02,
        left,
        bottom + h * 0.02,
        left,
        bottom - h * 0.17,
      )
      ..lineTo(left, top + h * 0.28)
      ..cubicTo(
        left,
        top + h * 0.12,
        left + rect.width * 0.08,
        top,
        cx,
        top,
      )
      ..close();
  }

  void _drawCactusHighlight(Canvas canvas, double w, double h, Rect bodyRect) {
    final highlightRect = Rect.fromLTWH(
      bodyRect.left + bodyRect.width * 0.14,
      bodyRect.top + bodyRect.height * 0.10,
      bodyRect.width * 0.21,
      bodyRect.height * 0.68,
    );

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.34),
          Colors.white.withOpacity(0.05),
        ],
      ).createShader(highlightRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        highlightRect,
        Radius.circular(w * 0.09),
      ),
      highlightPaint,
    );
  }

  void _drawBodyLines(Canvas canvas, double w, double h, Rect bodyRect) {
    final linePaint = Paint()
      ..color = const Color(0xFFA3F2B3).withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round;

    final xs = [
      bodyRect.left + bodyRect.width * 0.28,
      bodyRect.center.dx,
      bodyRect.left + bodyRect.width * 0.72,
    ];

    for (final x in xs) {
      final path = Path()
        ..moveTo(x, bodyRect.top + bodyRect.height * 0.10)
        ..cubicTo(
          x - 4,
          bodyRect.top + bodyRect.height * 0.34,
          x + 4,
          bodyRect.top + bodyRect.height * 0.66,
          x,
          bodyRect.bottom - bodyRect.height * 0.10,
        );
      canvas.drawPath(path, linePaint);
    }
  }

  void _drawSoftSpines(Canvas canvas, double w, double h, Rect bodyRect) {
    final dotPaint = Paint()
      ..color = const Color(0xFF0D7F41).withOpacity(0.55);
    final tinyLinePaint = Paint()
      ..color = const Color(0xFF0D7F41).withOpacity(0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[
      Offset(bodyRect.left + bodyRect.width * 0.32,
          bodyRect.top + bodyRect.height * 0.28),
      Offset(bodyRect.left + bodyRect.width * 0.60,
          bodyRect.top + bodyRect.height * 0.22),
      Offset(bodyRect.left + bodyRect.width * 0.72,
          bodyRect.top + bodyRect.height * 0.42),
      Offset(bodyRect.left + bodyRect.width * 0.38,
          bodyRect.top + bodyRect.height * 0.58),
      Offset(bodyRect.left + bodyRect.width * 0.64,
          bodyRect.top + bodyRect.height * 0.72),
    ];

    if (stage == TreeStage.bigTree) {
      points.addAll([
        Offset(bodyRect.left + bodyRect.width * 0.25,
            bodyRect.top + bodyRect.height * 0.75),
        Offset(bodyRect.left + bodyRect.width * 0.78,
            bodyRect.top + bodyRect.height * 0.62),
      ]);
    }

    for (final p in points) {
      canvas.drawCircle(p, 1.5, dotPaint);
      canvas.drawLine(
        Offset(p.dx - 2.2, p.dy - 1.8),
        Offset(p.dx + 2.2, p.dy - 1.8),
        tinyLinePaint,
      );
    }
  }

  void _drawFace(Canvas canvas, double w, double h, Rect bodyRect) {
    final faceY = bodyRect.top + bodyRect.height * 0.37;
    final eyeRadius =
        math.min(bodyRect.width * 0.17, stage == TreeStage.seed ? 7.0 : 12.0);

    _drawEye(
      canvas,
      center: Offset(bodyRect.left + bodyRect.width * 0.34, faceY),
      radius: eyeRadius,
    );

    _drawEye(
      canvas,
      center: Offset(bodyRect.left + bodyRect.width * 0.67, faceY),
      radius: eyeRadius * 1.08,
    );

    final cheekPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF8FB0).withOpacity(0.34),
          const Color(0xFFFF8FB0).withOpacity(0.03),
        ],
      ).createShader(
        Rect.fromLTWH(
          bodyRect.left,
          faceY,
          bodyRect.width,
          bodyRect.height * 0.30,
        ),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          bodyRect.left + bodyRect.width * 0.23,
          bodyRect.top + bodyRect.height * 0.52,
        ),
        width: bodyRect.width * 0.23,
        height: bodyRect.height * 0.07,
      ),
      cheekPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          bodyRect.left + bodyRect.width * 0.80,
          bodyRect.top + bodyRect.height * 0.53,
        ),
        width: bodyRect.width * 0.24,
        height: bodyRect.height * 0.08,
      ),
      cheekPaint,
    );

    final mouthPaint = Paint()
      ..color = const Color(0xFF0F703A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stage == TreeStage.seed ? 1.6 : 2.2
      ..strokeCap = StrokeCap.round;

    final mouthY = bodyRect.top + bodyRect.height * 0.56;
    final mouth = Path()
      ..moveTo(bodyRect.left + bodyRect.width * 0.42, mouthY)
      ..quadraticBezierTo(
        bodyRect.left + bodyRect.width * 0.51,
        mouthY + bodyRect.height * 0.10,
        bodyRect.left + bodyRect.width * 0.62,
        mouthY,
      );
    canvas.drawPath(mouth, mouthPaint);
  }

  void _drawEye(
    Canvas canvas, {
    required Offset center,
    required double radius,
  }) {
    final whitePaint = Paint()..color = Colors.white;
    final darkPaint = Paint()..color = const Color(0xFF173B35);
    final softShadow = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.95);

    canvas.drawCircle(
      Offset(center.dx, center.dy + 1),
      radius * 1.02,
      softShadow,
    );
    canvas.drawCircle(center, radius, whitePaint);
    canvas.drawCircle(center, radius * 0.63, darkPaint);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.27, center.dy - radius * 0.34),
      radius * 0.22,
      highlightPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.22, center.dy + radius * 0.20),
      radius * 0.08,
      Paint()..color = Colors.white.withOpacity(0.65),
    );
  }

  void _drawStageDecorations(Canvas canvas, double w, double h, Rect bodyRect) {
    switch (stage) {
      case TreeStage.seed:
        return;

      case TreeStage.sprout:
        if (level >= 12) {
          _drawBud(
            canvas,
            Offset(
              bodyRect.center.dx + bodyRect.width * 0.04,
              bodyRect.top + bodyRect.height * 0.02,
            ),
            w * 0.018,
          );
        }

        if (level >= 14) {
          _drawLeaf(
            canvas,
            center: Offset(
              bodyRect.center.dx,
              bodyRect.top + bodyRect.height * 0.16,
            ),
            length: w * 0.075,
            angle: -1.25,
            color: const Color(0xFF77F09A),
          );
        }
        return;

      case TreeStage.youngTree:
        if (level >= 18) {
          _drawBud(
            canvas,
            Offset(
              bodyRect.center.dx + bodyRect.width * 0.12,
              bodyRect.top + bodyRect.height * 0.06,
            ),
            w * 0.024,
          );
        }

        if (level >= 24) {
          _drawLeaf(
            canvas,
            center: Offset(
              bodyRect.right - bodyRect.width * 0.08,
              bodyRect.top + bodyRect.height * 0.25,
            ),
            length: w * 0.105,
            angle: -0.22,
            color: const Color(0xFF67E98B),
          );
        }

        if (level >= 30) {
          _drawFlower(
            canvas,
            Offset(bodyRect.center.dx, bodyRect.top - h * 0.004),
            scale: 0.46,
          );
        }
        return;

      case TreeStage.growingTree:
        if (level >= 38) {
          _drawBud(
            canvas,
            Offset(bodyRect.center.dx, bodyRect.top + bodyRect.height * 0.02),
            w * 0.025,
          );
        }

        if (level >= 45) {
          _drawFlower(
            canvas,
            Offset(bodyRect.center.dx, bodyRect.top - h * 0.006),
            scale: 0.70,
          );
        }

        if (level >= 55) {
          _drawBud(
            canvas,
            Offset(
              bodyRect.right + w * 0.02,
              bodyRect.top + bodyRect.height * 0.26,
            ),
            w * 0.024,
          );
        }

        if (level >= 63) {
          _drawFlower(
            canvas,
            Offset(
              bodyRect.left + bodyRect.width * 0.18,
              bodyRect.top + bodyRect.height * 0.22,
            ),
            scale: 0.42,
          );
        }
        return;

      case TreeStage.bigTree:
        _drawFlower(
          canvas,
          Offset(bodyRect.center.dx, bodyRect.top - h * 0.018),
          scale: _lerp(0.86, 1.08, stageProgress),
        );

        if (level >= 78) {
          _drawFlower(
            canvas,
            Offset(
              bodyRect.left + bodyRect.width * 0.18,
              bodyRect.top + bodyRect.height * 0.19,
            ),
            scale: 0.48,
          );
        }

        if (level >= 86) {
          _drawBud(
            canvas,
            Offset(
              bodyRect.right + w * 0.025,
              bodyRect.top + bodyRect.height * 0.30,
            ),
            w * 0.026,
          );
        }

        if (level >= 94) {
          _drawFlower(
            canvas,
            Offset(
              bodyRect.right - bodyRect.width * 0.08,
              bodyRect.top + bodyRect.height * 0.13,
            ),
            scale: 0.44,
          );
        }
        return;
    }
  }

  void _drawBud(Canvas canvas, Offset center, double radius) {
    final stemPaint = Paint()
      ..color = const Color(0xFF118A47)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy + radius * 2.0),
      Offset(center.dx, center.dy + radius * 0.4),
      stemPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2.2,
        height: radius * 2.8,
      ),
      Paint()..color = const Color(0xFFFF7AB5),
    );
    canvas.drawCircle(
      Offset(center.dx - radius * 0.28, center.dy - radius * 0.25),
      radius * 0.38,
      Paint()..color = Colors.white.withOpacity(0.45),
    );
  }

  void _drawFlower(Canvas canvas, Offset center, {double scale = 1.0}) {
    final petalPaint = Paint()..color = const Color(0xFFFF7AB5);
    final petalLight = Paint()..color = const Color(0xFFFFA2C7);
    final middlePaint = Paint()..color = const Color(0xFFFFF06A);
    final outlinePaint = Paint()
      ..color = const Color(0xFFE85A98).withOpacity(0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;

    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final petalCenter = Offset(
        center.dx + math.cos(angle) * 8.0 * scale,
        center.dy + math.sin(angle) * 8.0 * scale,
      );
      final rect = Rect.fromCenter(
        center: petalCenter,
        width: 12.0 * scale,
        height: 14.0 * scale,
      );
      canvas.drawOval(rect, i.isEven ? petalPaint : petalLight);
      canvas.drawOval(rect, outlinePaint);
    }

    canvas.drawCircle(center, 6.0 * scale, middlePaint);
    canvas.drawCircle(
      Offset(center.dx - 1.4 * scale, center.dy - 1.5 * scale),
      1.7 * scale,
      Paint()..color = Colors.white.withOpacity(0.55),
    );
  }

  void _drawLeaf(
    Canvas canvas, {
    required Offset center,
    required double length,
    required double angle,
    required Color color,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final leafPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(length * 0.30, -length * 0.34, length * 0.82,
          -length * 0.30, length, 0)
      ..cubicTo(length * 0.74, length * 0.34, length * 0.28,
          length * 0.28, 0, 0)
      ..close();

    final paint = Paint()..color = color;
    final stroke = Paint()
      ..color = const Color(0xFF15954E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final vein = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(leafPath, paint);
    canvas.drawPath(leafPath, stroke);
    canvas.drawLine(Offset(length * 0.10, 0), Offset(length * 0.78, 0), vein);
    canvas.restore();
  }

  void _drawSoilAndFrontRim(Canvas canvas, double w, double h) {
    // This method is intentionally called AFTER _drawPlant().
    // It draws the pot mouth over the lower cactus body, so the cactus
    // appears embedded inside the pot instead of floating outside it.

    final backRimRect = Rect.fromLTWH(
      w * 0.18,
      h * 0.635,
      w * 0.64,
      h * 0.120,
    );

    final rimStroke = Paint()
      ..color = const Color(0xFFD85B1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3;

    // Back/top rim of the pot.
    final backRimPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFB85A),
          Color(0xFFFF8A2A),
        ],
      ).createShader(backRimRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        backRimRect,
        const Radius.circular(10),
      ),
      backRimPaint,
    );

    // Inner soil: smaller and lower, so it looks like it is inside the pot.
    final soilRect = Rect.fromLTWH(
      w * 0.285,
      h * 0.660,
      w * 0.430,
      h * 0.060,
    );

    canvas.drawOval(
      soilRect,
      Paint()..color = const Color(0xFF7A3F1F),
    );

    canvas.drawOval(
      Rect.fromLTWH(
        soilRect.left + soilRect.width * 0.15,
        soilRect.top + soilRect.height * 0.18,
        soilRect.width * 0.42,
        soilRect.height * 0.34,
      ),
      Paint()..color = const Color(0xFFC97836).withOpacity(0.48),
    );

    // A dark inner shadow gives depth and hides the cactus base naturally.
    canvas.drawOval(
      Rect.fromLTWH(
        w * 0.300,
        h * 0.688,
        w * 0.400,
        h * 0.040,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Front thick lip. This is the key layer that covers the lower cactus.
    final frontLipRect = Rect.fromLTWH(
      w * 0.185,
      h * 0.685,
      w * 0.630,
      h * 0.090,
    );

    final frontLipPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFB04A),
          Color(0xFFFF8427),
          Color(0xFFE9641B),
        ],
      ).createShader(frontLipRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frontLipRect,
        const Radius.circular(10),
      ),
      frontLipPaint,
    );

    // Highlight on the front lip.
    canvas.drawLine(
      Offset(w * 0.255, h * 0.705),
      Offset(w * 0.735, h * 0.705),
      Paint()
        ..color = Colors.white.withOpacity(0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frontLipRect,
        const Radius.circular(10),
      ),
      rimStroke,
    );

    // Small visible soil strip above the front lip, centered around the cactus.
    canvas.drawOval(
      Rect.fromLTWH(w * 0.330, h * 0.675, w * 0.340, h * 0.032),
      Paint()..color = const Color(0xFF6F3519).withOpacity(0.82),
    );
  }

  void _drawPotHighlights(Canvas canvas, double w, double h) {
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.36, h * 0.75),
      Offset(w * 0.32, h * 0.92),
      shinePaint,
    );

    final fineShine = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.44, h * 0.76),
      Offset(w * 0.41, h * 0.89),
      fineShine,
    );
  }

  @override
  bool shouldRepaint(covariant TreePotArtPainter oldDelegate) {
    return oldDelegate.stage != stage || oldDelegate.level != level;
  }
}

class MiniPlantAvatarArt extends StatelessWidget {
  const MiniPlantAvatarArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 45,
      height: 45,
      child: CustomPaint(
        painter: MiniPlantAvatarPainter(),
      ),
    );
  }
}

class MiniPlantAvatarPainter extends CustomPainter {
  const MiniPlantAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w / 2,
      Paint()..color = const Color(0xFFB9F66F),
    );

    final bodyRect = Rect.fromLTWH(w * 0.32, h * 0.25, w * 0.36, h * 0.46);
    final plantPaint = Paint()..color = const Color(0xFF31C86C);
    final strokePaint = Paint()
      ..color = const Color(0xFF14924B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final body = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(w * 0.18),
    );

    canvas.drawRRect(body, plantPaint);
    canvas.drawRRect(body, strokePaint);

    canvas.drawCircle(
      Offset(w * 0.42, h * 0.42),
      2.1,
      Paint()..color = const Color(0xFF173B35),
    );

    canvas.drawCircle(
      Offset(w * 0.58, h * 0.42),
      2.5,
      Paint()..color = const Color(0xFF173B35),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.27, h * 0.66, w * 0.46, h * 0.14),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFF8A2A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniFlowerArt extends StatelessWidget {
  const MiniFlowerArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 27,
      height: 27,
      child: CustomPaint(
        painter: MiniFlowerPainter(),
      ),
    );
  }
}

class MiniFlowerPainter extends CustomPainter {
  const MiniFlowerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalPaint = Paint()..color = const Color(0xFF49D778);
    final middlePaint = Paint()..color = const Color(0xFFFF7AB5);

    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final dx = center.dx + math.cos(angle) * 6;
      final dy = center.dy + math.sin(angle) * 6;

      canvas.drawCircle(Offset(dx, dy), 5, petalPaint);
    }

    canvas.drawCircle(center, 4, middlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LadybugArt extends StatelessWidget {
  const LadybugArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 48,
      height: 34,
      child: CustomPaint(
        painter: LadybugPainter(),
      ),
    );
  }
}

class LadybugPainter extends CustomPainter {
  const LadybugPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()..color = const Color(0xFFFF5A7C);
    final black = Paint()..color = const Color(0xFF273238);

    canvas.drawOval(Rect.fromLTWH(4, 8, size.width - 8, size.height - 8), red);
    canvas.drawCircle(Offset(size.width * 0.28, 10), 7, black);
    canvas.drawCircle(Offset(size.width * 0.45, 19), 3.5, black);
    canvas.drawCircle(Offset(size.width * 0.70, 18), 3.5, black);
    canvas.drawCircle(Offset(size.width * 0.58, 27), 3, black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter nền 3D. Được đặt ở file vẽ vì đây là CustomPainter thuần.
/// Widget animation cho painter này nằm trong tree_3d_effects.dart.
class Premium3DWorldPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const Premium3DWorldPainter({
    required this.progress,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawSky(canvas, w, h);
    _drawSunAndLight(canvas, w, h);
    _drawFloatingParticles(canvas, w, h);
    _drawClouds(canvas, w, h);
    _drawBirds(canvas, w, h);
    _drawHills(canvas, w, h);
    _drawHillDetails(canvas, w, h);
    _drawFence3D(canvas, w, h);
    _drawWoodFloor3D(canvas, w, h);
    _drawVignette(canvas, w, h);
  }

  void _drawSky(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [
                Color(0xFF0C3147),
                Color(0xFF164C5A),
                Color(0xFF266B63),
                Color(0xFF547D55),
              ]
            : const [
                Color(0xFF0495B8),
                Color(0xFF1FC6C6),
                Color(0xFF87F2D0),
                Color(0xFFE9FF9D),
              ],
        stops: const [0.0, 0.36, 0.70, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  void _drawSunAndLight(Canvas canvas, double w, double h) {
    final sun = Offset(w * 0.82, h * 0.16);
    final radius = w * 0.36;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(isDark ? 0.10 : 0.38),
          const Color(0xFFFFF6A6).withOpacity(isDark ? 0.06 : 0.18),
          Colors.white.withOpacity(0.00),
        ],
        stops: const [0.0, 0.38, 1.0],
      ).createShader(Rect.fromCircle(center: sun, radius: radius));

    canvas.drawCircle(sun, radius, glowPaint);

    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF8B8).withOpacity(isDark ? 0.32 : 0.68),
          const Color(0xFFFFD86B).withOpacity(isDark ? 0.12 : 0.18),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: sun, radius: w * 0.11));

    canvas.drawCircle(sun, w * 0.11, sunPaint);

    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8
      ..color = Colors.white.withOpacity(isDark ? 0.04 : 0.12);

    final ray1 = Path()
      ..moveTo(-w * 0.08, h * 0.30)
      ..cubicTo(w * 0.18, h * 0.42, w * 0.34, h * 0.35, w * 0.52, h * 0.45);
    canvas.drawPath(ray1, rayPaint);

    final ray2 = Path()
      ..moveTo(w * 0.62, h * 0.63)
      ..cubicTo(w * 0.74, h * 0.53, w * 0.90, h * 0.60, w * 1.10, h * 0.48);
    canvas.drawPath(ray2, rayPaint..strokeWidth = 5);
  }

  void _drawFloatingParticles(Canvas canvas, double w, double h) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final phase = (progress + i * 0.071) % 1.0;
      final x = (w * ((i * 0.137) % 1.0)) + math.sin(phase * math.pi * 2) * 8;
      final y = h * (0.16 + ((i * 0.083) % 0.50)) - phase * 22;
      final opacity = (math.sin(phase * math.pi) * 0.18).clamp(0.0, 0.18);
      final r = 1.2 + (i % 3) * 0.8;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawClouds(Canvas canvas, double w, double h) {
    final shiftSlow = math.sin(progress * math.pi * 2) * 10;
    final shiftFast = math.sin((progress + 0.35) * math.pi * 2) * 14;

    _drawCloud3D(
      canvas,
      center: Offset(w * 0.18 + shiftSlow, h * 0.20),
      scale: 0.78,
      opacity: isDark ? 0.13 : 0.30,
    );

    _drawCloud3D(
      canvas,
      center: Offset(w * 0.75 - shiftFast, h * 0.26),
      scale: 0.52,
      opacity: isDark ? 0.10 : 0.23,
    );

    _drawCloud3D(
      canvas,
      center: Offset(w * 0.45 + shiftFast * 0.4, h * 0.37),
      scale: 0.44,
      opacity: isDark ? 0.08 : 0.16,
    );
  }

  void _drawCloud3D(
    Canvas canvas, {
    required Offset center,
    required double scale,
    required double opacity,
  }) {
    final shadowPaint = Paint()
      ..color = const Color(0xFF1C7E91).withOpacity(opacity * 0.26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final baseRect = Rect.fromCenter(
      center: Offset(center.dx + 4 * scale, center.dy + 18 * scale),
      width: 118 * scale,
      height: 31 * scale,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, Radius.circular(22 * scale)),
      shadowPaint,
    );

    final cloudPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(opacity),
          Colors.white.withOpacity(opacity * 0.72),
        ],
      ).createShader(
        Rect.fromCenter(
          center: center,
          width: 130 * scale,
          height: 65 * scale,
        ),
      );

    canvas.drawCircle(
      Offset(center.dx - 38 * scale, center.dy + 8 * scale),
      25 * scale,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(center.dx - 12 * scale, center.dy - 4 * scale),
      34 * scale,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + 25 * scale, center.dy + 5 * scale),
      27 * scale,
      cloudPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 16 * scale),
          width: 116 * scale,
          height: 31 * scale,
        ),
        Radius.circular(20 * scale),
      ),
      cloudPaint,
    );

    final highlight = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(center.dx - 12 * scale, center.dy - 6 * scale),
        radius: 28 * scale,
      ),
      math.pi * 1.08,
      math.pi * 0.42,
      false,
      highlight,
    );
  }

  void _drawBirds(Canvas canvas, double w, double h) {
    final wing = math.sin(progress * math.pi * 2) * 1.5;
    _drawBird(canvas, Offset(w * 0.66, h * 0.18), 0.78, wing);
    _drawBird(canvas, Offset(w * 0.76, h * 0.15), 0.58, -wing);
    _drawBird(canvas, Offset(w * 0.25, h * 0.30), 0.52, wing * 0.7);
  }

  void _drawBird(Canvas canvas, Offset center, double scale, double flap) {
    final birdPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.32 : 0.54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * scale
      ..strokeCap = StrokeCap.round;

    final leftWing = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(
        center.dx - 8 * scale,
        center.dy - (7 + flap) * scale,
        center.dx - 15 * scale,
        center.dy,
      );

    final rightWing = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(
        center.dx + 8 * scale,
        center.dy - (7 - flap) * scale,
        center.dx + 15 * scale,
        center.dy,
      );

    canvas.drawPath(leftWing, birdPaint);
    canvas.drawPath(rightWing, birdPaint);
  }

  void _drawHills(Canvas canvas, double w, double h) {
    final far = Path()
      ..moveTo(0, h * 0.72)
      ..cubicTo(w * 0.18, h * 0.63, w * 0.35, h * 0.67, w * 0.52, h * 0.72)
      ..cubicTo(w * 0.70, h * 0.77, w * 0.86, h * 0.72, w, h * 0.64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final farPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF587D5F), Color(0xFF3C664B)]
            : const [Color(0xFFE7FFC2), Color(0xFFD1F88D)],
      ).createShader(Rect.fromLTWH(0, h * 0.60, w, h * 0.38));
    canvas.drawPath(far, farPaint);

    final mid = Path()
      ..moveTo(0, h * 0.82)
      ..cubicTo(w * 0.22, h * 0.73, w * 0.43, h * 0.77, w * 0.62, h * 0.82)
      ..cubicTo(w * 0.78, h * 0.86, w * 0.90, h * 0.80, w, h * 0.76)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final midPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF4B8052), Color(0xFF315B40)]
            : const [Color(0xFFD8FB8E), Color(0xFFBCEA64)],
      ).createShader(Rect.fromLTWH(0, h * 0.70, w, h * 0.30));
    canvas.drawPath(mid, midPaint);

    final front = Path()
      ..moveTo(0, h * 0.91)
      ..cubicTo(w * 0.20, h * 0.82, w * 0.43, h * 0.80, w * 0.64, h * 0.85)
      ..cubicTo(w * 0.82, h * 0.89, w * 0.92, h * 0.86, w, h * 0.83)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF4C8B4D), Color(0xFF2E6B3F)]
            : const [Color(0xFFC3F36E), Color(0xFFAEE65D)],
      ).createShader(Rect.fromLTWH(0, h * 0.80, w, h * 0.20));
    canvas.drawPath(front, frontPaint);

    final sunBehindHill = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.08 : 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(Offset(w * 0.16, h * 0.67), w * 0.16, sunBehindHill);
  }

  void _drawHillDetails(Canvas canvas, double w, double h) {
    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(isDark ? 0.07 : 0.17);

    for (int i = 0; i < 8; i++) {
      final dx = w * 0.66 + i * 18;
      final path = Path()
        ..moveTo(dx, h * 0.66)
        ..quadraticBezierTo(dx - 26, h * 0.76, dx + 78, h * 0.82);
      canvas.drawPath(path, curvePaint);
    }

    final grassPaint = Paint()
      ..color = const Color(0xFF4FB846).withOpacity(isDark ? 0.20 : 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 22; i++) {
      final x = (i * 27.0 + math.sin(progress * math.pi * 2 + i) * 2) % w;
      final baseY = h * (0.82 + (i % 5) * 0.017);

      canvas.drawLine(
        Offset(x, baseY),
        Offset(x + 4, baseY - 11 - (i % 4) * 2),
        grassPaint,
      );
    }

    _drawTinyFlower(canvas, Offset(w * 0.12, h * 0.80), 0.76);
    _drawTinyFlower(canvas, Offset(w * 0.86, h * 0.78), 0.66);
    _drawTinyFlower(canvas, Offset(w * 0.72, h * 0.87), 0.56);
  }

  void _drawTinyFlower(Canvas canvas, Offset center, double scale) {
    final petalPaint = Paint()
      ..color = const Color(0xFFFF7AB5).withOpacity(isDark ? 0.42 : 0.70);
    final middlePaint = Paint()
      ..color = const Color(0xFFFFF06A).withOpacity(isDark ? 0.50 : 0.90);

    for (int i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5;
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * 5 * scale,
          center.dy + math.sin(angle) * 5 * scale,
        ),
        3.2 * scale,
        petalPaint,
      );
    }

    canvas.drawCircle(center, 2.5 * scale, middlePaint);
  }

  void _drawFence3D(Canvas canvas, double w, double h) {
    final fenceY = h - 92;

    final backShadow = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.18 : 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, fenceY + 30, w, 13),
        const Radius.circular(8),
      ),
      backShadow,
    );

    final fenceShaderRect = Rect.fromLTWH(0, fenceY, w, 84);
    final fencePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withOpacity(0.55),
                const Color(0xFFB7D7C6).withOpacity(0.42),
              ]
            : [
                Colors.white.withOpacity(0.98),
                const Color(0xFFF4FFF0).withOpacity(0.95),
              ],
      ).createShader(fenceShaderRect);

    for (double x = -8; x < w + 28; x += 36) {
      final post = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, fenceY, 24, 78),
        const Radius.circular(12),
      );
      canvas.drawRRect(post, fencePaint);

      canvas.drawLine(
        Offset(x + 5, fenceY + 9),
        Offset(x + 5, fenceY + 68),
        Paint()
          ..color = Colors.white.withOpacity(isDark ? 0.08 : 0.34)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawLine(
        Offset(x + 21, fenceY + 11),
        Offset(x + 21, fenceY + 72),
        Paint()
          ..color = Colors.black.withOpacity(isDark ? 0.10 : 0.035)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    _drawFenceRail(canvas, w, fenceY + 22);
    _drawFenceRail(canvas, w, fenceY + 54);
  }

  void _drawFenceRail(Canvas canvas, double w, double y) {
    final railRect = Rect.fromLTWH(0, y, w, 13);
    final railPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                Colors.white.withOpacity(0.52),
                const Color(0xFFBBD8C6).withOpacity(0.38),
              ]
            : [
                Colors.white.withOpacity(1.0),
                const Color(0xFFEDFCE9).withOpacity(0.98),
              ],
      ).createShader(railRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(railRect, const Radius.circular(8)),
      railPaint,
    );

    canvas.drawLine(
      Offset(0, y + 2),
      Offset(w, y + 2),
      Paint()
        ..color = Colors.white.withOpacity(isDark ? 0.08 : 0.32)
        ..strokeWidth = 1.0,
    );

    canvas.drawLine(
      Offset(0, y + 12),
      Offset(w, y + 12),
      Paint()
        ..color = Colors.black.withOpacity(isDark ? 0.12 : 0.035)
        ..strokeWidth = 1.0,
    );
  }

  void _drawWoodFloor3D(Canvas canvas, double w, double h) {
    final floorTop = h - 42;
    final floorRect = Rect.fromLTWH(0, floorTop, w, 42);

    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF8B6A43), Color(0xFF62482C)]
            : const [Color(0xFFFFE9BA), Color(0xFFFFDFA1), Color(0xFFFFCA7C)],
      ).createShader(floorRect);

    canvas.drawRect(floorRect, floorPaint);

    final topShadow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(isDark ? 0.20 : 0.07),
          Colors.black.withOpacity(0.00),
        ],
      ).createShader(Rect.fromLTWH(0, floorTop, w, 12));
    canvas.drawRect(Rect.fromLTWH(0, floorTop, w, 12), topShadow);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = (isDark ? const Color(0xFFB88A56) : const Color(0xFFE8B56E))
          .withOpacity(0.56);

    for (double y = floorTop + 5; y < h; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
    }

    final plankPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = (isDark ? const Color(0xFFAC8051) : const Color(0xFFE9BD7A))
          .withOpacity(0.36);

    for (double x = 28; x < w; x += 64) {
      canvas.drawLine(Offset(x, floorTop + 2), Offset(x, h), plankPaint);
    }

    final shinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(isDark ? 0.05 : 0.22);

    canvas.drawLine(Offset(0, floorTop + 3), Offset(w, floorTop + 3), shinePaint);
  }

  void _drawVignette(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.15),
        radius: 1.15,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(isDark ? 0.18 : 0.035),
        ],
        stops: const [0.72, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant Premium3DWorldPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

/// Painter cho shadow/glow của cây. Widget sử dụng nằm trong tree_3d_effects.dart.
class Tree3DGroundShadowPainter extends CustomPainter {
  final double sway;
  final double progress;

  const Tree3DGroundShadowPainter({
    required this.sway,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;
    final center = Offset(size.width / 2 + sway * 48, size.height / 2);

    final soft = Paint()
      ..color = const Color(0xFF1F5F35).withOpacity(0.10 + pulse * 0.025)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * (0.84 + pulse * 0.05),
        height: size.height * 0.54,
      ),
      soft,
    );

    final core = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.68,
        height: size.height * 0.34,
      ),
      core,
    );
  }

  @override
  bool shouldRepaint(covariant Tree3DGroundShadowPainter oldDelegate) {
    return oldDelegate.sway != sway || oldDelegate.progress != progress;
  }
}

class Tree3DGlowPainter extends CustomPainter {
  final double progress;

  const Tree3DGlowPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFB9FFB8).withOpacity(0.30 + pulse * 0.10),
          const Color(0xFF67EFA2).withOpacity(0.13),
          Colors.white.withOpacity(0.00),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width,
          height: size.height,
        ),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * (0.88 + pulse * 0.08),
        height: size.height * (0.62 + pulse * 0.08),
      ),
      glowPaint,
    );

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.white.withOpacity(0.22);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.70,
        height: size.height * 0.42,
      ),
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant Tree3DGlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class Tree3DLightSweepPainter extends CustomPainter {
  final double progress;
  final double intensity;

  const Tree3DLightSweepPainter({
    required this.progress,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sweepX = -size.width + progress * size.width * 2.4;
    final path = Path()
      ..moveTo(sweepX, 0)
      ..lineTo(sweepX + size.width * 0.20, 0)
      ..lineTo(sweepX + size.width * 0.68, size.height)
      ..lineTo(sweepX + size.width * 0.48, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(intensity),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.softLight;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant Tree3DLightSweepPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity;
  }
}

class Tree3DSparkleBurstPainter extends CustomPainter {
  final double progress;

  const Tree3DSparkleBurstPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);

    for (int i = 0; i < 18; i++) {
      final local = (progress + i * 0.047) % 1.0;
      final angle = i * math.pi * 2 / 18;
      final distance = 18 + local * 92;
      final opacity = math.sin(local * math.pi).clamp(0.0, 1.0).toDouble();

      final p = Offset(
        center.dx + math.cos(angle) * distance * (0.92 + (i % 3) * 0.08),
        center.dy + math.sin(angle) * distance * 0.82,
      );

      _drawStar(
        canvas,
        p,
        radius: 2.2 + (i % 4) * 0.7,
        opacity: opacity,
        rotation: angle + progress * math.pi,
      );
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double opacity,
    required double rotation,
  }) {
    final linePaint = Paint()
      ..color = const Color(0xFFFFF5A8).withOpacity(opacity * 0.86)
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    canvas.drawLine(Offset(-radius * 2, 0), Offset(radius * 2, 0), linePaint);
    canvas.drawLine(Offset(0, -radius * 2), Offset(0, radius * 2), linePaint);

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..color = Colors.white.withOpacity(opacity * 0.55),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant Tree3DSparkleBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
