import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Real-time sky background for the Together screen.
///
/// Bản sửa: chỉ giữ bầu trời theo thời gian thật.
/// Đã xóa phần vẽ đồi núi, mặt đất, hàng rào và đường gỗ.
///
/// It uses the device's local time (`DateTime.now()`) and refreshes every
/// minute, so the sky changes automatically between:
/// dawn -> day -> sunset -> night.
///
/// Usage:
/// ```dart
/// Positioned.fill(
///   child: RealTimeSkyBackground(),
/// )
/// ```
///
/// For quick UI testing:
/// ```dart
/// RealTimeSkyBackground(debugTime: DateTime(2026, 1, 1, 19, 30))
/// ```
class RealTimeSkyBackground extends StatefulWidget {
  final bool animate;
  final DateTime? debugTime;
  final bool showDebugClock;

  const RealTimeSkyBackground({
    super.key,
    this.animate = true,
    this.debugTime,
    this.showDebugClock = false,
  });

  @override
  State<RealTimeSkyBackground> createState() => _RealTimeSkyBackgroundState();
}

class _RealTimeSkyBackgroundState extends State<RealTimeSkyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();

    _now = widget.debugTime ?? DateTime.now();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );

    if (widget.animate) {
      _animationController.repeat();
    }

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = widget.debugTime ?? DateTime.now();
      });
    });
  }

  @override
  void didUpdateWidget(covariant RealTimeSkyBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }

    if (oldWidget.debugTime != widget.debugTime) {
      setState(() {
        _now = widget.debugTime ?? DateTime.now();
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = widget.debugTime ?? _now;

    return RepaintBoundary(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) {
              return CustomPaint(
                painter: RealTimeSkyPainter(
                  time: time,
                  progress: _animationController.value,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
          if (widget.showDebugClock)
            Positioned(
              left: 16,
              bottom: 52,
              child: _SkyClockChip(time: time),
            ),
        ],
      ),
    );
  }
}

class _SkyClockChip extends StatelessWidget {
  final DateTime time;

  const _SkyClockChip({
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        '$hour:$minute',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class RealTimeSkyPainter extends CustomPainter {
  final DateTime time;
  final double progress;

  const RealTimeSkyPainter({
    required this.time,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final phase = _SkyPhaseResolver.fromTime(time);

    _drawSky(canvas, w, h, phase);
    _drawAtmosphere(canvas, w, h, phase);
    _drawSunOrMoon(canvas, w, h, phase);
    _drawStars(canvas, w, h, phase);
    _drawMovingClouds(canvas, w, h, phase);
    _drawBirds(canvas, w, h, phase);

    // Không vẽ cảnh phía dưới nữa:
    // _drawHills(canvas, w, h, phase);
    // _drawGroundDetails(canvas, w, h, phase);
    // _drawFence(canvas, w, h, phase);
    // _drawWoodFloor(canvas, w, h, phase);

    _drawVignette(canvas, w, h, phase);
  }

  void _drawSky(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: phase.skyColors,
        stops: phase.skyStops,
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  void _drawAtmosphere(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    final lightCenter = Offset(w * 0.76, h * phase.lightY);
    final radius = w * phase.lightRadius;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          phase.lightColor.withOpacity(phase.lightOpacity),
          phase.lightColor.withOpacity(phase.lightOpacity * 0.32),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromCircle(center: lightCenter, radius: radius));

    canvas.drawCircle(lightCenter, radius, glowPaint);

    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = Colors.white.withOpacity(phase.ribbonOpacity);

    final waveShift = math.sin(progress * math.pi * 2) * 7;

    final path1 = Path()
      ..moveTo(-w * 0.10, h * 0.34)
      ..cubicTo(
        w * 0.18,
        h * 0.46 + waveShift,
        w * 0.35,
        h * 0.35,
        w * 0.52,
        h * 0.48,
      );
    canvas.drawPath(path1, ribbonPaint);

    final path2 = Path()
      ..moveTo(w * 0.60, h * 0.62)
      ..cubicTo(
        w * 0.72,
        h * 0.51,
        w * 0.91,
        h * 0.59 + waveShift * 0.4,
        w * 1.08,
        h * 0.48,
      );
    canvas.drawPath(path2, ribbonPaint..strokeWidth = 5);
  }

  void _drawSunOrMoon(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    if (phase.kind == _SkyKind.night) {
      _drawMoon(canvas, w, h, phase);
      return;
    }

    final pos = _sunPosition(w, h);
    final sunRadius = w * (phase.kind == _SkyKind.day ? 0.080 : 0.092);

    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          phase.sunColor.withOpacity(0.78),
          phase.sunColor.withOpacity(0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: pos, radius: sunRadius * 4.0));

    canvas.drawCircle(pos, sunRadius * 4.0, sunGlow);

    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.95),
          phase.sunColor.withOpacity(0.90),
          phase.sunEdgeColor.withOpacity(0.72),
        ],
      ).createShader(Rect.fromCircle(center: pos, radius: sunRadius));

    canvas.drawCircle(pos, sunRadius, sunPaint);

    canvas.drawCircle(
      Offset(pos.dx - sunRadius * 0.30, pos.dy - sunRadius * 0.34),
      sunRadius * 0.28,
      Paint()..color = Colors.white.withOpacity(0.32),
    );
  }

  void _drawMoon(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    final pos = _moonPosition(w, h);
    final moonRadius = w * 0.064;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFEAF6FF).withOpacity(0.28),
          const Color(0xFFEAF6FF).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: pos, radius: moonRadius * 4.5));

    canvas.drawCircle(pos, moonRadius * 4.5, glow);

    final moonPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFDDEEFF),
        ],
      ).createShader(Rect.fromCircle(center: pos, radius: moonRadius));

    canvas.drawCircle(pos, moonRadius, moonPaint);

    // Crescent cut.
    canvas.drawCircle(
      Offset(pos.dx + moonRadius * 0.36, pos.dy - moonRadius * 0.12),
      moonRadius * 0.94,
      Paint()..color = phase.skyColors.first.withOpacity(0.92),
    );

    final craterPaint = Paint()..color = const Color(0xFFBFD5E8).withOpacity(0.38);
    canvas.drawCircle(
      Offset(pos.dx - moonRadius * 0.18, pos.dy + moonRadius * 0.10),
      moonRadius * 0.10,
      craterPaint,
    );
    canvas.drawCircle(
      Offset(pos.dx - moonRadius * 0.32, pos.dy - moonRadius * 0.18),
      moonRadius * 0.07,
      craterPaint,
    );
  }

  void _drawStars(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    if (phase.starOpacity <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 34; i++) {
      final baseX = ((i * 73) % 1000) / 1000.0;
      final baseY = 0.09 + (((i * 41) % 520) / 1000.0);
      final twinkle =
          (math.sin(progress * math.pi * 2 + i * 0.73) + 1.0) / 2.0;

      final x = w * baseX;
      final y = h * baseY;
      final r = 0.8 + (i % 3) * 0.45 + twinkle * 0.35;

      paint.color = Colors.white.withOpacity(phase.starOpacity * (0.38 + twinkle * 0.58));
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawMovingClouds(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    final shiftA = math.sin(progress * math.pi * 2) * 11;
    final shiftB = math.sin((progress + 0.35) * math.pi * 2) * 17;

    _drawCloud(
      canvas,
      center: Offset(w * 0.16 + shiftA, h * 0.20),
      scale: 0.76,
      opacity: phase.cloudOpacity,
      phase: phase,
    );

    _drawCloud(
      canvas,
      center: Offset(w * 0.76 - shiftB, h * 0.28),
      scale: 0.52,
      opacity: phase.cloudOpacity * 0.78,
      phase: phase,
    );

    _drawCloud(
      canvas,
      center: Offset(w * 0.43 + shiftB * 0.35, h * 0.39),
      scale: 0.43,
      opacity: phase.cloudOpacity * 0.54,
      phase: phase,
    );
  }

  void _drawCloud(
    Canvas canvas, {
    required Offset center,
    required double scale,
    required double opacity,
    required _SkyPhaseData phase,
  }) {
    final shadowPaint = Paint()
      ..color = phase.cloudShadowColor.withOpacity(opacity * 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + 5 * scale, center.dy + 18 * scale),
          width: 118 * scale,
          height: 32 * scale,
        ),
        Radius.circular(22 * scale),
      ),
      shadowPaint,
    );

    final cloudPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          phase.cloudColor.withOpacity(opacity),
          phase.cloudColor.withOpacity(opacity * 0.68),
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
  }

  void _drawBirds(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    if (phase.kind == _SkyKind.night) return;

    final wing = math.sin(progress * math.pi * 2) * 1.5;
    _drawBird(canvas, Offset(w * 0.66, h * 0.18), 0.78, wing, phase);
    _drawBird(canvas, Offset(w * 0.76, h * 0.15), 0.58, -wing, phase);
    _drawBird(canvas, Offset(w * 0.25, h * 0.30), 0.52, wing * 0.7, phase);
  }

  void _drawBird(
    Canvas canvas,
    Offset center,
    double scale,
    double flap,
    _SkyPhaseData phase,
  ) {
    final birdPaint = Paint()
      ..color = Colors.white.withOpacity(phase.birdOpacity)
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

  void _drawHills(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    final far = Path()
      ..moveTo(0, h * 0.72)
      ..cubicTo(w * 0.18, h * 0.63, w * 0.35, h * 0.67, w * 0.52, h * 0.72)
      ..cubicTo(w * 0.70, h * 0.77, w * 0.86, h * 0.72, w, h * 0.64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      far,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: phase.farHillColors,
        ).createShader(Rect.fromLTWH(0, h * 0.60, w, h * 0.40)),
    );

    final mid = Path()
      ..moveTo(0, h * 0.82)
      ..cubicTo(w * 0.22, h * 0.73, w * 0.43, h * 0.77, w * 0.62, h * 0.82)
      ..cubicTo(w * 0.78, h * 0.86, w * 0.90, h * 0.80, w, h * 0.76)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      mid,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: phase.midHillColors,
        ).createShader(Rect.fromLTWH(0, h * 0.70, w, h * 0.30)),
    );

    final front = Path()
      ..moveTo(0, h * 0.91)
      ..cubicTo(w * 0.20, h * 0.82, w * 0.43, h * 0.80, w * 0.64, h * 0.85)
      ..cubicTo(w * 0.82, h * 0.89, w * 0.92, h * 0.86, w, h * 0.83)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: phase.frontHillColors,
        ).createShader(Rect.fromLTWH(0, h * 0.80, w, h * 0.22)),
    );
  }

  void _drawGroundDetails(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(phase.groundLineOpacity);

    for (int i = 0; i < 8; i++) {
      final dx = w * 0.66 + i * 18;
      final path = Path()
        ..moveTo(dx, h * 0.66)
        ..quadraticBezierTo(dx - 26, h * 0.76, dx + 78, h * 0.82);
      canvas.drawPath(path, curvePaint);
    }

    final grassPaint = Paint()
      ..color = phase.grassColor.withOpacity(phase.grassOpacity)
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
  }

  void _drawFence(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    final fenceY = h - 92;

    final backShadow = Paint()
      ..color = Colors.black.withOpacity(phase.fenceShadowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, fenceY + 30, w, 13),
        const Radius.circular(8),
      ),
      backShadow,
    );

    final fenceRect = Rect.fromLTWH(0, fenceY, w, 84);
    final fencePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: phase.fenceColors,
      ).createShader(fenceRect);

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
          ..color = Colors.white.withOpacity(phase.fenceHighlightOpacity)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawLine(
        Offset(x + 21, fenceY + 11),
        Offset(x + 21, fenceY + 72),
        Paint()
          ..color = Colors.black.withOpacity(phase.fenceSideShadowOpacity)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    _drawFenceRail(canvas, w, fenceY + 22, phase);
    _drawFenceRail(canvas, w, fenceY + 54, phase);
  }

  void _drawFenceRail(
    Canvas canvas,
    double w,
    double y,
    _SkyPhaseData phase,
  ) {
    final railRect = Rect.fromLTWH(0, y, w, 13);
    final railPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: phase.fenceColors,
      ).createShader(railRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(railRect, const Radius.circular(8)),
      railPaint,
    );

    canvas.drawLine(
      Offset(0, y + 2),
      Offset(w, y + 2),
      Paint()
        ..color = Colors.white.withOpacity(phase.fenceHighlightOpacity)
        ..strokeWidth = 1,
    );

    canvas.drawLine(
      Offset(0, y + 12),
      Offset(w, y + 12),
      Paint()
        ..color = Colors.black.withOpacity(phase.fenceSideShadowOpacity)
        ..strokeWidth = 1,
    );
  }

  void _drawWoodFloor(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    final floorTop = h - 42;
    final floorRect = Rect.fromLTWH(0, floorTop, w, 42);

    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: phase.woodColors,
      ).createShader(floorRect);

    canvas.drawRect(floorRect, floorPaint);

    final topShadow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(phase.floorTopShadowOpacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, floorTop, w, 12));
    canvas.drawRect(Rect.fromLTWH(0, floorTop, w, 12), topShadow);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = phase.woodLineColor.withOpacity(0.56);

    for (double y = floorTop + 5; y < h; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
    }

    final plankPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = phase.woodLineColor.withOpacity(0.30);

    for (double x = 28; x < w; x += 64) {
      canvas.drawLine(Offset(x, floorTop + 2), Offset(x, h), plankPaint);
    }
  }

  void _drawVignette(Canvas canvas, double w, double h, _SkyPhaseData phase) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.15),
        radius: 1.15,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(phase.vignetteOpacity),
        ],
        stops: const [0.68, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, vignette);
  }

  Offset _sunPosition(double w, double h) {
    final hour = time.hour + time.minute / 60.0;
    final t = ((hour - 5.0) / 13.5).clamp(0.0, 1.0).toDouble();

    return Offset(
      _lerp(w * 0.12, w * 0.86, t),
      _lerp(h * 0.54, h * 0.13, math.sin(t * math.pi)),
    );
  }

  Offset _moonPosition(double w, double h) {
    final hour = time.hour + time.minute / 60.0;
    final nightHour = hour >= 18.5 ? hour - 18.5 : hour + 5.5;
    final t = (nightHour / 11.0).clamp(0.0, 1.0).toDouble();

    return Offset(
      _lerp(w * 0.16, w * 0.84, t),
      _lerp(h * 0.26, h * 0.14, math.sin(t * math.pi)),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant RealTimeSkyPainter oldDelegate) {
    return oldDelegate.time.minute != time.minute ||
        oldDelegate.time.hour != time.hour ||
        oldDelegate.progress != progress;
  }
}

