import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// A loading bar that actually looks like a zip/zipper: interlocking
/// teeth along a track, filling teal as it loads, with a little pull-tab
/// slider that travels along the top as progress increases.
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
      height: height + 16,
      child: CustomPaint(painter: _ZipperPainter(progress)),
    );
  }
}

class _ZipperPainter extends CustomPainter {
  _ZipperPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const barH = 10.0;
    final top = (size.height - barH) / 2;
    final track = Rect.fromLTWH(8, top, size.width - 16, barH);
    final trackRR = RRect.fromRectAndRadius(track, Radius.circular(barH / 2));
    final p = math.min(1.0, math.max(0.0, progress));

    // track background
    canvas.drawRRect(trackRR, Paint()..color = AppColors.creamDark.withOpacity(0.30));

    // filled (zipped-up) portion
    canvas.save();
    canvas.clipRRect(trackRR);
    canvas.drawRect(
      Rect.fromLTWH(track.left, track.top, track.width * p, track.height),
      Paint()..color = AppColors.teal,
    );
    canvas.restore();

    // zipper teeth zig-zag across the whole track
    const toothW = 9.0;
    final teeth = Path();
    bool topTooth = true;
    for (double x = track.left; x < track.right; x += toothW) {
      final tipY = topTooth ? track.top - 2 : track.bottom + 2;
      teeth
        ..moveTo(x, track.center.dy)
        ..lineTo(x + toothW / 2, tipY)
        ..lineTo(x + toothW, track.center.dy);
      topTooth = !topTooth;
    }
    canvas.drawPath(
      teeth,
      Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    // the zipper pull, sitting at the current progress position
    final pullX = track.left + track.width * p;
    final pullRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(pullX, track.center.dy),
          width: 16,
          height: size.height - 2),
      const Radius.circular(6),
    );
    canvas.drawRRect(
        pullRect,
        Paint()
          ..color = AppColors.orangeDark
          ..style = PaintingStyle.fill);
    canvas.drawRRect(
        pullRect,
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    canvas.drawCircle(
        Offset(pullX, track.center.dy), 2.6, Paint()..color = Colors.white.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant _ZipperPainter old) => old.progress != progress;
}