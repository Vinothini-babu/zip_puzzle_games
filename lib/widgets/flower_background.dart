import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Deep indigo/violet "night arcade" background with a faint sparkle
/// pattern — distinct from the brown/floral cottage look.
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
          child: CustomPaint(painter: _SparklePainter(), size: Size.infinite),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    const step = 70.0;
    final sparkle = Paint()..color = AppColors.flower.withOpacity(0.14);
    int row = 0;
    for (double y = 10; y < size.height + step; y += step * 0.8) {
      final shift = (row++ % 2) * step / 2;
      for (double x = -20 + shift; x < size.width + step; x += step) {
        final dx = x + rnd.nextDouble() * 24 - 12;
        final dy = y + rnd.nextDouble() * 24 - 12;
        final r = 5 + rnd.nextDouble() * 5;
        final rot = rnd.nextDouble() * math.pi * 2;
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(rot);
        final path = Path()
          ..moveTo(0, -r)
          ..lineTo(r * 0.32, -r * 0.32)
          ..lineTo(r, 0)
          ..lineTo(r * 0.32, r * 0.32)
          ..lineTo(0, r)
          ..lineTo(-r * 0.32, r * 0.32)
          ..lineTo(-r, 0)
          ..lineTo(-r * 0.32, -r * 0.32)
          ..close();
        canvas.drawPath(path, sparkle);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}