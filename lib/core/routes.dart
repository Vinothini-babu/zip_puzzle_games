import 'package:flutter/material.dart';

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => page,
  transitionDuration: const Duration(milliseconds: 350),
  transitionsBuilder: (_, anim, __, child) =>
      FadeTransition(opacity: anim, child: child),
);

/// Pushed (not replaced) on top of the current screen with a dimmed
/// backdrop and a scale-in "pop" animation — used for the Level Complete
/// celebration so it feels like a popup rather than a page navigation.
Route<T> popupRoute<T>(Widget page) => PageRouteBuilder<T>(
  opaque: false,
  barrierColor: Colors.black.withOpacity(0.55),
  transitionDuration: const Duration(milliseconds: 380),
  reverseTransitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => FadeTransition(
    opacity: anim,
    child: ScaleTransition(
      scale: Tween(begin: 0.86, end: 1.0)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
      child: child,
    ),
  ),
);