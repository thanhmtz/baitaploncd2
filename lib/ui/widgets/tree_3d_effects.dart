import 'package:flutter/material.dart';

import 'tree_art_painters.dart';

/// File này chỉ chứa widget hiệu ứng / animation wrapper.
/// Các CustomPainter thật sự nằm trong tree_art_painters.dart.
///
/// Cách dùng:
/// ```dart
/// Positioned.fill(
///   child: Premium3DWorldBackground(
///     isDark: Theme.of(context).brightness == Brightness.dark,
///   ),
/// )
///
/// Tree3DStage(
///   sway: _swayAnimation.value,
///   floatY: _floatAnimation.value * 0.55,
///   pulse: _pulseAnimation.value,
///   tapScale: _tapAnimation.value,
///   sparkleProgress: _sparkleAnimation.value,
///   showSparkles: _showLevelUp,
///   child: TreePotArt(
///     level: provider.treeLevel,
///     stage: provider.currentStage,
///   ),
/// )
/// ```

class Premium3DWorldBackground extends StatefulWidget {
  final bool isDark;
  final bool animate;

  const Premium3DWorldBackground({
    super.key,
    this.isDark = false,
    this.animate = true,
  });

  @override
  State<Premium3DWorldBackground> createState() =>
      _Premium3DWorldBackgroundState();
}

class _Premium3DWorldBackgroundState extends State<Premium3DWorldBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Premium3DWorldBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: Premium3DWorldPainter(
              progress: _controller.value,
              isDark: widget.isDark,
            ),
          );
        },
      ),
    );
  }
}

class Tree3DStage extends StatelessWidget {
  final Widget child;
  final double sway;
  final double floatY;
  final double pulse;
  final double tapScale;
  final double sparkleProgress;
  final bool showSparkles;
  final double width;
  final double height;

  const Tree3DStage({
    super.key,
    required this.child,
    this.sway = 0,
    this.floatY = 0,
    this.pulse = 1,
    this.tapScale = 1,
    this.sparkleProgress = 0,
    this.showSparkles = false,
    this.width = 272,
    this.height = 306,
  });

  @override
  Widget build(BuildContext context) {
    final scale = pulse * tapScale;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 4,
            child: CustomPaint(
              size: Size(width * 0.74, 54),
              painter: Tree3DGroundShadowPainter(
                sway: sway,
                progress: sparkleProgress,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            child: CustomPaint(
              size: Size(width * 0.76, 76),
              painter: Tree3DGlowPainter(progress: sparkleProgress),
            ),
          ),
          Transform.translate(
            offset: Offset(0, floatY),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(sway * 1.15)
                ..rotateZ(sway * 0.28)
                ..scale(scale),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  child,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: Tree3DLightSweepPainter(
                          progress: sparkleProgress,
                          intensity: showSparkles ? 0.34 : 0.16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showSparkles)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: Tree3DSparkleBurstPainter(
                    progress: sparkleProgress,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
