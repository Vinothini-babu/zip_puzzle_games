// level_data.dart
// Level catalog: difficulty progression from Easy -> Medium -> Hard.
// Grid size and checkpoint count grow with level id, matching the
// reference app's pattern (Level 1: small/simple, later levels bigger).

enum Difficulty { easy, medium, hard }

class LevelData {
  final int id;
  final int rows;
  final int cols;
  final int checkpointCount;
  final Difficulty difficulty;
  final int baseCoinReward;

  const LevelData({
    required this.id,
    required this.rows,
    required this.cols,
    required this.checkpointCount,
    required this.difficulty,
    required this.baseCoinReward,
  });

  String get difficultyLabel {
    switch (difficulty) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }
}

class LevelCatalog {
  /// 12 levels total, matching the reference app's level-select grid.
  /// Levels 1-4: Easy (4x4, few checkpoints)
  /// Levels 5-8: Medium (6x6, more checkpoints)
  /// Levels 9-12: Hard (8x8, most checkpoints)
  static final List<LevelData> levels = List.generate(12, (i) {
    final id = i + 1;
    if (id <= 4) {
      return LevelData(
        id: id,
        rows: 4,
        cols: 4,
        checkpointCount: 4 + id, // 5..8
        difficulty: Difficulty.easy,
        baseCoinReward: 10,
      );
    } else if (id <= 8) {
      return LevelData(
        id: id,
        rows: 6,
        cols: 6,
        checkpointCount: 6 + (id - 4), // 7..10
        difficulty: Difficulty.medium,
        baseCoinReward: 20,
      );
    } else {
      return LevelData(
        id: id,
        rows: 8,
        cols: 8,
        checkpointCount: 8 + (id - 8), // 9..12
        difficulty: Difficulty.hard,
        baseCoinReward: 30,
      );
    }
  });

  static LevelData byId(int id) => levels.firstWhere((l) => l.id == id);
}