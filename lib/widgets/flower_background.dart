import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Reddish-brown radial background with a faint flower pattern.
class FlowerBackground extends StatelessWidget {
  const FlowerBackground({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.1),
              radius: 0.95,
              colors: [AppColors.bgGlow, AppColors.bgMid, AppColors.bgDark],
              stops: [0, 0.5, 1],
            ),
          ),
        ),
        const RepaintBoundary(
          child: CustomPaint(painter: _FlowerPainter(), size: Size.infinite),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _FlowerPainter extends CustomPainter {
  const _FlowerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    const step = 78.0;
    final petal = Paint()..color = AppColors.flower.withOpacity(0.10);
    final center = Paint()..color = AppColors.bgDark.withOpacity(0.20);
    int row = 0;
    for (double y = 10; y < size.height + step; y += step * 0.8) {
      final shift = (row++ % 2) * step / 2;
      for (double x = -20 + shift; x < size.width + step; x += step) {
        final dx = x + rnd.nextDouble() * 24 - 12;
        final dy = y + rnd.nextDouble() * 24 - 12;
        final r = 7 + rnd.nextDouble() * 6;
        final rot = rnd.nextDouble() * math.pi * 2;
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(rot);
        for (int i = 0; i < 5; i++) {
          final a = i * 2 * math.pi / 5;
          canvas.drawCircle(
              Offset(math.cos(a) * r, math.sin(a) * r), r * 0.75, petal);
        }
        canvas.drawCircle(Offset.zero, r * 0.4, center);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
