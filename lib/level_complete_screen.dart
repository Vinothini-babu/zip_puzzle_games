// level_complete_screen.dart
// Congratulations screen shown after solving a level.
// Design matches the reference "ZIP" app: solid background, level number,
// "Congratulations!" heading, the completed grid shown with its solved
// path, coins earned, and a simple arrow button to continue.

import 'package:flutter/material.dart';
import 'level_data.dart';
import 'level_select_screen.dart';
import 'puzzle_screen.dart';
import 'solved_grid_preview.dart';
import 'zip_puzzle_generator.dart';

class LevelCompleteScreen extends StatelessWidget {
  final LevelData level;
  final int coinsEarned;
  final PuzzlePuzzleData puzzle;

  const LevelCompleteScreen({
    super.key,
    required this.level,
    required this.coinsEarned,
    required this.puzzle,
  });

  static const Color background = Color(0xFF004D40); // teal 900
  static const Color primaryTeal = Color(0xFF00796B);

  void _goNext(BuildContext context) {
    final hasNextLevel = level.id < LevelCatalog.levels.length;
    if (hasNextLevel) {
      final nextLevel = LevelCatalog.byId(level.id + 1);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PuzzleScreen(level: nextLevel)),
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // top bar - back to level select
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
                          (route) => false,
                    );
                  },
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Text('ZIP PUZZLE',
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Level #${level.id}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Congratulations!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('+$coinsEarned',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(width: 6),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // The completed grid, shown with its full solved path -
            // matches the reference app's congratulations screen.
            SolvedGridPreview(puzzle: puzzle, size: 260),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: GestureDetector(
                onTap: () => _goNext(context),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: background),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}