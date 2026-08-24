// puzzle_screen.dart
// Plays one level: tracks time taken and reset attempts to compute a
// performance-based coin reward, then hands off to LevelCompleteScreen.

import 'dart:async';
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'level_data.dart';
import 'level_complete_screen.dart';
import 'how_to_play_dialog.dart';
import 'zip_puzzle_generator.dart';
import 'zip_puzzle_grid.dart';

class PuzzleScreen extends StatefulWidget {
  final LevelData level;
  const PuzzleScreen({super.key, required this.level});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  static const Color primaryTeal = Color(0xFF00796B);

  late PuzzlePuzzleData _puzzle;
  final Stopwatch _stopwatch = Stopwatch();
  int _resetCount = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _puzzle = ZipPuzzleGenerator().generate(
      rows: widget.level.rows,
      cols: widget.level.cols,
      checkpointCount: widget.level.checkpointCount,
    );
    // Show the tutorial only when starting Level 1, once the first frame
    // has rendered (so the puzzle screen is visible behind the dialog).
    // The timer starts only after the player dismisses it, so reading
    // the instructions doesn't eat into their speed-bonus window.
    if (widget.level.id == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await HowToPlayDialog.show(context);
        _stopwatch.start();
      });
    } else {
      _stopwatch.start();
    }
  }

  /// Coin reward scales with how well the player performed:
  /// - base reward from the level definition
  /// - +5 bonus coins if solved quickly (under 20s) with no resets
  /// - -2 coins per reset used, never dropping below the base reward's half
  int _computeReward() {
    final seconds = _stopwatch.elapsed.inSeconds;
    int reward = widget.level.baseCoinReward;

    if (_resetCount == 0 && seconds < 20) {
      reward += 5; // speed + no-mistake bonus
    }
    reward -= _resetCount * 2;

    final minReward = (widget.level.baseCoinReward / 2).ceil();
    if (reward < minReward) reward = minReward;
    return reward;
  }

  void _onComplete(bool solved) {
    if (!solved || _finished) return;
    _finished = true;
    _stopwatch.stop();

    final coinsEarned = _computeReward();
    AppState.instance.completeLevel(widget.level.id, coinsEarned);

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LevelCompleteScreen(
            level: widget.level,
            coinsEarned: coinsEarned,
            puzzle: _puzzle,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${widget.level.id}'),
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ZipPuzzleGrid(
              puzzle: _puzzle,
              onComplete: _onComplete,
              onReset: () => _resetCount++,
            ),
          ),
        ),
      ),
    );
  }
}