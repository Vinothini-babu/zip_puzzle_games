// how_to_play_dialog.dart
// "How to Play" popup shown when the player starts Level 1 for the first
// time. Styled after the reference app's tutorial card: two instructions,
// each with a small illustrative graphic.

import 'package:flutter/material.dart';

class HowToPlayDialog extends StatelessWidget {
  const HowToPlayDialog({super.key});

  static const Color primaryTeal = Color(0xFF00796B);

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const HowToPlayDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'HOW TO PLAY',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InstructionColumn(
                    graphic: const _ConnectNumbersGraphic(),
                    text: 'Connect all the\nnumbers in order',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InstructionColumn(
                    graphic: const _FillCellsGraphic(),
                    text: 'Fill every cell and\nend on the highest',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionColumn extends StatelessWidget {
  final Widget graphic;
  final String text;
  const _InstructionColumn({required this.graphic, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 64, child: Center(child: graphic)),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
        ),
      ],
    );
  }
}

/// Three connected numbered circles (1-2-3), matching the reference
/// app's "connect numbers in order" illustration.
class _ConnectNumbersGraphic extends StatelessWidget {
  const _ConnectNumbersGraphic();

  static const Color teal = Color(0xFF00796B);
  static const Color green = Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 40,
      child: CustomPaint(
        painter: _ConnectPainter(),
      ),
    );
  }
}

class _ConnectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _ConnectNumbersGraphic.teal
      ..strokeWidth = size.height * 0.7
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    final positions = [size.width * 0.18, size.width * 0.5, size.width * 0.82];

    canvas.drawLine(Offset(positions[0], y), Offset(positions[2], y), linePaint);

    for (int i = 0; i < positions.length; i++) {
      final fillPaint = Paint()..color = _ConnectNumbersGraphic.green;
      final borderPaint = Paint()
        ..color = _ConnectNumbersGraphic.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final radius = size.height * 0.42;
      canvas.drawCircle(Offset(positions[i], y), radius, fillPaint);
      canvas.drawCircle(Offset(positions[i], y), radius, borderPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(positions[i], y) - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectPainter oldDelegate) => false;
}

/// A zig-zag path inside a bordered box, matching the reference app's
/// "fill every cell" illustration.
class _FillCellsGraphic extends StatelessWidget {
  const _FillCellsGraphic();

  static const Color teal = Color(0xFF00796B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        border: Border.all(color: teal.withOpacity(0.4), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(painter: _ZigZagPainter()),
    );
  }
}

class _ZigZagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _FillCellsGraphic.teal
      ..strokeWidth = size.width * 0.16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.85);
    path.lineTo(size.width * 0.15, size.height * 0.35);
    path.lineTo(size.width * 0.5, size.height * 0.35);
    path.lineTo(size.width * 0.5, size.height * 0.65);
    path.lineTo(size.width * 0.85, size.height * 0.65);
    path.lineTo(size.width * 0.85, size.height * 0.15);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ZigZagPainter oldDelegate) => false;
}