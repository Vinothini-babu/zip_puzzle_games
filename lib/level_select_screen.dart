// level_select_screen.dart
// Level select grid - locked/unlocked levels, checkmark on completed ones,
// coin balance shown at top. Styled after the reference app: curved
// header, staggered tile entrance, tap-scale bounce, a pulsing highlight
// on the next playable level, and a bottom bar with Shop / Free Coins.

import 'package:flutter/material.dart';
import 'app_state.dart';
import 'level_data.dart';
import 'puzzle_screen.dart';
import 'shop_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with TickerProviderStateMixin {
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color darkTeal = Color(0xFF004D40);

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _difficultyColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return const Color(0xFF00796B);
      case Difficulty.medium:
        return const Color(0xFF00695C);
      case Difficulty.hard:
        return const Color(0xFF004D40);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _CurvedHeader(pulseController: _pulseController),
            Expanded(
              child: ListenableBuilder(
                listenable: AppState.instance,
                builder: (context, _) {
                  // The "next playable" level: unlocked but not yet
                  // completed - this is the one we draw the eye to.
                  final nextPlayableId = LevelCatalog.levels
                      .firstWhere(
                        (l) =>
                    AppState.instance.isUnlocked(l.id) &&
                        !AppState.instance.isCompleted(l.id),
                    orElse: () => LevelCatalog.levels.first,
                  )
                      .id;

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: LevelCatalog.levels.length,
                    itemBuilder: (context, index) {
                      final level = LevelCatalog.levels[index];
                      final unlocked = AppState.instance.isUnlocked(level.id);
                      final completed = AppState.instance.isCompleted(level.id);
                      final isNextPlayable =
                          unlocked && !completed && level.id == nextPlayableId;

                      final start = (index * 0.06).clamp(0.0, 0.7);
                      final end = (start + 0.4).clamp(0.0, 1.0);
                      final animation = CurvedAnimation(
                        parent: _entranceController,
                        curve: Interval(start, end, curve: Curves.easeOutCubic),
                      );

                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: animation.value,
                            child: Transform.translate(
                              offset: Offset(0, 24 * (1 - animation.value)),
                              child: child,
                            ),
                          );
                        },
                        child: _LevelTile(
                          level: level,
                          unlocked: unlocked,
                          completed: completed,
                          highlight: isNextPlayable,
                          pulseController: _pulseController,
                          color: _difficultyColor(level.difficulty),
                          onTap: unlocked
                              ? () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PuzzleScreen(level: level),
                              ),
                            );
                          }
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _BottomBar(),
          ],
        ),
      ),
    );
  }
}

/// Header with a curved (wave) bottom edge, coin balance, and title -
/// echoes the reference app's pink header shape, in the app's teal theme.
class _CurvedHeader extends StatelessWidget {
  final AnimationController pulseController;
  const _CurvedHeader({required this.pulseController});

  static const Color primaryTeal = Color(0xFF00796B);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        color: primaryTeal,
        child: Column(
          children: [
            Row(
              children: [
                ListenableBuilder(
                  listenable: AppState.instance,
                  builder: (context, _) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('${AppState.instance.coins}',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.share, color: Colors.white70, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'ZIP PUZZLE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 24);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height - 12);
    path.quadraticBezierTo(
        size.width * 0.75, size.height - 24, size.width, size.height - 4);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BottomBar extends StatelessWidget {
  static const Color primaryTeal = Color(0xFF00796B);

  void _openShop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    );
  }

  void _claimFreeCoins(BuildContext context) {
    // Simple demo reward - simulates a "watch ad" bonus by crediting
    // coins directly. Swap this for a real rewarded-ad SDK call later.
    const reward = 20;
    AppState.instance.addBonusCoins(reward);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You earned $reward free coins! 🎉')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _PillButton(
              icon: Icons.storefront,
              label: 'SHOP',
              color: const Color(0xFF29B6F6),
              onTap: () => _openShop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PillButton(
              icon: Icons.smart_display,
              label: 'FREE COINS',
              color: const Color(0xFFFFC107),
              onTap: () => _claimFreeCoins(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(widget.label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatefulWidget {
  final LevelData level;
  final bool unlocked;
  final bool completed;
  final bool highlight;
  final AnimationController pulseController;
  final Color color;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.level,
    required this.unlocked,
    required this.completed,
    required this.highlight,
    required this.pulseController,
    required this.color,
    required this.onTap,
  });

  @override
  State<_LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<_LevelTile> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    if (widget.onTap == null) return;
    setState(() => _scale = pressed ? 0.93 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.unlocked ? widget.color : Colors.grey.shade300;
    final textColor = widget.unlocked ? Colors.white : Colors.grey.shade600;

    Widget tile = Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      elevation: widget.unlocked ? 2 : 0,
      child: Stack(
        children: [
          Center(
            child: Text(
              widget.level.id.toString().padLeft(2, '0'),
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!widget.unlocked)
            const Positioned(
              right: 10,
              top: 10,
              child: Icon(Icons.lock, color: Colors.white70, size: 18),
            ),
          if (widget.completed)
            Positioned(
              right: 8,
              top: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.check, color: Colors.green, size: 14),
                ),
              ),
            ),
          Positioned(
            left: 10,
            bottom: 8,
            child: Text(
              widget.level.difficultyLabel,
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );

    // Pulsing glow ring around the level the player should play next -
    // draws the eye without being distracting on the rest of the grid.
    if (widget.highlight) {
      tile = AnimatedBuilder(
        animation: widget.pulseController,
        builder: (context, child) {
          final t = widget.pulseController.value;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.25 + 0.25 * t),
                  blurRadius: 6 + 10 * t,
                  spreadRadius: 1 + 2 * t,
                ),
              ],
            ),
            child: child,
          );
        },
        child: tile,
      );
    }

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: tile,
      ),
    );
  }
}