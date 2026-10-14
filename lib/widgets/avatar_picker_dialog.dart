import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import 'cartoon_dialog.dart';
import 'game_button.dart';
import 'stroked_text.dart';

/// Toys + cute-animal emoji set the player can pick as their profile
/// avatar. Add or remove entries here to change the choices.
const List<String> kAvatarChoices = [
  '🐼', '🦊', '🐶', '🐱', '🦁', '🐯',
  '🐨', '🐰', '🦄', '🐵', '🐸', '🐻',
  '🧸', '🤖', '🚀', '🎮', '🎲', '🧩',
];

Future<void> showAvatarPickerDialog(BuildContext context) {
  final gs = GameState.instance;
  return showCartoonDialog<void>(
    context,
    builder: (ctx) => CartoonDialog(
      title: 'CHOOSE AVATAR',
      ribbon: AppColors.purple,
      ribbonDark: AppColors.purpleDark,
      onClose: () => Navigator.pop(ctx),
      child: ListenableBuilder(
        listenable: gs,
        builder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kAvatarChoices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, i) {
                final emoji = kAvatarChoices[i];
                final selected = emoji == gs.avatarEmoji;
                return GestureDetector(
                  onTap: () {
                    if (gs.vibration) HapticFeedback.selectionClick();
                    gs.setAvatar(emoji);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.purple.withOpacity(0.35)
                          : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.purpleDark : AppColors.creamDark,
                        width: selected ? 3 : 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            GameButton(
              width: 140,
              height: 50,
              onTap: () => Navigator.pop(ctx),
              child: const StrokedText('OK', size: 24, stroke: AppColors.greenDark),
            ),
          ],
        ),
      ),
    ),
  );
}