import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../core/routes.dart';
import '../widgets/flower_background.dart';
import '../widgets/game_button.dart';
import '../widgets/rope_progress_bar.dart';
import '../widgets/stroked_text.dart';
import '../widgets/zip_logo.dart';
import 'home_screen.dart';

/// 1) studio splash (green)  ->  2) game splash with rope loading bar  ->  Home
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _load = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3200));
  bool _showGame = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await Future.wait([
      GameState.instance.load(),
      Future.delayed(const Duration(milliseconds: 1700)),
    ]);
    if (!mounted) return;
    setState(() => _showGame = true);
    await _load.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));
  }

  @override
  void dispose() {
    _load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showGame ? _gameSplash() : _studioSplash(),
      ),
    );
  }

  Widget _studioSplash() {
    return Container(
      key: const ValueKey('studio'),
      color: const Color(0xFF00C566),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        builder: (_, v, child) => Opacity(opacity: v, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppInfo.studioName,
                textAlign: TextAlign.center,
                style: AppText.display(38, color: Colors.white.withOpacity(0.45))),
            const SizedBox(height: 14),
            Text('PRESENTS',
                style: AppText.display(18, color: Colors.white.withOpacity(0.45))),
          ],
        ),
      ),
    );
  }

  Widget _gameSplash() {
    return FlowerBackground(
      key: const ValueKey('game'),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 14,
              child: GameButton(
                height: 34,
                radius: 12,
                style: GameButtonStyle.orange,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onTap: () {},
                child: const StrokedText('SUPPORT',
                    size: 14, stroke: AppColors.orangeDark),
              ),
            ),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: const ZipLogo(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: AnimatedBuilder(
                animation: _load,
                builder: (_, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StrokedText('LOADING... ${(_load.value * 100).round()}%',
                        size: 16, fill: AppColors.cream),
                    const SizedBox(height: 8),
                    RopeProgressBar(progress: _load.value, width: 240),
                    const SizedBox(height: 18),
                    Text('v${AppInfo.version}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35), fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
