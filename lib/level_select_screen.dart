// level_select_screen.dart
// Level select grid - locked/unlocked levels, checkmark on completed ones,
// coin balance shown at top. Styled after the reference app's level grid.
//
// Animations:
// - Tiles fade + slide up in a staggered sequence when the screen opens
// - Each tile does a small scale-bounce on tap press

import 'package:flutter/material.dart';
import 'app_state.dart';
import 'level_data.dart';
import 'puzzle_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryTeal = Color(0xFF00796B);

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Color _difficultyColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return const Color(0xFF00796B); // teal 700
      case Difficulty.medium:
        return const Color(0xFF00695C); // teal 800
      case Difficulty.hard:
        return const Color(0xFF004D40); // teal 900
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Zip Puzzle'),
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        actions: [
          ListenableBuilder(
            listenable: AppState.instance,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${AppState.instance.coins}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
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

              // Stagger: each tile's animation window starts a little
              // later than the one before it, so they cascade in.
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
    );
  }
}

class _LevelTile extends StatefulWidget {
  final LevelData level;
  final bool unlocked;
  final bool completed;
  final Color color;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.level,
    required this.unlocked,
    required this.completed,
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

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
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
        ),
      ),
    );
  }
}