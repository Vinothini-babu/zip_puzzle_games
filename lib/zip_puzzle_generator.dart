// zip_puzzle_generator.dart
// Core logic for ZIP_PUZZLE_GAME - Hamiltonian path puzzle generator + validator
// Reference: "Zip Puzzle" style number-path game (connect numbers in order, fill every cell)

import 'dart:math';

/// A single cell position on the grid
class Cell {
  final int row;
  final int col;
  const Cell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '($row,$col)';
}

/// Represents a generated puzzle: grid size, checkpoints (numbered cells),
/// and the hidden solution path (used only for validation / hint / solve).
class PuzzlePuzzleData {
  final int rows;
  final int cols;
  final List<Cell> solutionPath; // full Hamiltonian path, index 0 = start
  final Map<int, Cell> checkpoints; // number -> cell (1, 2, 3 ... N)

  PuzzlePuzzleData({
    required this.rows,
    required this.cols,
    required this.solutionPath,
    required this.checkpoints,
  });
}

class ZipPuzzleGenerator {
  final Random _rng = Random();

  /// Generates a puzzle for given [rows] x [cols] grid with [checkpointCount]
  /// numbered cells (including start=1 and end=last number).
  ///
  /// difficulty tip: checkpointCount ~ 4-6 for easy, 8-12 for hard on bigger grids.
  PuzzlePuzzleData generate({
    required int rows,
    required int cols,
    required int checkpointCount,
  }) {
    List<Cell>? path;

    // Retry until a full Hamiltonian path covering all cells is found.
    // Randomized DFS with backtracking - works fine for grids up to ~10x10.
    int attempts = 0;
    while (path == null && attempts < 200) {
      attempts++;
      final start = Cell(_rng.nextInt(rows), _rng.nextInt(cols));
      path = _findHamiltonianPath(rows, cols, start);
    }

    if (path == null) {
      throw StateError(
          'Could not generate a Hamiltonian path for $rows x $cols grid. Try fewer retries or smaller grid.');
    }

    final checkpoints = _pickCheckpoints(path, checkpointCount);

    return PuzzlePuzzleData(
      rows: rows,
      cols: cols,
      solutionPath: path,
      checkpoints: checkpoints,
    );
  }

  /// Randomized backtracking DFS to find a path visiting every cell exactly once.
  List<Cell>? _findHamiltonianPath(int rows, int cols, Cell start) {
    final total = rows * cols;
    final visited = <Cell>{};
    final path = <Cell>[];

    bool dfs(Cell current) {
      visited.add(current);
      path.add(current);

      if (path.length == total) return true;

      final neighbors = _neighborsOf(current, rows, cols)
          .where((c) => !visited.contains(c))
          .toList()
        ..shuffle(_rng);

      for (final next in neighbors) {
        if (dfs(next)) return true;
      }

      // backtrack
      visited.remove(current);
      path.removeLast();
      return false;
    }

    final success = dfs(start);
    return success ? List<Cell>.from(path) : null;
  }

  List<Cell> _neighborsOf(Cell c, int rows, int cols) {
    final candidates = [
      Cell(c.row - 1, c.col),
      Cell(c.row + 1, c.col),
      Cell(c.row, c.col - 1),
      Cell(c.row, c.col + 1),
    ];
    return candidates
        .where((n) => n.row >= 0 && n.row < rows && n.col >= 0 && n.col < cols)
        .toList();
  }

  /// Picks evenly spaced indices along the path as numbered checkpoints.
  /// Checkpoint 1 = path start, last checkpoint = path end (always included).
  Map<int, Cell> _pickCheckpoints(List<Cell> path, int count) {
    if (count < 2) count = 2;
    if (count > path.length) count = path.length;

    final indices = <int>{0, path.length - 1};
    while (indices.length < count) {
      // spread remaining checkpoints roughly evenly
      final idx = ((path.length - 1) * indices.length / count).round();
      indices.add(idx.clamp(0, path.length - 1));
    }

    final sortedIndices = indices.toList()..sort();
    final checkpoints = <int, Cell>{};
    for (int i = 0; i < sortedIndices.length; i++) {
      checkpoints[i + 1] = path[sortedIndices[i]];
    }
    return checkpoints;
  }
}

/// Validates a player's drawn path against puzzle rules:
/// - moves only between orthogonally adjacent cells
/// - no cell visited twice
/// - checkpoints hit in ascending order at correct path positions
/// - every cell in the grid is covered
class ZipPuzzleValidator {
  final PuzzlePuzzleData puzzle;
  ZipPuzzleValidator(this.puzzle);

  /// Returns null if valid, or an error message describing the first violation.
  String? validate(List<Cell> playerPath) {
    final totalCells = puzzle.rows * puzzle.cols;

    if (playerPath.isEmpty) return 'Path is empty';

    // 1. must start at checkpoint 1
    if (playerPath.first != puzzle.checkpoints[1]) {
      return 'Path must start at checkpoint 1';
    }

    // 2. must cover every cell exactly once
    if (playerPath.length != totalCells) {
      return 'Path must cover all $totalCells cells (currently ${playerPath.length})';
    }
    final seen = <Cell>{};
    for (final c in playerPath) {
      if (seen.contains(c)) return 'Cell $c visited more than once';
      seen.add(c);
    }

    // 3. adjacency check
    for (int i = 1; i < playerPath.length; i++) {
      if (!_isAdjacent(playerPath[i - 1], playerPath[i])) {
        return 'Cells ${playerPath[i - 1]} and ${playerPath[i]} are not adjacent';
      }
    }

    // 4. checkpoints must appear in ascending order along the path
    final checkpointOrder = puzzle.checkpoints.keys.toList()..sort();
    int lastFoundIndex = -1;
    for (final num in checkpointOrder) {
      final cell = puzzle.checkpoints[num]!;
      final idx = playerPath.indexOf(cell);
      if (idx == -1) return 'Checkpoint $num not found on path';
      if (idx < lastFoundIndex) {
        return 'Checkpoint $num appears out of order';
      }
      lastFoundIndex = idx;
    }

    // 5. must end at the final checkpoint
    if (playerPath.last != puzzle.checkpoints[checkpointOrder.last]) {
      return 'Path must end at the final checkpoint';
    }

    return null; // valid!
  }

  bool _isAdjacent(Cell a, Cell b) {
    final dr = (a.row - b.row).abs();
    final dc = (a.col - b.col).abs();
    return (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
  }
}

// ---------------------------------------------------------------------------
// Example usage (remove or move into a test file for your Flutter project):
//
// void main() {
//   final generator = ZipPuzzleGenerator();
//   final puzzle = generator.generate(rows: 6, cols: 6, checkpointCount: 6);
//   print('Checkpoints: ${puzzle.checkpoints}');
//   print('Solution path: ${puzzle.solutionPath}');
//
//   final validator = ZipPuzzleValidator(puzzle);
//   final result = validator.validate(puzzle.solutionPath); // should be valid
//   print(result == null ? 'Valid!' : 'Invalid: $result');
// }
// ---------------------------------------------------------------------------