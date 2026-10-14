import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../game/zip_puzzle_generator.dart';
import 'stroked_text.dart';

/// Edge key for a wall between two neighbouring cells (order independent).
int zipEdgeKey(int a, int b) => a < b ? a * 100000 + b : b * 100000 + a;

/// The real drag-to-connect board (real Zip rules).
/// - Touch checkpoint 1 to start, drag through adjacent cells.
/// - Checkpoints must be crossed in order 1,2,3... (wrong one flashes red).
/// - You cannot cross your own path or a wall.
/// - Drag back = undo. Tap/press any cell already on your path = rewind to it.
/// - Solved only when EVERY cell is filled AND you finish on the LAST number.
/// - Works with fast finger drags (no skipped cells, no pan-slop delay).
class ZipPuzzleGrid extends StatefulWidget {
  const ZipPuzzleGrid({
    super.key,
    required this.puzzle,
    required this.onSolved,
    this.onWrongMove,
    this.onProgressChanged,
    this.onStep,
    this.walls = const <int>{},
  });

  final ZipPuzzle puzzle;

  /// Optional blocked edges, built with [zipEdgeKey].
  final Set<int> walls;

  final ValueChanged<List<int>> onSolved;
  final VoidCallback? onWrongMove;
  final ValueChanged<List<int>>? onProgressChanged;

  /// Called every time the path grows by one cell (for the tick sound).
  final VoidCallback? onStep;

  @override
  State<ZipPuzzleGrid> createState() => ZipPuzzleGridState();
}

