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
  // Background — deep indigo / violet "night arcade" (was brown/flower)
  static const bgDark = Color(0xFF211A45);
  static const bgMid = Color(0xFF3B2C7E);
  static const bgGlow = Color(0xFF7657F0);
  static const flower = Color(0xFFC9B8FF); // sparkle-pattern accent colour

  // Cartoon panel palette — coral/pink is now the primary warm colour
  // (was orange), matching the new indigo backdrop instead of brown wood.
  static const orange = Color(0xFFFF6F91);
  static const orangeLight = Color(0xFFFF9EB6);
  static const orangeDark = Color(0xFFD1436C);
  static const cream = Color(0xFFF4EEFF);
  static const creamDark = Color(0xFFE3D6FF);
  static const brown = Color(0xFF3B2A66); // deep plum text (was brown)
  static const brownDark = Color(0xFF241849);

  // Button colours
  static const green = Color(0xFF57E0A6);
  static const greenDark = Color(0xFF1F9E6E);
  static const red = Color(0xFFFF6B6B);
  static const redDark = Color(0xFFC72F3A);
  static const purple = Color(0xFFB08CFF);
  static const purpleDark = Color(0xFF6B46C9);
  static const teal = Color(0xFF29D9E0);
  static const tealDark = Color(0xFF139AA3);
  static const pink = Color(0xFFFF8FD0);

  // Coin
  static const coin = Color(0xFFFFD24D);
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