enum _SkyKind {
  dawn,
  day,
  sunset,
  night,
}

class _SkyPhaseResolver {
  static _SkyPhaseData fromTime(DateTime time) {
    final hour = time.hour + time.minute / 60.0;

    if (hour >= 5.0 && hour < 7.0) {
      return _SkyPhaseData.dawn();
    }

    if (hour >= 7.0 && hour < 16.5) {
      return _SkyPhaseData.day();
    }

    if (hour >= 16.5 && hour < 18.5) {
      return _SkyPhaseData.sunset();
    }

    return _SkyPhaseData.night();
  }
}

class _SkyPhaseData {
  final _SkyKind kind;
  final List<Color> skyColors;
  final List<double> skyStops;

  final Color lightColor;
  final double lightOpacity;
  final double lightRadius;
  final double lightY;
  final Color sunColor;
  final Color sunEdgeColor;

  final double ribbonOpacity;
  final double starOpacity;
  final double cloudOpacity;
  final Color cloudColor;
  final Color cloudShadowColor;
  final double birdOpacity;

  final List<Color> farHillColors;
  final List<Color> midHillColors;
  final List<Color> frontHillColors;
  final Color grassColor;
  final double grassOpacity;
  final double groundLineOpacity;

  final List<Color> fenceColors;
  final double fenceShadowOpacity;
  final double fenceHighlightOpacity;
  final double fenceSideShadowOpacity;

