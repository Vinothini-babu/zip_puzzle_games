import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../core/routes.dart';
import '../widgets/coin_pill.dart';
import '../widgets/flower_background.dart';
import '../widgets/game_button.dart';
import '../widgets/stroked_text.dart';
import 'puzzle_screen.dart';
import 'shop_screen.dart';

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  static const _ribbonByLabel = {
    'EASY': [AppColors.green, AppColors.greenDark],
    'MEDIUM': [AppColors.orange, AppColors.orangeDark],
    'HARD': [AppColors.red, AppColors.redDark],
  };

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    const per = GameState.levelsPerChapter;

    return Scaffold(
      body: FlowerBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: gs,
            builder: (context, _) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      GameButton(
                        width: 44,
                        height: 40,
                        radius: 12,
                        style: GameButtonStyle.orange,
                        padding: EdgeInsets.zero,
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const Spacer(),
                      const StrokedText('LEVELS', size: 28),
                      const Spacer(),
                      CoinPill(
                        coins: gs.coins,
                        onAdd: () => Navigator.push(
                            context, fadeRoute(const ShopScreen())),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(builder: (context, cons) {
                    // one chapter = one row, so columns == levels per chapter
                    final tile =
                    ((cons.maxWidth - 32 - 12 * (per - 1)) / per)
                        .floorToDouble();
                    // itemCount is left unbounded (null) — levels are
                    // endless, so chapters are built lazily as the
                    // player scrolls down, forever.
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemBuilder: (context, chapterIndex) {
                        final first = chapterIndex * per + 1;
                        final last = first + per - 1;
                        final label = GameState.difficultyOf(first);
                        final colors = _ribbonByLabel[label]!;
                        final nFirst = GameState.gridSizeForLevel(first);
                        final nLast = GameState.gridSizeForLevel(last);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors[0],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: colors[1],
                                        offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: StrokedText(
                                    '$label  (${nFirst}x$nFirst'
                                        '${nFirst == nLast ? '' : '-${nLast}x$nLast'})',
                                    size: 16, stroke: colors[1]),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  for (int l = first; l <= last; l++)
                                    _LevelTile(level: l, size: tile, gs: gs),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.size, required this.gs});
  final int level;
  final double size;
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final solved = level <= gs.solvedLevels;
    final open = level <= gs.unlockedLevel;
    final style = !open
        ? GameButtonStyle.grey
        : solved
        ? GameButtonStyle.green
        : GameButtonStyle.orange;
    final dark = solved ? AppColors.greenDark : AppColors.orangeDark;

    return GameButton(
      width: size,
      height: size - 6,
      radius: 16,
      style: style,
      padding: EdgeInsets.zero,
      onTap: open
          ? () => Navigator.push(
          context, fadeRoute(PuzzleScreen(level: level)))
          : null,
      child: open
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StrokedText('$level', size: 26, stroke: dark),
          if (solved)
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 16),
        ],
      )
          : const Icon(Icons.lock_rounded, color: Colors.white70, size: 28),
    );
  }
}