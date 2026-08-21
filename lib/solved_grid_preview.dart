// solved_grid_preview.dart
// Small, non-interactive preview of a SOLVED puzzle - used on the
// Level Complete screen, matching the reference app's congratulations
// screen (shows the grid with the completed path drawn in).

import 'package:flutter/material.dart';
import 'zip_puzzle_generator.dart';

class SolvedGridPreview extends StatelessWidget {
  final PuzzlePuzzleData puzzle;
  final double size;

  const SolvedGridPreview({
    super.key,
    required this.puzzle,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SolvedGridPainter(puzzle: puzzle),
      ),
    );
  }
}

class _SolvedGridPainter extends CustomPainter {
  final PuzzlePuzzleData puzzle;
  _SolvedGridPainter({required this.puzzle});

  static const Color pathColor = Colors.white;
  static const Color checkpointFill = Color(0xFF00C853); // green, like reference
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

    // draw the full solved path
    final pathPaint = Paint()
      ..color = pathColor.withOpacity(0.85)
      ..strokeWidth = cellSize * 0.28
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(center(puzzle.solutionPath.first).dx, center(puzzle.solutionPath.first).dy);
    for (final cell in puzzle.solutionPath.skip(1)) {
      path.lineTo(center(cell).dx, center(cell).dy);
    }
    canvas.drawPath(path, pathPaint);

    // draw checkpoints on top
    final fillPaint = Paint()..color = checkpointFill;
    final borderPaint = Paint()
      ..color = checkpointBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final entry in puzzle.checkpoints.entries) {
      final c = center(entry.value);
      final radius = cellSize * 0.32;
      canvas.drawCircle(c, radius, fillPaint);
      canvas.drawCircle(c, radius, borderPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '${entry.key}',
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
  bool shouldRepaint(covariant _SolvedGridPainter oldDelegate) => false;
}