  final List<Color> woodColors;
  final Color woodLineColor;
  final double floorTopShadowOpacity;

  final double vignetteOpacity;

  const _SkyPhaseData({
    required this.kind,
    required this.skyColors,
    required this.skyStops,
    required this.lightColor,
    required this.lightOpacity,
    required this.lightRadius,
    required this.lightY,
    required this.sunColor,
    required this.sunEdgeColor,
    required this.ribbonOpacity,
    required this.starOpacity,
    required this.cloudOpacity,
    required this.cloudColor,
    required this.cloudShadowColor,
    required this.birdOpacity,
    required this.farHillColors,
    required this.midHillColors,
    required this.frontHillColors,
    required this.grassColor,
    required this.grassOpacity,
    required this.groundLineOpacity,
    required this.fenceColors,
    required this.fenceShadowOpacity,
    required this.fenceHighlightOpacity,
    required this.fenceSideShadowOpacity,
    required this.woodColors,
    required this.woodLineColor,
    required this.floorTopShadowOpacity,
    required this.vignetteOpacity,
  });

  factory _SkyPhaseData.dawn() {
    return _SkyPhaseData(
      kind: _SkyKind.dawn,
      skyColors: const [
        Color(0xFF114C75),
        Color(0xFF1E91A7),
        Color(0xFFFFB47A),
        Color(0xFFFFF1A3),
      ],
      skyStops: const [0.0, 0.42, 0.78, 1.0],
      lightColor: const Color(0xFFFFC98A),
      lightOpacity: 0.28,
      lightRadius: 0.40,
      lightY: 0.22,
      sunColor: const Color(0xFFFFF0A3),
      sunEdgeColor: const Color(0xFFFFA45B),
      ribbonOpacity: 0.13,
      starOpacity: 0.06,
      cloudOpacity: 0.26,
      cloudColor: Colors.white,
      cloudShadowColor: const Color(0xFF6B7896),
      birdOpacity: 0.46,
      farHillColors: const [Color(0xFFDDF7B2), Color(0xFFC8E978)],
      midHillColors: const [Color(0xFFC8ED78), Color(0xFFAED95C)],
      frontHillColors: const [Color(0xFF9FD75B), Color(0xFF7EBB48)],
      grassColor: const Color(0xFF5DAE43),
      grassOpacity: 0.28,
      groundLineOpacity: 0.12,
      fenceColors: const [Color(0xFFFFFFFF), Color(0xFFEAF8E6)],
      fenceShadowOpacity: 0.07,
      fenceHighlightOpacity: 0.26,
      fenceSideShadowOpacity: 0.04,
      woodColors: const [Color(0xFFFFE5AE), Color(0xFFFFC879)],
      woodLineColor: Color(0xFFE0A65B),
      floorTopShadowOpacity: 0.07,
      vignetteOpacity: 0.08,
    );
  }

