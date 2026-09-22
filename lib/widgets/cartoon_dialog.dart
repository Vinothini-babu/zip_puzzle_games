import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'game_button.dart';
import 'stroked_text.dart';

Future<T?> showCartoonDialog<T>(
    BuildContext context, {
      required WidgetBuilder builder,
      bool dismissible = true,
    }) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'dialog',
    barrierColor: Colors.black.withOpacity(0.68),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) => builder(ctx),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
    ),
  );
}

/// Orange frame + cream dashed panel + red ribbon title + X button.
class CartoonDialog extends StatelessWidget {
  const CartoonDialog({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.below,
    this.ribbon = AppColors.red,
    this.ribbonDark = AppColors.redDark,
    this.maxWidth = 340,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final Widget? below;
  final Color ribbon;
  final Color ribbonDark;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: _panel()),
                    Positioned(top: 0, left: 14, right: 0, child: _header()),
                  ],
                ),
                if (below != null) ...[const SizedBox(height: 14), below!],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(ribbon, Colors.white, 0.25)!, ribbon],
              ),
              boxShadow: [BoxShadow(color: ribbonDark, offset: const Offset(0, 4))],
            ),
            child: StrokedText(title, size: 21, stroke: ribbonDark),
          ),
        ),
        if (onClose != null) ...[
          const SizedBox(width: 6),
          GameButton(
            width: 42,
            height: 38,
            radius: 12,
            style: GameButtonStyle.red,
            padding: EdgeInsets.zero,
            onTap: onClose,
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
          ),
        ],
      ],
    );
  }

  Widget _panel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.orangeLight, AppColors.orange],
        ),
        boxShadow: const [
          BoxShadow(color: AppColors.orangeDark, offset: Offset(0, 6)),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: const DashedBorderPainter(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({this.color = AppColors.orangeLight, this.radius = 14});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(7, 7, size.width - 14, size.height - 14);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 8), paint);
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
