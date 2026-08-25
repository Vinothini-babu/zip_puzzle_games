// level_complete_screen.dart
// Congratulations screen shown after solving a level.
// Fully animated entrance: logo and text fade/slide in in sequence, the
// solved path traces itself onto the mini grid, the coin count animates
// up from 0, and the reward buttons pop in last.

import 'package:flutter/material.dart';
import 'app_state.dart';
import 'level_data.dart';
import 'level_select_screen.dart';
import 'puzzle_screen.dart';
import 'solved_grid_preview.dart';
import 'zip_puzzle_generator.dart';
import 'share_helper.dart';

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

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  static const Color background = Color(0xFF004D40);
  static const Color primaryTeal = Color(0xFF00796B);

  bool _claimed = false;

  // One long entrance timeline, sliced into intervals for each element -
  // keeps every piece perfectly in sync without juggling many controllers.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final Animation<double> _logoAnim =
  CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.18, curve: Curves.easeOut));
  late final Animation<double> _headingAnim =
  CurvedAnimation(parent: _entrance, curve: const Interval(0.12, 0.32, curve: Curves.easeOut));
  late final Animation<double> _coinBadgeAnim = CurvedAnimation(
      parent: _entrance, curve: const Interval(0.28, 0.46, curve: Curves.easeOutBack));
  late final Animation<double> _gridDrawAnim = CurvedAnimation(
      parent: _entrance, curve: const Interval(0.42, 0.85, curve: Curves.easeInOut));
  late final Animation<double> _buttonsAnim = CurvedAnimation(
      parent: _entrance, curve: const Interval(0.85, 1.0, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

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
    AppState.instance.addBonusCoins(widget.coinsEarned * 2);
    _goNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // soft decorative glow blobs for depth, like the reference app
          Positioned(top: 60, left: -40, child: _glowBlob(140)),
          Positioned(top: 300, right: -50, child: _glowBlob(160)),
          SafeArea(
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
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white70),
                      onPressed: () => ShareHelper.shareLevelComplete(
                        levelId: widget.level.id,
                        coinsEarned: widget.coinsEarned,
                      ),
                    ),
                    ListenableBuilder(
                      listenable: AppState.instance,
                      builder: (context, _) => Padding(
                        padding: const EdgeInsets.only(right: 16, left: 4),
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
                // Scrollable middle section - on shorter screens this
                // scrolls instead of pushing the reward buttons off-screen.
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _logoAnim,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, -0.3), end: Offset.zero)
                                .animate(_logoAnim),
                            child: const _ZipLogo(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _headingAnim,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, 0.2), end: Offset.zero)
                                .animate(_headingAnim),
                            child: Column(
                              children: [
                                Text('Level #${widget.level.id}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                const SizedBox(height: 8),
                                const Text('Congratulations!',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ScaleTransition(
                          scale: _coinBadgeAnim,
                          child: FadeTransition(
                            opacity: _coinBadgeAnim,
                            child: AnimatedBuilder(
                              animation: _coinBadgeAnim,
                              builder: (context, _) {
                                final shown =
                                (widget.coinsEarned * _coinBadgeAnim.value).round();
                                return Container(
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white38),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('+$shown',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _gridDrawAnim,
                          child: AnimatedBuilder(
                            animation: _gridDrawAnim,
                            builder: (context, _) => SolvedGridPreview(
                              puzzle: widget.puzzle,
                              size: 220,
                              progress: _gridDrawAnim.value,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                // Reward buttons - always pinned at the bottom, never
                // scrolled away or clipped by shorter screens.
                ScaleTransition(
                  scale: _buttonsAnim,
                  child: FadeTransition(
                    opacity: _buttonsAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                      child: Row(
                        children: [
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.04),
      ),
    );
  }
}

class _ZipLogo extends StatelessWidget {
  const _ZipLogo();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'ZIP',
      style: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 3,
        height: 1.0,
        shadows: [
          Shadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 4),
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
                      color: widget.foreground, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.subLabel, style: TextStyle(color: widget.foreground, fontSize: 13)),
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