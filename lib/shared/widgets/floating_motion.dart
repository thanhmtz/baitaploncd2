import 'dart:math';
import 'package:flutter/material.dart';
import 'package:health_tracker/shared/styles/animations.dart';

class FloatingMotion extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final double frequency;
  final Duration delay;

  const FloatingMotion({
    super.key,
    required this.child,
    this.amplitude = 6.0,
    this.frequency = 1.0,
    this.delay = Duration.zero,
  });

  @override
  State<FloatingMotion> createState() => _FloatingMotionState();
}

class _FloatingMotionState extends State<FloatingMotion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: (3 / widget.frequency).round()),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
    });
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
        final offset = sin(_controller.value * 2 * pi) * widget.amplitude;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