  factory _SkyPhaseData.day() {
    return _SkyPhaseData(
      kind: _SkyKind.day,
      skyColors: const [
        Color(0xFF0495B8),
        Color(0xFF1FC6C6),
        Color(0xFF87F2D0),
        Color(0xFFE9FF9D),
      ],
      skyStops: const [0.0, 0.36, 0.70, 1.0],
      lightColor: Colors.white,
      lightOpacity: 0.30,
      lightRadius: 0.36,
      lightY: 0.16,
      sunColor: const Color(0xFFFFF8B8),
      sunEdgeColor: const Color(0xFFFFD86B),
      ribbonOpacity: 0.12,
      starOpacity: 0.0,
      cloudOpacity: 0.30,
      cloudColor: Colors.white,
      cloudShadowColor: const Color(0xFF1C7E91),
      birdOpacity: 0.54,
      farHillColors: const [Color(0xFFE7FFC2), Color(0xFFD1F88D)],
      midHillColors: const [Color(0xFFD8FB8E), Color(0xFFBCEA64)],
      frontHillColors: const [Color(0xFFC3F36E), Color(0xFFAEE65D)],
      grassColor: const Color(0xFF4FB846),
      grassOpacity: 0.32,
      groundLineOpacity: 0.17,
      fenceColors: const [Color(0xFFFFFFFF), Color(0xFFEDFCE9)],
      fenceShadowOpacity: 0.06,
      fenceHighlightOpacity: 0.34,
      fenceSideShadowOpacity: 0.035,
      woodColors: const [Color(0xFFFFE9BA), Color(0xFFFFDFA1), Color(0xFFFFCA7C)],
      woodLineColor: Color(0xFFE8B56E),
      floorTopShadowOpacity: 0.07,
      vignetteOpacity: 0.035,
    );
  }

