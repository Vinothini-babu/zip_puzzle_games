// level_complete_screen.dart
// Congratulations screen shown after solving a level.
// Design matches the reference "ZIP" app: stylized logo, level number,
// "Congratulations!" heading, the completed grid shown with its solved
// path, coins earned, and COLLECT / BONUS X3 buttons to continue.

import 'package:flutter/material.dart';
import 'app_state.dart';
import 'level_data.dart';
import 'level_select_screen.dart';
import 'puzzle_screen.dart';
import 'solved_grid_preview.dart';
import 'zip_puzzle_generator.dart';

class LevelCompleteScreen extends StatefulWidget {
  final LevelData level;
  final int coinsEarned;
  final PuzzlePuzzleData puzzle;

  const LevelCompleteScreen({
    super.key,
    required this.level,
    required this.coinsEarned,
    required this.puzzle,
  });

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen> {
  static const Color background = Color(0xFF004D40); // teal 900
  static const Color primaryTeal = Color(0xFF00796B);

  bool _claimed = false;

  void _goNext() {
    final hasNextLevel = widget.level.id < LevelCatalog.levels.length;
    if (hasNextLevel) {
      final nextLevel = LevelCatalog.byId(widget.level.id + 1);
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

  void _collect() {
    if (_claimed) return;
    _claimed = true;
    _goNext();
  }

  void _collectBonus() {
    if (_claimed) return;
    _claimed = true;
    // "BONUS X3" - awards 2x more on top of the coins already credited
    // when the level was completed, matching the reference app's offer.
    AppState.instance.addBonusCoins(widget.coinsEarned * 2);
    _goNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
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
                ListenableBuilder(
                  listenable: AppState.instance,
                  builder: (context, _) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text('${AppState.instance.coins}',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Stylized "ZIP" logo - bold letters with small accent dots,
            // matching the reference app's title treatment.
            const _ZipLogo(),
            const SizedBox(height: 20),
            Text(
              'Level #${widget.level.id}',
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white38),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('+${widget.coinsEarned}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(width: 6),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SolvedGridPreview(puzzle: widget.puzzle, size: 230),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  // COLLECT - claims the base reward already earned.
                  Expanded(
                    child: _RewardButton(
                      label: 'COLLECT',
                      subLabel: '${widget.coinsEarned}',
                      background: Colors.white,
                      foreground: primaryTeal,
                      onTap: _collect,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // BONUS X3 - claims triple the reward instead.
                  Expanded(
                    child: _RewardButton(
                      label: 'BONUS X3',
                      subLabel: '${widget.coinsEarned * 3}',
                      background: Colors.black,
                      foreground: Colors.white,
                      trailingIcon: Icons.smart_display,
                      onTap: _collectBonus,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZipLogo extends StatelessWidget {
  const _ZipLogo();

  static const Color teal = Color(0xFF00796B);
  static const Color accent = Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'ZIP',
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 4),
              ],
            ),
          ),
          // small accent dots above the letters, like the reference logo
          Positioned(
            top: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                    (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardButton extends StatefulWidget {
  final String label;
  final String subLabel;
  final Color background;
  final Color foreground;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  const _RewardButton({
    required this.label,
    required this.subLabel,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  State<_RewardButton> createState() => _RewardButtonState();
}

class _RewardButtonState extends State<_RewardButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              Text(widget.label,
                  style: TextStyle(
                      color: widget.foreground,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.subLabel,
                      style: TextStyle(color: widget.foreground, fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  if (widget.trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(widget.trailingIcon, color: widget.foreground, size: 14),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}