import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../core/routes.dart';
import '../widgets/coin_pill.dart';
import '../widgets/dialogs.dart';
import '../widgets/flower_background.dart';
import '../widgets/game_button.dart';
import '../widgets/mini_board_preview.dart';
import '../widgets/stroked_text.dart';
import 'levels_screen.dart';
import 'puzzle_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    return Scaffold(
      body: FlowerBackground(
        child: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: gs,
            builder: (context, _) {
              final level = gs.unlockedLevel;
              final pct = (gs.chapterProgress(level) * 100).round();
              return Column(
                children: [
                  _TopBar(gs: gs),
                  if (!gs.premium)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, top: 6),
                        child: _OfferBadge(onTap: () => _openShop(context)),
                      ),
                    ),
                  Expanded(
                    child: LayoutBuilder(builder: (context, cons) {
                      final h = math.min(cons.maxHeight - 56, cons.maxWidth * 0.64 * 1.28);
                      final w = h / 1.28;
                      return Center(
                        child: _LevelCard(
                            width: w, height: h, level: level, percent: pct),
                      );
                    }),
                  ),
                  _PlayButton(level: level, percent: pct),
                  const SizedBox(height: 22),
                  const _BottomNav(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

void _openShop(BuildContext context) =>
    Navigator.push(context, fadeRoute(const ShopScreen()));

// ───────────────────────── top bar ─────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.gs});
  final GameState gs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      // Horizontal scroll = safety net so this row can never overflow off
      // the edge of narrow phone screens.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.orangeLight, AppColors.orangeDark],
                ),
              ),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text('🐼', style: TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 12),
            if (!gs.premium)
              GestureDetector(
                onTap: () => _openShop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFF8A80), AppColors.redDark],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text('ADS', style: AppText.display(12)),
                      Transform.rotate(
                        angle: -0.75,
                        child: Container(width: 38, height: 3, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 20),
            CoinPill(coins: gs.coins, onAdd: () => _openShop(context)),
            const SizedBox(width: 10),
            GameButton(
              width: 42,
              height: 38,
              radius: 12,
              style: GameButtonStyle.orange,
              padding: EdgeInsets.zero,
              onTap: () => showSettingsDialog(context),
              child: const Icon(Icons.settings_rounded, color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferBadge extends StatelessWidget {
  const _OfferBadge({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.favorite_rounded,
                  size: 60,
                  color: Color(0xFFF0555F),
                  shadows: [Shadow(color: AppColors.redDark, offset: Offset(0, 3))]),
              Icon(Icons.all_inclusive_rounded, size: 28, color: Colors.white),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE98CF0), AppColors.pink],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            ),
            child: Text('OFFER', style: AppText.display(12)),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── level card ─────────────────────────
class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.width,
    required this.height,
    required this.level,
    required this.percent,
  });
  final double width;
  final double height;
  final int level;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final n = 4 + GameState.chapterOf(level);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.orangeLight, AppColors.orangeDark],
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 26, 14, 30),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6E7D4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('LEVEL $level',
                        style: AppText.display(20, color: AppColors.brown)),
                    const SizedBox(height: 10),
                    Flexible(child: MiniBoardPreview(n: n)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -14,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.orange, width: 2),
                ),
                child: Text('$percent%',
                    style: AppText.display(13, color: AppColors.brown)),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GameButton(
                    height: 42,
                    radius: 14,
                    style: GameButtonStyle.orange,
                    onTap: () => Navigator.push(
                        context, fadeRoute(const LevelsScreen())),
                    child: StrokedText(GameState.difficultyOf(level),
                        size: 17, stroke: AppColors.orangeDark),
                  ),
                  if (percent == 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text('!', style: AppText.display(13)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── play button ─────────────────────────
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.level, required this.percent});
  final int level;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      width: 210,
      height: 100,
      radius: 26,
      onTap: () =>
          Navigator.push(context, fadeRoute(PuzzleScreen(level: level))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StrokedText('PLAY', size: 34, stroke: AppColors.greenDark),
          StrokedText('LEVEL $level',
              size: 17,
              fill: const Color(0xFFE6FFCB),
              stroke: AppColors.greenDark),
          const SizedBox(height: 4),
          Container(
            width: 86,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$percent%',
                style: AppText.display(11, color: AppColors.greenDark)),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── bottom nav ─────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 78,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _NavTab(
                  icon: Icons.shopping_cart_rounded,
                  onTap: () => _openShop(context),
                ),
              ),
              const Expanded(
                child: _NavTab(
                    icon: Icons.home_rounded, label: 'HOME', selected: true),
              ),
              Expanded(
                child: _NavTab(
                  icon: Icons.grid_view_rounded,
                  onTap: () =>
                      Navigator.push(context, fadeRoute(const LevelsScreen())),
                ),
              ),
            ],
          ),
        ),
        Container(height: 14 + bottom, color: const Color(0xFF7A3A2E)),
      ],
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.icon, this.label, this.selected = false, this.onTap});
  final IconData icon;
  final String? label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: selected ? 78 : 58,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFEFC9), AppColors.creamDark],
          ),
          border: Border.all(color: AppColors.orange, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: selected ? 36 : 30,
                color: selected ? const Color(0xFFE8683B) : AppColors.orangeDark),
            if (label != null)
              StrokedText(label!, size: 14, stroke: AppColors.orangeDark, dropShadow: 1.5),
          ],
        ),
      ),
    );
  }
}
