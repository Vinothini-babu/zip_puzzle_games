import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Decorative "closed puzzle" card art for the home screen and level list.
/// Deliberately does NOT reveal the solution path — just a clean blank
/// board with a zip-bolt badge, like a face-down puzzle card.
class MiniBoardPreview extends StatelessWidget {
  const MiniBoardPreview({super.key, this.n = 5, this.color = AppColors.brown});
  final int n;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, cons) {
        final size = cons.biggest.shortestSide;
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size(size, size), painter: _BlankBoardPainter(n, color)),
            Container(
              width: size * 0.36,
              height: size * 0.36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.orangeLight, AppColors.orange],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4, offset: const Offset(0, 3)),
                ],
              ),
              child: Icon(Icons.bolt_rounded, color: AppColors.orangeDark, size: size * 0.2),
            ),
          ],
        );
      }),
    );
  }
}

class _BlankBoardPainter extends CustomPainter {
  _BlankBoardPainter(this.n, this.color);
  final int n;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / n;
    final gap = cell * 0.07;
    final cellPaint = Paint()..color = Colors.white.withOpacity(0.65);
    final border = Paint()
      ..color = color.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * cell + gap, r * cell + gap, cell - gap * 2, cell - gap * 2),
          Radius.circular(cell * 0.16),
        );
        canvas.drawRRect(rect, cellPaint);
        canvas.drawRRect(rect, border);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BlankBoardPainter old) => old.n != n || old.color != color;
}
