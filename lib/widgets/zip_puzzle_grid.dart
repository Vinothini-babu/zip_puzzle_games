import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../game/zip_puzzle_generator.dart';

/// The real drag-to-connect board.
/// - Touch checkpoint 1 to start, drag through adjacent cells.
/// - Every cell must be filled to win.
/// - Checkpoints must be crossed in order: hitting one out of order
///   flashes it red and rejects the move (does not extend the path).
/// - Dragging back onto the previous cell undoes the last step.
class ZipPuzzleGrid extends StatefulWidget {
  const ZipPuzzleGrid({
    super.key,
    required this.puzzle,
    required this.onSolved,
    this.onWrongMove,
    this.onProgressChanged,
  });

  final ZipPuzzle puzzle;

  /// Called once the whole board is filled and every checkpoint was
  /// crossed in order. Passes the player's final path for the replay.
  final ValueChanged<List<int>> onSolved;

  /// Called whenever the player tries an out-of-order checkpoint.
  final VoidCallback? onWrongMove;

  final ValueChanged<List<int>>? onProgressChanged;

  @override
  State<ZipPuzzleGrid> createState() => ZipPuzzleGridState();
}

class ZipPuzzleGridState extends State<ZipPuzzleGrid>
    with SingleTickerProviderStateMixin {
  List<int> _path = [];
  int? _errorCell;
  Timer? _errorTimer;
  bool _solved = false;

  late final AnimationController _solveFlash = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  int get n => widget.puzzle.n;
  Map<int, int> get _cp => widget.puzzle.checkpointOf;

  /// Public: used by the Clean button.
  void reset() {
    _errorTimer?.cancel();
    setState(() {
      _path = [];
      _errorCell = null;
      _solved = false;
    });
    widget.onProgressChanged?.call(_path);
  }

  /// Public: used by the Hint button. Reveals the next cell of the
  /// generator's own solution, snapping the current path back onto it
  /// first if the player had wandered off it.
  void revealNextCell() {
    if (_solved) return;
    final full = widget.puzzle.path;
    int common = 0;
    while (common < _path.length &&
        common < full.length &&
        _path[common] == full[common]) {
      common++;
    }
    setState(() {
      if (common < _path.length) _path = _path.sublist(0, common);
      if (common < full.length) _path = [..._path, full[common]];
    });
    widget.onProgressChanged?.call(_path);
    _checkSolved();
  }

  int _reachedCheckpoints() => _path.where((c) => _cp.containsKey(c)).length;

  bool _adjacent(int a, int b) {
    final ar = a ~/ n, ac = a % n, br = b ~/ n, bc = b % n;
    return (ar == br && (ac - bc).abs() == 1) ||
        (ac == bc && (ar - br).abs() == 1);
  }

  void _flashError(int cell) {
    _errorTimer?.cancel();
    setState(() => _errorCell = cell);
    _errorTimer = Timer(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _errorCell = null);
    });
    widget.onWrongMove?.call();
  }

  void _handleCell(int cell) {
    if (_solved) return;
    if (_path.isEmpty) {
      if (_cp[cell] == 1) {
        setState(() => _path = [cell]);
        widget.onProgressChanged?.call(_path);
      }
      return;
    }
    final last = _path.last;
    if (cell == last) return;

    // drag back = undo last step
    if (_path.length > 1 && cell == _path[_path.length - 2]) {
      setState(() => _path = _path.sublist(0, _path.length - 1));
      widget.onProgressChanged?.call(_path);
      return;
    }

    if (_path.contains(cell)) return;
    if (!_adjacent(cell, last)) return;

    final wantCp = _cp[cell];
    if (wantCp != null) {
      final nextExpected = _reachedCheckpoints() + 1;
      if (wantCp != nextExpected) {
        _flashError(cell);
        return;
      }
    }

    setState(() => _path = [..._path, cell]);
    widget.onProgressChanged?.call(_path);
    _checkSolved();
  }

  void _checkSolved() {
    if (_path.length == n * n && _reachedCheckpoints() == _cp.length) {
      _solved = true;
      _solveFlash.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) widget.onSolved(_path);
      });
    }
  }

  int _cellFromLocal(Offset local, double size) {
    final cellSize = size / n;
    final col = (local.dx / cellSize).floor().clamp(0, n - 1);
    final row = (local.dy / cellSize).floor().clamp(0, n - 1);
    return row * n + col;
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _solveFlash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final size = cons.biggest.shortestSide;
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _handleCell(_cellFromLocal(d.localPosition, size)),
            onPanUpdate: (d) => _handleCell(_cellFromLocal(d.localPosition, size)),
            child: AnimatedBuilder(
              animation: _solveFlash,
              builder: (context, _) => CustomPaint(
                painter: _GridPainter(
                  n: n,
                  path: _path,
                  checkpoints: _cp,
                  errorCell: _errorCell,
                  solveFlash: _solveFlash.value,
                ),
                size: Size(size, size),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.n,
    required this.path,
    required this.checkpoints,
    required this.errorCell,
    required this.solveFlash,
  });

  final int n;
  final List<int> path;
  final Map<int, int> checkpoints;
  final int? errorCell;
  final double solveFlash;

  Offset _center(int cell, double cellSize) {
    final r = cell ~/ n, c = cell % n;
    return Offset(c * cellSize + cellSize / 2, r * cellSize + cellSize / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / n;
    final gap = cellSize * 0.07;

    // background cells
    final cellPaint = Paint()..color = Colors.white.withOpacity(0.72);
    final cellBorder = Paint()
      ..color = AppColors.brown.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * cellSize + gap, r * cellSize + gap,
              cellSize - gap * 2, cellSize - gap * 2),
          Radius.circular(cellSize * 0.16),
        );
        canvas.drawRRect(rect, cellPaint);
        canvas.drawRRect(rect, cellBorder);
      }
    }

    // player's path
    if (path.length > 1) {
      final p = Path()..moveTo(_center(path.first, cellSize).dx, _center(path.first, cellSize).dy);
      for (final cell in path.skip(1)) {
        final o = _center(cell, cellSize);
        p.lineTo(o.dx, o.dy);
      }
      final glow = Color.lerp(AppColors.teal, Colors.white, solveFlash * 0.6)!;
      canvas.drawPath(
        p,
        Paint()
          ..color = glow
          ..style = PaintingStyle.stroke
          ..strokeWidth = cellSize * 0.34
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    if (path.isNotEmpty) {
      canvas.drawCircle(_center(path.first, cellSize), cellSize * 0.18,
          Paint()..color = AppColors.tealDark);
    }

    // checkpoints
    final reached = path.where((c) => checkpoints.containsKey(c)).length;
    checkpoints.forEach((cell, number) {
      final o = _center(cell, cellSize);
      final isReached = number <= reached;
      final isError = cell == errorCell;
      final fill = isError
          ? AppColors.red
          : (isReached ? AppColors.tealDark : AppColors.orange);
      canvas.drawCircle(o, cellSize * 0.30,
          Paint()..color = Colors.black.withOpacity(0.12));
      canvas.drawCircle(o, cellSize * 0.28, Paint()..color = fill);
      canvas.drawCircle(
          o,
          cellSize * 0.28,
          Paint()
            ..color = Colors.white.withOpacity(0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      final tp = TextPainter(
        text: TextSpan(
          text: '$number',
          style: TextStyle(
              color: Colors.white,
              fontSize: cellSize * 0.32,
              fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.path != path || old.errorCell != errorCell || old.solveFlash != solveFlash;
}
