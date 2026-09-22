import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Replays the player's winning path drawing itself in, cell by cell.
/// Used inside the embroidery-hoop on the Level Complete screen.
class SolvedGridPreview extends StatefulWidget {
  const SolvedGridPreview({
    super.key,
    required this.n,
    required this.path,
    required this.checkpoints,
  });

  final int n;
  final List<int> path;
  final Map<int, int> checkpoints;

  @override
  State<SolvedGridPreview> createState() => _SolvedGridPreviewState();
}

class _SolvedGridPreviewState extends State<SolvedGridPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250 + widget.path.length * 45))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _ReplayPainter(
            n: widget.n,
            path: widget.path,
            checkpoints: widget.checkpoints,
            progress: _c.value,
          ),
        ),
      ),
    );
  }
}

class _ReplayPainter extends CustomPainter {
  _ReplayPainter(
      {required this.n, required this.path, required this.checkpoints, required this.progress});
  final int n;
  final List<int> path;
  final Map<int, int> checkpoints;
  final double progress;

  Offset _center(int cell, double cellSize) {
    final r = cell ~/ n, c = cell % n;
    return Offset(c * cellSize + cellSize / 2, r * cellSize + cellSize / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / n;
    final visibleCount = (path.length * progress).ceil().clamp(0, path.length);
    final visible = path.take(visibleCount).toList();

    if (visible.length > 1) {
      final p = Path()..moveTo(_center(visible.first, cellSize).dx, _center(visible.first, cellSize).dy);
      for (final cell in visible.skip(1)) {
        final o = _center(cell, cellSize);
        p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = AppColors.teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = cellSize * 0.30
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final reachedCells = visible.toSet();
    checkpoints.forEach((cell, number) {
      final o = _center(cell, cellSize);
      final on = reachedCells.contains(cell);
      canvas.drawCircle(o, cellSize * 0.22,
          Paint()..color = on ? AppColors.tealDark : AppColors.orange.withOpacity(0.5));
      final tp = TextPainter(
        text: TextSpan(
            text: '$number',
            style: TextStyle(
                color: Colors.white, fontSize: cellSize * 0.24, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(covariant _ReplayPainter old) => old.progress != progress;
}
