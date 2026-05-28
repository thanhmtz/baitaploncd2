import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:health_tracker/shared/styles/animations.dart';

class GlassmorphicCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color tint;
  final double opacity;
  final EdgeInsetsGeometry? margin;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 10,
    this.tint = Colors.white,
    this.opacity = 0.15,
    this.margin,
  });

  @override
  State<GlassmorphicCard> createState() => _GlassmorphicCardState();
}

class _GlassmorphicCardState extends State<GlassmorphicCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _glowAnim = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppEasing.smooth),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.tint.withOpacity(0.1 * _glowAnim.value),
                blurRadius: 20 * _glowAnim.value,
                spreadRadius: 2 * _glowAnim.value,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: widget.blur,
                sigmaY: widget.blur,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.tint.withOpacity(widget.opacity),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: widget.tint.withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
