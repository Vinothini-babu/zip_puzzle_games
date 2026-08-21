import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'level_select_screen.dart';

void main() {
  runApp(const ZipPuzzleApp());
}

class ZipPuzzleApp extends StatelessWidget {
  const ZipPuzzleApp({super.key});

  static const Color primaryTeal = Color(0xFF00796B); // Colors.teal.shade700

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zip Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryTeal),
        useMaterial3: true,
      ),
      // Splash -> Level Select -> Puzzle -> Level Complete -> back to
      // Level Select. Works the same on Windows desktop and Android.
      home: const SplashScreen(nextScreen: LevelSelectScreen()),
    );
  }
}