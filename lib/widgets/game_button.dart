import 'package:flutter/material.dart';

import '../core/app_theme.dart';

enum GameButtonStyle { green, red, purple, orange, grey }

/// Glossy 3D candy button with a press-down animation.
/// Pass `width: double.infinity` only when inside an Expanded / tight width.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.child,
    this.onTap,
    this.style = GameButtonStyle.green,
    this.width,
    this.height = 56,
    this.radius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
  });

  final Widget child;
  final VoidCallback? onTap;
  final GameButtonStyle style;
  final double? width;
  final double height;
  final double radius;
  final EdgeInsets padding;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  static const double _lip = 6;
  bool _down = false;

  /// [light, main, dark]
  List<Color> get _colors {
    if (widget.onTap == null) {
      return const [Color(0xFFCFCFCF), Color(0xFFAAAAAA), Color(0xFF7C7C7C)];
    }
    switch (widget.style) {
      case GameButtonStyle.green:
        return const [Color(0xFFA5F26E), AppColors.green, AppColors.greenDark];
      case GameButtonStyle.red:
        return const [Color(0xFFFF9A8F), AppColors.red, AppColors.redDark];
      case GameButtonStyle.purple:
        return const [Color(0xFFC7BEFF), AppColors.purple, AppColors.purpleDark];
      case GameButtonStyle.orange:
        return const [
          AppColors.orangeLight,
          AppColors.orange,
          AppColors.orangeDark
        ];
      case GameButtonStyle.grey:
        return const [Color(0xFFCFCFCF), Color(0xFFAAAAAA), Color(0xFF7C7C7C)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final c = _colors;
    final radius = BorderRadius.circular(widget.radius);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled
          ? (_) {
        setState(() => _down = false);
        widget.onTap!();
      }
          : null,
      onTapCancel: () => setState(() => _down = false),
      child: Stack(
        children: [
          // dark base (the 3D lip)
          Positioned.fill(
            top: _lip,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c[2],
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 4)),
                ],
              ),
            ),
          ),
          // face
          AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            width: widget.width,
            height: widget.height,
            margin: EdgeInsets.only(
                top: _down ? _lip : 0, bottom: _down ? 0 : _lip),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c[0], c[1]],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 10,
                  right: 10,
                  top: 3,
                  height: widget.height * 0.28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(widget.height),
                    ),
                  ),
                ),
                Padding(padding: widget.padding, child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
