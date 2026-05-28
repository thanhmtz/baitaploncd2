import 'package:flutter/material.dart';

class AppEasing {
  static const smooth = Curves.fastOutSlowIn;
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
  static const soft = Cubic(0.25, 0.46, 0.45, 0.94);
  static const bounce = Cubic(0.68, -0.55, 0.27, 1.55);
  static const decelerate = Cubic(0.0, 0.0, 0.2, 1);
  static const emphasize = Cubic(0.2, 0.0, 0.0, 1);
  static const flutterDefault = Curves.fastOutSlowIn;
}

class AppDurations {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 500);
  static const pageTransition = Duration(milliseconds: 400);
}

class FadeSlideRoute extends PageRouteBuilder {
  final Widget page;

  FadeSlideRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.08);
            const end = Offset.zero;
            const curve = Curves.fastOutSlowIn;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
          transitionDuration: AppDurations.pageTransition,
        );
}

class HeroRoute extends PageRouteBuilder {
  final Widget page;

  HeroRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: AppDurations.slow,
        );
}
