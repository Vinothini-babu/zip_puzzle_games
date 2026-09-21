import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';

/// Chunky outlined cartoon text (fill + dark outline + drop shadow).
class StrokedText extends StatelessWidget {
  const StrokedText(
      this.text, {
        super.key,
        this.size = 24,
        this.fill = Colors.white,
        this.stroke = AppColors.brownDark,
        this.strokeWidth,
        this.dropShadow = 3,
        this.align = TextAlign.center,
        this.height,
      });

  final String text;
  final double size;
  final Color fill;
  final Color stroke;
  final double? strokeWidth;
  final double dropShadow;
  final TextAlign align;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final sw = strokeWidth ?? size * 0.22;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeJoin = StrokeJoin.round
      ..color = stroke;

    TextStyle style({Paint? fg, Color? color}) => GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: height,
        foreground: fg,
        color: color);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (dropShadow > 0)
          Transform.translate(
            offset: Offset(0, dropShadow),
            child: Text(text, textAlign: align, style: style(fg: strokePaint)),
          ),
        Text(text, textAlign: align, style: style(fg: strokePaint)),
        Text(text, textAlign: align, style: style(color: fill)),
      ],
    );
  }
}
