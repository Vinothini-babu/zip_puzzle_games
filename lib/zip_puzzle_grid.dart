// zip_puzzle_grid.dart
// Flutter grid widget + drag gesture for ZIP_PUZZLE_GAME
// Pairs with zip_puzzle_generator.dart (Cell, PuzzlePuzzleData, ZipPuzzleValidator)
//
// Theme: Colors.teal.shade700 (0xFF00796B) as primary accent
// Works on Windows desktop AND Android/emulator - grid is locked to a square
// and capped at a max size so it never overflows on wide desktop windows.

import 'package:flutter/material.dart';
import 'zip_puzzle_generator.dart';

class ZipPuzzleGrid extends StatefulWidget {
  final PuzzlePuzzleData puzzle;
  final void Function(bool solved)? onComplete;
  final VoidCallback? onReset;

  const ZipPuzzleGrid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onReset,
  });

  @override
  State<ZipPuzzleGrid> createState() => _ZipPuzzleGridState();
}

class _ZipPuzzleGridState extends State<ZipPuzzleGrid>
    with SingleTickerProviderStateMixin {
  final List<Cell> _playerPath = [];
  String? _errorMessage;
  bool _solved = false;
  bool _locked = false; // true once solved - ignores further gestures
  bool _liveValid = true; // false while the current drag has broken checkpoint order

  late final Map<Cell, int> _cellToCheckpointNumber = {
    for (final entry in widget.puzzle.checkpoints.entries) entry.value: entry.key,
  };

  static const Color _primaryTeal = Color(0xFF00796B); // Colors.teal.shade700
  static const Color _lightTeal = Color(0xFFB2DFDB); // Colors.teal.shade100
  static const Color _errorRed = Color(0xFFD32F2F);

  double _cellSize = 0;

  late final AnimationController _blinkController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _blinkOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.15), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.15, end: 1.0), weight: 1),
  ]).animate(_blinkController);

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Cell? _cellFromLocalPosition(Offset localPos, double cellSize) {
    final col = (localPos.dx / cellSize).floor();
    final row = (localPos.dy / cellSize).floor();
    if (row < 0 || row >= widget.puzzle.rows || col < 0 || col >= widget.puzzle.cols) {
      return null;
    }
    return Cell(row, col);
  }

  /// Checks whether checkpoints touched so far are in ascending order
  /// (1, 2, 3...). Used to give live red/teal feedback while dragging,
  /// before the full path is complete.
  bool _isCheckpointOrderValid(List<Cell> path) {
    int expectedNext = 1;
    for (final cell in path) {
      final num = _cellToCheckpointNumber[cell];
      if (num != null) {
        if (num != expectedNext) return false;
        expectedNext++;
      }
    }
    return true;
  }

  void _handleStart(Offset localPos) {
    if (_locked) return;
    final cell = _cellFromLocalPosition(localPos, _cellSize);
    if (cell == null) return;
    if (cell != widget.puzzle.checkpoints[1]) return;

    setState(() {
      _playerPath
        ..clear()
        ..add(cell);
      _errorMessage = null;
      _solved = false;
      _liveValid = true;
    });
  }

  void _handleUpdate(Offset localPos) {
    if (_locked) return;
    if (_playerPath.isEmpty) return;
    final cell = _cellFromLocalPosition(localPos, _cellSize);
    if (cell == null) return;

    final last = _playerPath.last;
    if (cell == last) return;

    if (_playerPath.length > 1 && cell == _playerPath[_playerPath.length - 2]) {
      setState(() {
        _playerPath.removeLast();
        _liveValid = _isCheckpointOrderValid(_playerPath);
      });
      return;
    }

    final isAdjacent = (last.row - cell.row).abs() + (last.col - cell.col).abs() == 1;
    final alreadyVisited = _playerPath.contains(cell);

    if (isAdjacent && !alreadyVisited) {
      setState(() {
        _playerPath.add(cell);
        _liveValid = _isCheckpointOrderValid(_playerPath);
      });
    }
  }

  void _handleEnd() {
    if (_locked) return;
    if (_playerPath.isEmpty) return;
    final validator = ZipPuzzleValidator(widget.puzzle);
    final error = validator.validate(_playerPath);

    setState(() {
      _errorMessage = error;
      _solved = error == null;
      if (_solved) _locked = true; // freeze the board on success
    });

    if (_solved) {
      // blink the completed path 3 times before the checkmark settles
      _blinkController.forward(from: 0).then((_) async {
        for (int i = 0; i < 2; i++) {
          await _blinkController.forward(from: 0);
        }
      });
    }

    widget.onComplete?.call(_solved);
  }

  void _resetPath() {
    if (_locked) return; // can't reset after a solved board
    setState(() {
      _playerPath.clear();
      _errorMessage = null;
      _solved = false;
    });
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // LayoutBuilder gives us the max space we're allowed; we then pick
        // a square size that fits within BOTH width and height, capped so
        // it looks good on wide desktop windows too.
        LayoutBuilder(
          builder: (context, constraints) {
            final maxSquareSide = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
            final boardSide = maxSquareSide.clamp(0, 480).toDouble();
            _cellSize = boardSide / widget.puzzle.cols;

            return SizedBox(
              width: boardSide,
              height: boardSide,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onPanStart: (details) => _handleStart(details.localPosition),
                    onPanUpdate: (details) => _handleUpdate(details.localPosition),
                    onPanEnd: (_) => _handleEnd(),
                    child: AnimatedBuilder(
                      animation: _blinkController,
                      builder: (context, _) => CustomPaint(
                        size: Size(boardSide, boardSide),
                        painter: _GridPainter(
                          puzzle: widget.puzzle,
                          playerPath: _playerPath,
                          cellSize: _cellSize,
                          primaryColor: _primaryTeal,
                          lightColor: _lightTeal,
                          errorMode: _errorMessage != null || !_liveValid,
                          errorColor: _errorRed,
                          pathOpacity: _solved ? _blinkOpacity.value : 1.0,
                        ),
                      ),
                    ),
                  ),
                  // Success celebration: dims the board and pops a checkmark
                  // badge in, giving the player a clear "you solved it"
                  // moment before the screen navigates away.
                  AnimatedOpacity(
                    opacity: _solved ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      child: Container(
                        width: boardSide,
                        height: boardSide,
                        color: Colors.black.withOpacity(0.15),
                        alignment: Alignment.center,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.4, end: 1.0),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) => Transform.scale(
                            scale: _solved ? scale : 0,
                            child: child,
                          ),
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: _primaryTeal, size: 52),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (_errorMessage != null)
          Text(_errorMessage!, style: const TextStyle(color: _errorRed)),
        if (_solved)
          const Text('Solved! 🎉',
              style: TextStyle(color: _primaryTeal, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _resetPath,
          style: ElevatedButton.styleFrom(backgroundColor: _primaryTeal),
          child: const Text('Reset', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final PuzzlePuzzleData puzzle;
  final List<Cell> playerPath;
  final double cellSize;
  final Color primaryColor;
  final Color lightColor;
  final bool errorMode;
  final Color errorColor;
  final double pathOpacity;

  _GridPainter({
    required this.puzzle,
    required this.playerPath,
    required this.cellSize,
    required this.primaryColor,
    required this.lightColor,
    required this.errorMode,
    required this.errorColor,
    this.pathOpacity = 1.0,
  });

  Offset _center(Cell c) =>
      Offset(c.col * cellSize + cellSize / 2, c.row * cellSize + cellSize / 2);

  @override
  void paint(Canvas canvas, Size size) {
    final gridLinePaint = Paint()
      ..color = primaryColor.withOpacity(0.35)
      ..strokeWidth = 1.5;

    final outerBorderPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final cellFillPaint = Paint()..color = Colors.white;

    for (int r = 0; r < puzzle.rows; r++) {
      for (int c = 0; c < puzzle.cols; c++) {
        final rect = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);
        canvas.drawRect(rect, cellFillPaint);
        canvas.drawRect(rect, gridLinePaint);
      }
    }

    // outer border drawn last, on top, so the whole board reads clearly
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), outerBorderPaint);

    if (playerPath.length > 1) {
      final pathPaint = Paint()
        ..color = (errorMode ? errorColor : primaryColor).withOpacity(pathOpacity)
        ..strokeWidth = cellSize * 0.25
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(_center(playerPath.first).dx, _center(playerPath.first).dy);
      for (final cell in playerPath.skip(1)) {
        path.lineTo(_center(cell).dx, _center(cell).dy);
      }
      canvas.drawPath(path, pathPaint);
    }

    for (final entry in puzzle.checkpoints.entries) {
      final center = _center(entry.value);
      final radius = cellSize * 0.35;

      // A node is "joined" once the drawn path has reached it - it then
      // switches from the light unvisited fill to the active app color
      // (or the error color, if the path reaching it is currently wrong).
      final joined = playerPath.contains(entry.value);
      final nodeColor = joined
          ? (errorMode ? errorColor : primaryColor)
          : lightColor;
      final nodeTextColor = joined ? Colors.white : primaryColor;

      final fillPaint = Paint()..color = nodeColor;
      final borderPaint = Paint()
        ..color = joined ? nodeColor : primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, borderPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${entry.key}',
          style: TextStyle(
            color: nodeTextColor,
            fontWeight: FontWeight.bold,
            fontSize: cellSize * 0.35,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}