import 'dart:math';

/// A generated Zip-style puzzle: a full Hamiltonian path over an n x n grid,
/// with a handful of cells along that path marked as numbered checkpoints.
/// The player must reproduce a path that fills every cell and crosses the
/// checkpoints in order 1, 2, 3 ...
class ZipPuzzle {
  const ZipPuzzle({required this.n, required this.path, required this.checkpointOf});

  final int n;

  /// The generator's own solution, as a sequence of cell indices
  /// (index = row * n + col). Not shown to the player — only used to
  /// place checkpoints and to power the Hint button.
  final List<int> path;

  /// cellIndex -> checkpoint number (1-based).
  final Map<int, int> checkpointOf;

  int get totalCells => n * n;
  int get totalCheckpoints => checkpointOf.length;

  static int row(int cell, int n) => cell ~/ n;
  static int col(int cell, int n) => cell % n;
}

/// NOTE: an earlier version of this file used randomised backtracking to
/// search for a Hamiltonian path. On some devices/seeds that search could
/// take several seconds (even longer in debug builds), which froze the
/// puzzle screen right when it opened — that was the "black / frozen
/// screen" bug. This version builds a valid Hamiltonian path directly
/// (a boustrophedon / "snake" sweep with a randomised orientation), so
/// puzzle generation is always instant, with no search involved.
class ZipPuzzleGenerator {
  const ZipPuzzleGenerator._();

  static ZipPuzzle generate(int n, {int? checkpointCount, int? seed}) {
    final rnd = Random(seed);
    final path = _generateSnakePath(n, rnd);
    final count = (checkpointCount ?? _defaultCheckpointCount(n))
        .clamp(2, path.length);
    final checkpointOf = _pickCheckpoints(path, count);
    return ZipPuzzle(n: n, path: path, checkpointOf: checkpointOf);
  }

  static int _defaultCheckpointCount(int n) => n.clamp(3, 6);

  /// Always-valid, always-instant Hamiltonian path: sweep the grid row by
  /// row (or column by column), alternating direction each line, like
  /// mowing a lawn. The 3 random flags below just change the starting
  /// corner / axis so puzzles don't all look identical.
  static List<int> _generateSnakePath(int n, Random rnd) {
    final rowMajor = rnd.nextBool();
    final reverseOuter = rnd.nextBool();
    final startFlipped = rnd.nextBool();

    final path = <int>[];
    final outerIndices = List<int>.generate(n, (i) => i);
    final outerOrder = reverseOuter ? outerIndices.reversed.toList() : outerIndices;

    for (int oi = 0; oi < n; oi++) {
      final o = outerOrder[oi];
      final flipThisLine = startFlipped ? oi.isEven : oi.isOdd;
      final innerIndices = List<int>.generate(n, (i) => i);
      final innerOrder = flipThisLine ? innerIndices.reversed.toList() : innerIndices;
      for (final ii in innerOrder) {
        path.add(rowMajor ? (o * n + ii) : (ii * n + o));
      }
    }
    return path;
  }

  static Map<int, int> _pickCheckpoints(List<int> path, int count) {
    final map = <int, int>{};
    for (int i = 0; i < count; i++) {
      final t = count == 1 ? 0.0 : i / (count - 1);
      final idx = (t * (path.length - 1)).round();
      map[path[idx]] = i + 1;
    }
    return map;
  }
}
