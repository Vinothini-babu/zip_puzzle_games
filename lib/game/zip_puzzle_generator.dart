import 'dart:math';

/// A generated Zip-style puzzle: a full Hamiltonian path over an n x n grid,
/// with cells along that path marked as numbered checkpoints (and optional
/// walls). The player must fill every cell and cross the checkpoints in
/// order 1, 2, 3 ... finishing on the last number.
class ZipPuzzle {
  const ZipPuzzle({
    required this.n,
    required this.path,
    required this.checkpointOf,
    this.walls = const <int>{},
  });

  final int n;

  /// The generator's own solution (index = row * n + col). Only used to
  /// place checkpoints/walls and to power the Hint button.
  final List<int> path;

  /// cellIndex -> checkpoint number (1-based).
  final Map<int, int> checkpointOf;

  /// Blocked edges between neighbouring cells. Key = smaller*100000 + larger.
  final Set<int> walls;

  int get totalCells => n * n;
  int get totalCheckpoints => checkpointOf.length;

  static int row(int cell, int n) => cell ~/ n;
  static int col(int cell, int n) => cell % n;
}

/// Builds a real, random-looking Zip puzzle.
///
/// The old version used a snake sweep, so every puzzle was the same
/// zig-zag. This version shuffles the snake with "backbite" moves, which
/// keeps the path a valid Hamiltonian path but makes it twist like a real
/// Zip puzzle. It is instant, even on 16x16 (no search / no freezing).
/// Same seed => same puzzle, so a level is always the same.
class ZipPuzzleGenerator {
  const ZipPuzzleGenerator._();

  static ZipPuzzle generate(
      int n, {
        int? checkpointCount,
        int? wallCount,
        int? seed,
      }) {
    final rnd = Random(seed);
    final path = _randomHamiltonianPath(n, rnd);
    final int count = (checkpointCount ?? _defaultCheckpointCount(n))
        .clamp(2, max(2, path.length ~/ 2))
        .toInt();
    final checkpointOf = _pickCheckpoints(path, count, rnd);
    final walls = _pickWalls(path, n, wallCount ?? _defaultWallCount(n), rnd);
    return ZipPuzzle(
        n: n, path: path, checkpointOf: checkpointOf, walls: walls);
  }

  // 4x4 -> 3, 6x6 -> 5, 10x10 -> 12, 16x16 -> 16
  static int _defaultCheckpointCount(int n) =>
      ((n * n) / 8).round().clamp(3, 16).toInt();

  // easy (<=10): no walls, medium: a few, hard (16): more
  static int _defaultWallCount(int n) {
    if (n <= 10) return 0;
    if (n < 16) return (n * n * 0.04).round();
    return (n * n * 0.07).round();
  }

  static List<int> _randomHamiltonianPath(int n, Random rnd) {
    final total = n * n;
    final path = <int>[];
    for (var r = 0; r < n; r++) {
      if (r.isEven) {
        for (var c = 0; c < n; c++) {
          path.add(r * n + c);
        }
      } else {
        for (var c = n - 1; c >= 0; c--) {
          path.add(r * n + c);
        }
      }
    }
    final pos = List<int>.filled(total, 0);
    for (var i = 0; i < total; i++) {
      pos[path[i]] = i;
    }

    void reverse(int a, int b) {
      var i = a, j = b;
      while (i < j) {
        final t = path[i];
        path[i] = path[j];
        path[j] = t;
        i++;
        j--;
      }
      for (var x = a; x <= b; x++) {
        pos[path[x]] = x;
      }
    }

    List<int> neighbours(int c) {
      final r = c ~/ n, col = c % n;
      return [
        if (r > 0) c - n,
        if (r < n - 1) c + n,
        if (col > 0) c - 1,
        if (col < n - 1) c + 1,
      ];
    }

    for (var it = 0; it < total * 60; it++) {
      final atHead = rnd.nextBool();
      final end = atHead ? path.first : path.last;
      final nb = neighbours(end);
      final v = nb[rnd.nextInt(nb.length)];
      final k = pos[v];
      if (atHead) {
        if (k <= 1) continue;
        reverse(0, k - 1);
      } else {
        if (k >= total - 2) continue;
        reverse(k + 1, total - 1);
      }
    }
    if (rnd.nextBool()) reverse(0, total - 1);
    return path;
  }

  /// Checkpoints spread along the path with a little jitter.
  /// 1 = path start, last number = path end.
  static Map<int, int> _pickCheckpoints(List<int> path, int count, Random rnd) {
    final total = path.length;
    final idx = <int>{0, total - 1};
    final seg = (total - 1) / (count - 1);
    for (var i = 1; i < count - 1; i++) {
      final lo = (i * seg - seg / 3).round();
      final hi = (i * seg + seg / 3).round();
      final p = lo + rnd.nextInt(max(1, hi - lo + 1));
      idx.add(p.clamp(1, total - 2).toInt());
    }
    final sorted = idx.toList()..sort();
    return {for (var i = 0; i < sorted.length; i++) path[sorted[i]]: i + 1};
  }

  /// Walls only on edges the solution does NOT use, so it stays solvable.
  static Set<int> _pickWalls(List<int> path, int n, int count, Random rnd) {
    if (count <= 0) return const <int>{};
    final pos = List<int>.filled(n * n, 0);
    for (var i = 0; i < path.length; i++) {
      pos[path[i]] = i;
    }
    final cand = <int>[];
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final a = r * n + c;
        if (c + 1 < n && (pos[a] - pos[a + 1]).abs() != 1) {
          cand.add(a * 100000 + a + 1);
        }
        if (r + 1 < n && (pos[a] - pos[a + n]).abs() != 1) {
          cand.add(a * 100000 + a + n);
        }
      }
    }
    cand.shuffle(rnd);
    return cand.take(count).toSet();
  }
}