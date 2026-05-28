import 'package:flutter/material.dart';
import 'package:health_tracker/shared/styles/animations.dart';

class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.duration = AppDurations.fast,
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnim = Tween(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _controller, curve: AppEasing.smooth));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails d) {
    _pressed = true;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails d) {
    _pressed = false;
    _controller.reverse();
  }

  void _onTapCancel() {
    _pressed = false;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _scaleAnim.value,
        child: widget.child,
      ),
    );
  }
}
