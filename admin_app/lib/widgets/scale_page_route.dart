import 'package:flutter/material.dart';

/// A page route where the new screen grows from the center,
/// like Flutter's ScaleTransition sample.
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  ScalePageRoute({required Widget page})
    : super(
        transitionDuration: const Duration(milliseconds: 1200),
        reverseTransitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          );
          return ScaleTransition(scale: curved, child: child);
        },
      );
}
