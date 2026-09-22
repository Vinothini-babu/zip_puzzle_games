import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../widgets/game_button.dart';
import '../widgets/solved_grid_preview.dart';
import '../widgets/stroked_text.dart';
import '../widgets/zip_puzzle_grid.dart';
import 'puzzle_controller.dart';
import 'zip_puzzle_generator.dart';

/// Builds the real, playable board for [level] and wires it to
/// [controller] (reportReset on Clean, reportSolved when finished).
Widget buildBoardForLevel(
    BuildContext context, int level, PuzzleController controller) {
  return RealBoard(level: level, controller: controller);
}

class RealBoard extends StatefulWidget {
  const RealBoard({super.key, required this.level, required this.controller});
  final int level;
  final PuzzleController controller;

  @override
  State<RealBoard> createState() => _RealBoardState();
}

class _RealBoardState extends State<RealBoard> {
  final _gridKey = GlobalKey<ZipPuzzleGridState>();
  late final ZipPuzzle _puzzle;

  @override
  void initState() {
    super.initState();
    final n = 4 + GameState.chapterOf(widget.level);
    final cpCount = (3 + GameState.chapterOf(widget.level)).clamp(3, 6);
    _puzzle = ZipPuzzleGenerator.generate(n,
        checkpointCount: cpCount, seed: widget.level * 7919 + 13);
    widget.controller.showHint = () => _gridKey.currentState?.revealNextCell();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ZipPuzzleGrid(
            key: _gridKey,
            puzzle: _puzzle,
            onSolved: (path) {
              widget.controller.solvedPreviewBuilder = (_) => SolvedGridPreview(
                n: _puzzle.n,
                path: path,
                checkpoints: _puzzle.checkpointOf,
              );
              widget.controller.reportSolved();
            },
          ),
        ),
        const SizedBox(height: 8),
        GameButton(
          height: 42,
          radius: 12,
          style: GameButtonStyle.orange,
          onTap: () {
            _gridKey.currentState?.reset();
            widget.controller.reportReset();
          },
          child: const StrokedText('CLEAN', size: 16, stroke: AppColors.orangeDark),
        ),
      ],
    );
  }
}
