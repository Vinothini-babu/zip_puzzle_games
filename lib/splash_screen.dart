// splash_screen.dart
// Splash screen for ZIP_PUZZLE_GAME
// Theme: Colors.teal.shade700 (0xFF00796B)

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final Duration duration;

  const SplashScreen({
    super.key,
    required this.nextScreen,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryTeal = Color(0xFF00796B); // Colors.teal.shade700
  static const Color _lightTeal = Color(0xFFB2DFDB); // Colors.teal.shade100

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(widget.duration);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => widget.nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
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
    return Scaffold(
      backgroundColor: _primaryTeal,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon / logo placeholder - replace with your actual logo asset
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(60, 60),
                      painter: _ZipIconPainter(color: _primaryTeal),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ZIP PUZZLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect. Fill. Solve.',
                  style: TextStyle(
                    color: _lightTeal,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(_lightTeal),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple zig-zag path icon drawn with CustomPaint - stands in for a logo
/// until a real app icon/asset is added.
class _ZipIconPainter extends CustomPainter {
  final Color color;
  _ZipIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.85);
    path.lineTo(size.width * 0.1, size.height * 0.35);
    path.lineTo(size.width * 0.5, size.height * 0.35);
    path.lineTo(size.width * 0.5, size.height * 0.85);
    path.lineTo(size.width * 0.9, size.height * 0.85);
    path.lineTo(size.width * 0.9, size.height * 0.15);

    canvas.drawPath(path, paint);

    // dots at the two ends (start / end checkpoints)
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.85), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.15), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ZipIconPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Example usage in main.dart:
//
// void main() {
//   runApp(const ZipPuzzleApp());
// }
//
// class ZipPuzzleApp extends StatelessWidget {
//   const ZipPuzzleApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Zip Puzzle',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primaryColor: const Color(0xFF00796B),
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00796B)),
//         useMaterial3: true,
//       ),
//       home: SplashScreen(nextScreen: const HomeScreen()), // your home/menu screen
//     );
//   }
// }
// ---------------------------------------------------------------------------