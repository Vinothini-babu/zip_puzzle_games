import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Game-wide constants. Change these in one place.
class AppInfo {
  static const gameName = 'ZIP';
  static const studioName = 'SHADOW STUDIO'; // <- your studio / your name
  static const version = '1.0.0';
  static const premiumPrice = '₹1,150.00';
  static const maxLevel = 12;
  static const levelsPerChapter = 4;
  static const startCoins = 500;
  static const startMoves = 5; // resets allowed per level before "Out of moves"
  static const unlimitedMovesCost = 300;
  static const hintCost = 50;
}

class AppColors {
  // Background (reddish brown with flowers)
  static const bgDark = Color(0xFF6E3229);
  static const bgMid = Color(0xFF8E4636);
  static const bgGlow = Color(0xFFC8735A);
  static const flower = Color(0xFFFFB8A0);

  // Cartoon panel palette
  static const orange = Color(0xFFFFA23E);
  static const orangeLight = Color(0xFFFFC163);
  static const orangeDark = Color(0xFFD9701A);
  static const cream = Color(0xFFFFEAC0);
  static const creamDark = Color(0xFFFFD88A);
  static const brown = Color(0xFF9C4A12);
  static const brownDark = Color(0xFF6B2E0B);

  // Button colours
  static const green = Color(0xFF7BE04E);
  static const greenDark = Color(0xFF3F9A2B);
  static const red = Color(0xFFFF6B6B);
  static const redDark = Color(0xFFC72F3A);
  static const purple = Color(0xFFA99BFF);
  static const purpleDark = Color(0xFF6A5AE0);
  static const teal = Color(0xFF3EC9D6);
  static const tealDark = Color(0xFF1C8E9A);
  static const pink = Color(0xFFD86BE0);

  // Coin
  static const coin = Color(0xFFFFC928);
  static const coinDark = Color(0xFFE0921A);
}

class AppText {
  static TextStyle display(double size,
      {Color color = Colors.white, double? height}) =>
      GoogleFonts.fredoka(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          height: height);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange, brightness: Brightness.dark),
    scaffoldBackgroundColor: AppColors.bgDark,
  );
  return base.copyWith(textTheme: GoogleFonts.fredokaTextTheme(base.textTheme));
}