  factory _SkyPhaseData.sunset() {
    return _SkyPhaseData(
      kind: _SkyKind.sunset,
      skyColors: const [
        Color(0xFF243060),
        Color(0xFF985B93),
        Color(0xFFFF8A5B),
        Color(0xFFFFD377),
      ],
      skyStops: const [0.0, 0.40, 0.74, 1.0],
      lightColor: const Color(0xFFFF9A5B),
      lightOpacity: 0.34,
      lightRadius: 0.44,
      lightY: 0.25,
      sunColor: const Color(0xFFFFD177),
      sunEdgeColor: const Color(0xFFFF6D4A),
      ribbonOpacity: 0.10,
      starOpacity: 0.03,
      cloudOpacity: 0.22,
      cloudColor: const Color(0xFFFFE4CC),
      cloudShadowColor: const Color(0xFF5E3E72),
      birdOpacity: 0.34,
      farHillColors: const [Color(0xFFBBD883), Color(0xFF8BAD58)],
      midHillColors: const [Color(0xFFA4C766), Color(0xFF77994C)],
      frontHillColors: const [Color(0xFF7EAC50), Color(0xFF5E8740)],
      grassColor: const Color(0xFF4F8C3F),
      grassOpacity: 0.24,
      groundLineOpacity: 0.10,
      fenceColors: const [Color(0xFFFFF7EA), Color(0xFFECD8C2)],
      fenceShadowOpacity: 0.10,
      fenceHighlightOpacity: 0.18,
      fenceSideShadowOpacity: 0.075,
      woodColors: const [Color(0xFFFFD49A), Color(0xFFD98A4B), Color(0xFFB5653B)],
      woodLineColor: Color(0xFFB4663A),
      floorTopShadowOpacity: 0.12,
      vignetteOpacity: 0.14,
    );
  }

