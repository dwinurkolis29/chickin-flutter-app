import 'package:flutter/material.dart';

class SlideFadeTransitionBuilder extends PageTransitionsBuilder {
  const SlideFadeTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0); // dari kanan
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}
