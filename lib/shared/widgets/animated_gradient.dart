import 'package:flutter/material.dart';
import 'package:health_tracker/shared/styles/animations.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFF4ECDC4),
      Color(0xFF2DBB7A),
      Color(0xFF1A8FE3),
    ],
    this.duration = const Duration(seconds: 6),
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final a = _controller.value;
        final c = widget.colors;
        final mid = c.length ~/ 2;
        final colors = [
          Color.lerp(c[0], c[mid], a)!,
          Color.lerp(c[mid], c.last, a)!,
        ];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
