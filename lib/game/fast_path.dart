import 'dart:math';

/// Fast random Hamiltonian path on an n x n grid ("backbite" algorithm).
/// Works instantly even for 16x16 (plain backtracking gets very slow there).
/// Same seed => same puzzle, so "Level 5" is always the same puzzle.
List<int> randomHamiltonianPath(int n, {int? seed}) {
  final rnd = Random(seed);
  final total = n * n;

  // start from a snake, then shuffle it with backbite moves
  final path = <int>[];
  for (var r = 0; r < n; r++) {
    if (r.isEven) {
      for (var c = 0; c < n; c++) path.add(r * n + c);
    } else {
      for (var c = n - 1; c >= 0; c--) path.add(r * n + c);
    }
  }
  final pos = List<int>.filled(total, 0);
  for (var i = 0; i < total; i++) pos[path[i]] = i;

  void reverse(int a, int b) {
    var i = a, j = b;
    while (i < j) {
      final t = path[i];
      path[i] = path[j];
      path[j] = t;
      i++;
      j--;
    }
    for (var x = a; x <= b; x++) pos[path[x]] = x;
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

/// Places numbered checkpoints ALONG the path, in order.
/// Returns cell -> number (1 = path start, count = path end).
Map<int, int> placeCheckpoints(List<int> path, int count, {int? seed}) {
  final rnd = Random(seed);
  final total = path.length;
  final k = count.clamp(2, total ~/ 2);
  final idx = <int>{0, total - 1};
  final seg = (total - 1) / (k - 1);
  for (var i = 1; i < k - 1; i++) {
    final lo = (i * seg - seg / 3).round();
    final hi = (i * seg + seg / 3).round();
    var p = lo + rnd.nextInt(max(1, hi - lo + 1));
    idx.add(p.clamp(1, total - 2));
  }
  final sorted = idx.toList()..sort();
  return {for (var i = 0; i < sorted.length; i++) path[sorted[i]]: i + 1};
}

/// Random walls on edges the solution does NOT use (so it stays solvable).
/// Keys use the same format as zipEdgeKey() in zip_puzzle_grid.dart.
Set<int> placeWalls(List<int> path, int n, int count, {int? seed}) {
  if (count <= 0) return {};
  final rnd = Random(seed);
  final pos = List<int>.filled(n * n, 0);
  for (var i = 0; i < path.length; i++) pos[path[i]] = i;
  final cand = <int>[];
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      final a = r * n + c;
      if (c + 1 < n && (pos[a] - pos[a + 1]).abs() != 1) cand.add(a * 100000 + a + 1);
      if (r + 1 < n && (pos[a] - pos[a + n]).abs() != 1) cand.add(a * 100000 + a + n);
    }
  }
  cand.shuffle(rnd);
  return cand.take(count).toSet();
}