class ZipPuzzleGridState extends State<ZipPuzzleGrid>
    with TickerProviderStateMixin {
  List<int> _path = [];
  int? _errorCell;
  Timer? _errorTimer;
  bool _solved = false;

  // fast, strong blink (6 half-flashes ~ 1.5s)
  late final AnimationController _solveFlash = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));

  // "SOLVED!" popup that bounces in
  late final AnimationController _popup = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));

  int get n => widget.puzzle.n;
  Map<int, int> get _cp => widget.puzzle.checkpointOf;

  /// Public: used by the Clean button.
  void reset() {
    _errorTimer?.cancel();
    _solveFlash.value = 0;
    _popup.value = 0;
    setState(() {
      _path = [];
      _errorCell = null;
      _solved = false;
    });
    widget.onProgressChanged?.call(_path);
  }

  /// Public: used by the Hint button.
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

  // ── pointer down: start on "1", or rewind to a cell already on the path ──
  void _down(int cell) {
    if (_solved) return;
    if (_path.isEmpty) {
      if (_cp[cell] == 1) {
        setState(() => _path = [cell]);
        widget.onProgressChanged?.call(_path);
      }
      return;
    }
    final idx = _path.indexOf(cell);
    if (idx >= 0 && idx < _path.length - 1) {
      setState(() => _path = _path.sublist(0, idx + 1));
      widget.onProgressChanged?.call(_path);
    }
  }

  // ── pointer move: walk towards the finger one cell at a time ──
  void _move(int target) {
    if (_solved || _path.isEmpty) return;
    int guard = 0;
    while (_path.last != target && guard++ < 4) {
      final h = _path.last;
      final dr = target ~/ n - h ~/ n;
      final dc = target % n - h % n;
      final next =
      dr.abs() >= dc.abs() ? h + (dr > 0 ? n : -n) : h + (dc > 0 ? 1 : -1);
      if (!_step(next)) break;
    }
  }

  bool _step(int cell) {
    final last = _path.last;

    // drag back = undo last step
    if (_path.length > 1 && cell == _path[_path.length - 2]) {
      setState(() => _path = _path.sublist(0, _path.length - 1));
      widget.onProgressChanged?.call(_path);
      return true;
    }

    if (_path.contains(cell)) return false;
    if (!_adjacent(cell, last)) return false;
    if (widget.walls.contains(zipEdgeKey(cell, last))) {
      _flashError(cell);
      return false;
    }

    final reached = _reachedCheckpoints();
    // already on the final number -> cannot go further (only undo)
    if (reached == _cp.length) return false;

    final wantCp = _cp[cell];
    if (wantCp != null && wantCp != reached + 1) {
      _flashError(cell);
      return false;
    }

    setState(() => _path = [..._path, cell]);
    widget.onProgressChanged?.call(_path);
    widget.onStep?.call();
    _checkSolved();
    return true;
  }

  void _checkSolved() {
    if (_path.length == n * n && _reachedCheckpoints() == _cp.length) {
      _solved = true;
      _popup.forward(from: 0);
      // blink a few times, then report
      _solveFlash
          .repeat(reverse: true, count: 6)
          .whenCompleteOrCancel(() {
        if (mounted && _solved) widget.onSolved(_path);
      });
    }
  }

  int _cellFromLocal(Offset local, double size) {
    final cellSize = size / n;
    final col = (local.dx / cellSize).floor().clamp(0, n - 1);
    final row = (local.dy / cellSize).floor().clamp(0, n - 1);
    return row * n + col;
  }

  Widget _solvedPopup(double size) {
    final t = _popup.value;
    final scale = Curves.elasticOut.transform(t.clamp(0.0, 1.0).toDouble());
    final opacity = (t * 3).clamp(0.0, 1.0).toDouble();
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: size * 0.08, vertical: size * 0.045),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.07),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9BE564), AppColors.green],
            ),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
              BoxShadow(
                  color: const Color(0xFFFFD54F).withOpacity(0.8),
                  blurRadius: 30,
                  spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: size * 0.14),
              StrokedText('SOLVED!',
                  size: size * 0.10, stroke: AppColors.greenDark),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _solveFlash.dispose();
    _popup.dispose();
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
          // Listener (not GestureDetector) => reacts instantly, no pan slop.
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _down(_cellFromLocal(e.localPosition, size)),
            onPointerMove: (e) => _move(_cellFromLocal(e.localPosition, size)),
            child: AnimatedBuilder(
              animation: Listenable.merge([_solveFlash, _popup]),
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  // board "pulses" slightly while blinking
                  Transform.scale(
                    scale: 1 + 0.05 * _solveFlash.value,
                    child: CustomPaint(
                      painter: _GridPainter(
                        n: n,
                        path: _path,
                        checkpoints: _cp,
                        walls: widget.walls,
                        errorCell: _errorCell,
                        solveFlash: _solveFlash.value,
                      ),
                      size: Size(size, size),
                    ),
                  ),
                  if (_solved)
                    IgnorePointer(child: _solvedPopup(size)),
                ],
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
    required this.walls,
    required this.errorCell,
    required this.solveFlash,
  });

  final int n;
  final List<int> path;
  final Map<int, int> checkpoints;
  final Set<int> walls;
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
        if (solveFlash > 0) {
          canvas.drawRRect(
              rect,
              Paint()
                ..color =
                const Color(0xFFFFD54F).withOpacity(0.55 * solveFlash));
        }
        canvas.drawRRect(rect, cellBorder);
      }
    }

    // player's path
    if (path.length > 1) {
      final p = Path()
        ..moveTo(_center(path.first, cellSize).dx,
            _center(path.first, cellSize).dy);
      for (final cell in path.skip(1)) {
        final o = _center(cell, cellSize);
        p.lineTo(o.dx, o.dy);
      }
      final glow =
      Color.lerp(AppColors.teal, const Color(0xFFFFC107), solveFlash)!;
      if (solveFlash > 0) {
        canvas.drawPath(
          p,
          Paint()
            ..color = const Color(0xFFFFE082).withOpacity(0.9 * solveFlash)
            ..style = PaintingStyle.stroke
            ..strokeWidth = cellSize * 0.62
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, cellSize * 0.22),
        );
      }
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

    // walls (thick bars on the edge between two cells)
    if (walls.isNotEmpty) {
      final wallPaint = Paint()
        ..color = AppColors.brownDark
        ..strokeWidth = (cellSize * 0.10).clamp(2.5, 7.0)
        ..strokeCap = StrokeCap.round;
      for (final key in walls) {
        final a = key ~/ 100000, b = key % 100000;
        if (b == a + 1 && a ~/ n == b ~/ n) {
          final x = (b % n) * cellSize;
          final y = (a ~/ n) * cellSize;
          canvas.drawLine(Offset(x, y + gap), Offset(x, y + cellSize - gap), wallPaint);
        } else {
          final x = (a % n) * cellSize;
          final y = (b ~/ n) * cellSize;
          canvas.drawLine(Offset(x + gap, y), Offset(x + cellSize - gap, y), wallPaint);
        }
      }
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
      canvas.drawCircle(
          o, cellSize * 0.30, Paint()..color = Colors.black.withOpacity(0.12));
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
              fontSize: cellSize * (number > 9 ? 0.26 : 0.32),
              fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => true;
}