  factory _SkyPhaseData.night() {
    return _SkyPhaseData(
      kind: _SkyKind.night,
      skyColors: const [
        Color(0xFF061729),
        Color(0xFF0E3445),
        Color(0xFF15515B),
        Color(0xFF2E6D55),
      ],
      skyStops: const [0.0, 0.42, 0.74, 1.0],
      lightColor: const Color(0xFFBFE8FF),
      lightOpacity: 0.13,
      lightRadius: 0.42,
      lightY: 0.18,
      sunColor: const Color(0xFFEAF6FF),
      sunEdgeColor: const Color(0xFFBFD5E8),
      ribbonOpacity: 0.045,
      starOpacity: 0.62,
      cloudOpacity: 0.13,
      cloudColor: const Color(0xFFB8CCD5),
      cloudShadowColor: const Color(0xFF071A2A),
      birdOpacity: 0.0,
      farHillColors: const [Color(0xFF496F59), Color(0xFF315541)],
      midHillColors: const [Color(0xFF3E7448), Color(0xFF284C38)],
      frontHillColors: const [Color(0xFF3F7C45), Color(0xFF255B37)],
      grassColor: const Color(0xFF57A44C),
      grassOpacity: 0.20,
      groundLineOpacity: 0.07,
      fenceColors: const [Color(0xFFBFD9C7), Color(0xFF91B39E)],
      fenceShadowOpacity: 0.18,
      fenceHighlightOpacity: 0.08,
      fenceSideShadowOpacity: 0.12,
      woodColors: const [Color(0xFF8B6A43), Color(0xFF62482C)],
      woodLineColor: Color(0xFFB88A56),
      floorTopShadowOpacity: 0.20,
      vignetteOpacity: 0.22,
    );
  }
}
