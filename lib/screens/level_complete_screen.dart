import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/ad_service.dart';
import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../core/routes.dart';
import '../widgets/cartoon_dialog.dart';
import '../widgets/coin_pill.dart';
import '../widgets/flower_background.dart';
import '../widgets/game_button.dart';
import '../widgets/stroked_text.dart';
import 'home_screen.dart';

/// LEVEL N COMPLETED + swinging multiplier bar (x1.5 / x2 / x3 / x2 / x1.5).
/// Left button = plain reward, right button = reward x multiplier (rewarded ad).
class LevelCompleteScreen extends StatefulWidget {
  const LevelCompleteScreen({
    super.key,
    required this.level,
    required this.baseReward,
    required this.preview,
  });

  final int level;
  final int baseReward;
  final Widget preview;

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with SingleTickerProviderStateMixin {
  static const _mults = [1.5, 2.0, 3.0, 2.0, 1.5];
  static const _labels = ['x1.5', 'x2', 'x3', 'x2', 'x1.5'];
  static const _segColors = [
    Color(0xFFFF7A5C),
    Color(0xFFFFB347),
    Color(0xFF7BE04E),
    Color(0xFFFFB347),
    Color(0xFFFF7A5C),
  ];

  late final AnimationController _ptr = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat(reverse: true);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // mark solved after first frame (avoids notify during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GameState.instance.completeLevel(widget.level);
    });
  }

  @override
  void dispose() {
    _ptr.dispose();
    super.dispose();
  }

  double get _mult =>
      _mults[math.min(4, math.max(0, (_ptr.value * 5).floor()))];
  int get _bonus => (widget.baseReward * _mult).round();

  void _goHome() {
    Navigator.pushAndRemoveUntil(
        context, fadeRoute(const HomeScreen()), (r) => false);
  }

  void _collect() {
    if (_busy) return;
    _busy = true;
    GameState.instance.addCoins(widget.baseReward);
    _goHome();
  }

  Future<void> _watchAd() async {
    if (_busy) return;
    _busy = true;
    final amount = _bonus; // freeze the multiplier at tap time
    _ptr.stop();
    final ok = await AdService.showRewarded();
    if (!mounted) return;
    if (ok) {
      GameState.instance.addCoins(amount);
      _goHome();
    } else {
      _busy = false;
      _ptr.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlowerBackground(
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 110,
              child: CustomPaint(painter: _BuntingPainter()),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 78),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.3, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: Column(
                      children: [
                        StrokedText('LEVEL ${widget.level}',
                            size: 44, stroke: AppColors.brownDark),
                        StrokedText('COMPLETED',
                            size: 50,
                            fill: AppColors.orangeLight,
                            stroke: const Color(0xFF8A3A16),
                            height: 1.05),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(builder: (context, cons) {
                      final s = math.max(160.0,
                          math.min(cons.maxWidth - 56, cons.maxHeight - 10));
                      return Center(child: _Hoop(size: s, child: widget.preview));
                    }),
                  ),
                  _multiplierBar(),
                  const SizedBox(height: 18),
                  _buttons(),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _multiplierBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Row(
                children: [
                  for (int i = 0; i < 5; i++)
                    Expanded(
                      child: Container(
                        color: _segColors[i],
                        alignment: Alignment.center,
                        child: StrokedText(_labels[i],
                            size: 15,
                            stroke: Color.lerp(_segColors[i], Colors.black, 0.45)!,
                            dropShadow: 1.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _ptr,
            builder: (_, __) => Align(
              alignment: Alignment(_ptr.value * 2 - 1, 0),
              child: const Icon(Icons.arrow_drop_up_rounded,
                  size: 46, color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        children: [
          Expanded(
            child: GameButton(
              width: double.infinity,
              height: 58,
              onTap: _collect,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CoinIcon(size: 28),
                  const SizedBox(width: 6),
                  StrokedText('+${widget.baseReward}',
                      size: 26, stroke: AppColors.greenDark),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GameButton(
              width: double.infinity,
              height: 58,
              style: GameButtonStyle.purple,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onTap: _watchAd,
              child: AnimatedBuilder(
                animation: _ptr,
                builder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CoinIcon(size: 28),
                    const SizedBox(width: 6),
                    StrokedText('+$_bonus',
                        size: 26, stroke: AppColors.purpleDark),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.purpleDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Orange embroidery-hoop frame that holds the solved board.
class _Hoop extends StatelessWidget {
  const _Hoop({required this.size, required this.child});
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.035),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.orangeLight, AppColors.orangeDark],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 8)),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: const _StitchPainter(),
        child: Container(
          padding: EdgeInsets.all(size * 0.15),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFBF3E6),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StitchPainter extends CustomPainter {
  const _StitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 8;
    final path = Path()..addOval(Rect.fromCircle(center: size.center(Offset.zero), radius: r));
    final paint = Paint()
      ..color = const Color(0xFFD9C7A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BuntingPainter extends CustomPainter {
  const _BuntingPainter();

  static const _flags = [
    Color(0xFF4DB6FF),
    Color(0xFFB57BFF),
    Color(0xFFFFA23E),
    Color(0xFF7BE04E),
    Color(0xFFFF6B9A),
    Color(0xFFFFD84D),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p0 = Offset(-10, 6);
    final c = Offset(size.width / 2, 62);
    final p2 = Offset(size.width + 10, 6);
    Offset at(double t) {
      final u = 1 - t;
      return Offset(
        u * u * p0.dx + 2 * u * t * c.dx + t * t * p2.dx,
        u * u * p0.dy + 2 * u * t * c.dy + t * t * p2.dy,
      );
    }

    final string = Path()..moveTo(p0.dx, p0.dy);
    string.quadraticBezierTo(c.dx, c.dy, p2.dx, p2.dy);
    canvas.drawPath(
        string,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.orangeLight);

    const count = 12;
    for (int i = 0; i < count; i++) {
      final t = (i + 0.7) / (count + 0.4);
      final p = at(t);
      final flag = Path()
        ..moveTo(p.dx - 14, p.dy)
        ..lineTo(p.dx + 14, p.dy)
        ..lineTo(p.dx, p.dy + 34)
        ..close();
      canvas.drawPath(flag, Paint()..color = _flags[i % _flags.length]);
      canvas.drawPath(
        flag,
        Paint()
          ..color = Colors.black.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
