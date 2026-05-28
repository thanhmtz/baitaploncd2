import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x, y;
  double vx, vy;
  double size;
  double opacity;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.size = 3.0,
    this.opacity = 0.5,
    required this.color,
  });

  void update(double width, double height) {
    x += vx;
    y += vy;
    if (x < 0 || x > width) vx = -vx;
    if (y < 0 || y > height) vy = -vy;
  }
}

class ParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color particleColor;
  final double maxParticleSize;

  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 20,
    this.particleColor = Colors.white,
    this.maxParticleSize = 4.0,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particles = List.generate(
      widget.particleCount,
      (_) => Particle(
        x: _random.nextDouble() * 400,
        y: _random.nextDouble() * 800,
        vx: (_random.nextDouble() - 0.5) * 0.5,
        vy: (_random.nextDouble() - 0.5) * 0.5,
        size: 1.0 + _random.nextDouble() * widget.maxParticleSize,
        opacity: 0.1 + _random.nextDouble() * 0.4,
        color: widget.particleColor,
      ),
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
      animation: _controller,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            for (final p in _particles) {
              p.update(w, h);
            }
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                ..._particles.map(
                  (p) => Positioned(
                    left: p.x,
                    top: p.y,
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.color.withOpacity(p.opacity),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: widget.child,
    );
  }
}
