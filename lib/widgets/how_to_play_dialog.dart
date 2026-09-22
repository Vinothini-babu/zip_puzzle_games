import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'cartoon_dialog.dart';
import 'game_button.dart';
import 'stroked_text.dart';

/// Shown automatically the first time the player ever opens Level 1,
/// and re-openable any time from the HOW TO PLAY button on Level 1.
Future<void> showHowToPlayDialog(BuildContext context) {
  return showCartoonDialog<void>(
    context,
    builder: (ctx) => CartoonDialog(
      title: 'HOW TO PLAY',
      ribbon: AppColors.teal,
      ribbonDark: AppColors.tealDark,
      onClose: () => Navigator.pop(ctx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _step(Icons.touch_app_rounded, 'Touch checkpoint 1 and hold.'),
          _step(Icons.gesture_rounded, 'Drag through cells one by one — do not lift your finger.'),
          _step(Icons.looks_two_rounded, 'Cross checkpoints 1, 2, 3... in order.'),
          _step(Icons.grid_view_rounded, 'Fill the whole board to solve the level!'),
          const SizedBox(height: 16),
          GameButton(
            width: 150,
            height: 50,
            onTap: () => Navigator.pop(ctx),
            child: const StrokedText('GOT IT', size: 20, stroke: AppColors.greenDark),
          ),
        ],
      ),
    ),
  );
}

Widget _step(IconData icon, String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: AppText.display(13, color: AppColors.brown))),
    ],
  ),
);
