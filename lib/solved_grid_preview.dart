// solved_grid_preview.dart
// Small, non-interactive preview of a SOLVED puzzle - used on the
// Level Complete screen. Supports an animated "draw-in" of the path via
// [progress] (0.0 -> path not drawn, 1.0 -> fully drawn), so the
// congratulations screen can trace the solution like a replay.

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'zip_puzzle_generator.dart';

class SolvedGridPreview extends StatelessWidget {
  final PuzzlePuzzleData puzzle;
  final double size;
  final double progress; // 0.0 - 1.0, how much of the path is drawn

  const SolvedGridPreview({
    super.key,
    required this.puzzle,
    this.size = 240,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SolvedGridPainter(puzzle: puzzle, progress: progress),
      ),
    );
  }
}

class _SolvedGridPainter extends CustomPainter {
  final PuzzlePuzzleData puzzle;
  final double progress;
  _SolvedGridPainter({required this.puzzle, required this.progress});

  static const Color pathColor = Colors.white;
  static const Color checkpointFill = Color(0xFF00C853);
  static const Color checkpointBorder = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / puzzle.cols;

    final gridLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;

    for (int r = 0; r <= puzzle.rows; r++) {
      canvas.drawLine(Offset(0, r * cellSize), Offset(size.width, r * cellSize), gridLinePaint);
    }
    for (int c = 0; c <= puzzle.cols; c++) {
      canvas.drawLine(Offset(c * cellSize, 0), Offset(c * cellSize, size.height), gridLinePaint);
    }

    Offset center(Cell cell) =>
        Offset(cell.col * cellSize + cellSize / 2, cell.row * cellSize + cellSize / 2);

    // Build the full path, then trim it to `progress` using PathMetrics so
    // it looks like the solution is being traced/drawn in real time.
    final fullPath = Path();
    fullPath.moveTo(center(puzzle.solutionPath.first).dx, center(puzzle.solutionPath.first).dy);
    for (final cell in puzzle.solutionPath.skip(1)) {
      fullPath.lineTo(center(cell).dx, center(cell).dy);
    }

    final pathPaint = Paint()
      ..color = pathColor.withOpacity(0.9)
      ..strokeWidth = cellSize * 0.28
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (progress >= 1.0) {
      canvas.drawPath(fullPath, pathPaint);
    } else if (progress > 0) {
      final metrics = fullPath.computeMetrics().toList();
      double totalLength = 0;
      for (final m in metrics) {
        totalLength += m.length;
      }
      double remaining = totalLength * progress;
      for (final m in metrics) {
        if (remaining <= 0) break;
        final take = remaining >= m.length ? m.length : remaining;
        canvas.drawPath(m.extractPath(0, take), pathPaint);
        remaining -= take;
      }
    }

    // Checkpoints appear once the path has visually reached them.
    final checkpointCount = puzzle.checkpoints.length;
    final revealedCount = (checkpointCount * progress).ceil();
    final sortedNums = puzzle.checkpoints.keys.toList()..sort();

    final fillPaint = Paint()..color = checkpointFill;
    final borderPaint = Paint()
      ..color = checkpointBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < sortedNums.length; i++) {
      final num = sortedNums[i];
      final visible = i < revealedCount || progress >= 1.0;
      if (!visible) continue;

      final cell = puzzle.checkpoints[num]!;
      final c = center(cell);
      final radius = cellSize * 0.32;
      canvas.drawCircle(c, radius, fillPaint);
      canvas.drawCircle(c, radius, borderPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$num',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: cellSize * 0.32,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _SolvedGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}