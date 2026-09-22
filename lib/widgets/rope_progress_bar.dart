import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Twisted-rope style loading bar with orange end caps.
class RopeProgressBar extends StatelessWidget {
  const RopeProgressBar(
      {super.key, required this.progress, this.width = 220, this.height = 14});
  final double progress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height + 8,
      child: CustomPaint(painter: _RopePainter(progress)),
    );
  }
}

class _RopePainter extends CustomPainter {
  _RopePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const capW = 10.0;
    final barH = size.height - 8;
    final bar = Rect.fromLTWH(capW / 2, 4, size.width - capW, barH);
    final rr = RRect.fromRectAndRadius(bar, Radius.circular(barH / 2));
    final p = math.min(1.0, math.max(0.0, progress));

    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(bar, Paint()..color = const Color(0xFFE58A6B));
    canvas.drawRect(
      Rect.fromLTWH(bar.left, bar.top, bar.width * p, bar.height),
      Paint()..color = AppColors.teal,
    );
    final stripe = Paint()
      ..color = Colors.black.withOpacity(0.14)
      ..strokeWidth = 2.6;
    for (double x = bar.left - barH; x < bar.right; x += 7) {
      canvas.drawLine(Offset(x, bar.bottom), Offset(x + barH, bar.top), stripe);
    }
    canvas.restore();

    final cap = Paint()..color = AppColors.orangeLight;
    for (final x in [0.0, size.width - capW]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 0, capW, size.height), const Radius.circular(5)),
        cap,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RopePainter old) => old.progress != progress;
}
