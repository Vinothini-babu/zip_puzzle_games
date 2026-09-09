// app_colors.dart
// Centralized theme palette for ZIP_PUZZLE_GAME.
// Base: Teal | Accent: Gold/Amber (used for coins, highlights, rewards).
// Import this in every screen instead of hardcoding color values.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // no instances - just a constants holder

  // ---- Base (Teal) ----
  static const Color primary = Color(0xFF00796B);       // Colors.teal.shade700
  static const Color primaryLight = Color(0xFF48A999);  // Colors.teal.shade300-ish
  static const Color primaryDark = Color(0xFF004C40);   // Colors.teal.shade900

  // ---- Accent (Gold) ----
  static const Color accent = Color(0xFFFFB300);        // Colors.amber.shade700
  static const Color accentLight = Color(0xFFFFD54F);   // Colors.amber.shade300
  static const Color accentDark = Color(0xFFFF8F00);    // Colors.amber.shade800

  // ---- Status colors (grid validation) ----
  static const Color correct = primary;                 // correct checkpoint = teal
  static const Color incorrect = Color(0xFFD32F2F);      // wrong checkpoint = red

  // ---- Neutrals ----
  static const Color background = Color(0xFFF5F7F6);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1B1B1B);
  static const Color textMuted = Color(0xFF6E7A78);
  static const Color locked = Color(0xFFBDBDBD);

  // ---- Reusable gradients (for buttons/cards that need a gold "pop") ----
  static const LinearGradient goldGradient = LinearGradient(
    colors: [accentLight, accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}