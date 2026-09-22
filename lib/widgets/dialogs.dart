import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import 'cartoon_dialog.dart';
import 'coin_pill.dart';
import 'game_button.dart';
import 'stroked_text.dart';

enum OutOfMovesAction { coins, ad, premium, restart }

/// "ARE YOU SURE?  RESTART THIS LEVEL?"  -> true when the player restarts.
Future<bool> showRestartConfirm(BuildContext context) async {
  final res = await showCartoonDialog<bool>(
    context,
    builder: (ctx) => CartoonDialog(
      title: 'ARE YOU SURE?',
      onClose: () => Navigator.pop(ctx, false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 130,
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.creamDark.withOpacity(0.55),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(Icons.heart_broken_rounded,
                size: 96, color: Color(0xFFF0555F)),
          ),
          const SizedBox(height: 14),
          Text('RESTART THIS LEVEL?',
              style: AppText.display(15, color: AppColors.brown)),
          const SizedBox(height: 14),
          GameButton(
            width: 120,
            height: 50,
            onTap: () => Navigator.pop(ctx, false),
            child: const StrokedText('NO', size: 26, stroke: AppColors.greenDark),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('RESTART',
                style: AppText.display(16, color: AppColors.brown)),
          ),
        ],
      ),
    ),
  );
  return res ?? false;
}

/// "OUT OF MOVES" dialog with coin / ad / premium offer.
Future<OutOfMovesAction?> showOutOfMovesDialog(BuildContext context) {
  return showCartoonDialog<OutOfMovesAction>(
    context,
    dismissible: false,
    builder: (ctx) => CartoonDialog(
      title: 'OUT OF MOVES',
      onClose: () => Navigator.pop(ctx),
      below: _MovesOfferBanner(
          onTap: () => Navigator.pop(ctx, OutOfMovesAction.premium)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 130,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.orangeLight, AppColors.orange],
              ),
              boxShadow: const [
                BoxShadow(color: AppColors.orangeDark, offset: Offset(0, 5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StrokedText('MOVES', size: 22, stroke: AppColors.orangeDark),
                Text('0', style: AppText.display(44, color: AppColors.brown, height: 1)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('GET UNLIMITED MOVES ON\nTHE CURRENT LEVEL',
              textAlign: TextAlign.center,
              style: AppText.display(14, color: AppColors.brown)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  width: double.infinity,
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: () => Navigator.pop(ctx, OutOfMovesAction.coins),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoinIcon(size: 24),
                      const SizedBox(width: 6),
                      StrokedText('${AppInfo.unlimitedMovesCost}',
                          size: 22, stroke: AppColors.greenDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  width: double.infinity,
                  height: 52,
                  style: GameButtonStyle.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: () => Navigator.pop(ctx, OutOfMovesAction.ad),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StrokedText('GET', size: 22, stroke: AppColors.purpleDark),
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
            ],
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(ctx, OutOfMovesAction.restart),
            child: Text('RESTART', style: AppText.display(16, color: AppColors.brown)),
          ),
        ],
      ),
    ),
  );
}

class _MovesOfferBanner extends StatelessWidget {
  const _MovesOfferBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.fromLTRB(14, 26, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE2E4FF), Color(0xFFB9BDFF)],
            ),
            border: Border.all(color: AppColors.purple, width: 3),
          ),
          child: Row(
            children: [
              const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.favorite_rounded, size: 84, color: Color(0xFFF0555F)),
                  Icon(Icons.all_inclusive_rounded, size: 40, color: Colors.white),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    Text('ENJOY UNLIMITED\nMOVES FOREVER!',
                        textAlign: TextAlign.center,
                        style: AppText.display(13, color: AppColors.purpleDark)),
                    const SizedBox(height: 8),
                    GameButton(
                      height: 40,
                      radius: 12,
                      onTap: onTap,
                      child: StrokedText(AppInfo.premiumPrice,
                          size: 18, stroke: AppColors.greenDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: AppColors.tealDark, offset: Offset(0, 3)),
              ],
            ),
            child: const StrokedText('MOVES OFFER', size: 16, stroke: AppColors.tealDark),
          ),
        ),
        Positioned(
          top: 30,
          left: -6,
          child: Transform.rotate(
            angle: -0.6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              color: AppColors.redDark,
              child: Text('POPULAR', style: AppText.display(10)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple "message + OK" dialog (purchase done, not enough coins, ...).
Future<void> showMessageDialog(
    BuildContext context, {
      required String title,
      required String message,
      Color ribbon = AppColors.green,
      Color ribbonDark = AppColors.greenDark,
    }) {
  return showCartoonDialog<void>(
    context,
    builder: (ctx) => CartoonDialog(
      title: title,
      ribbon: ribbon,
      ribbonDark: ribbonDark,
      onClose: () => Navigator.pop(ctx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message,
              textAlign: TextAlign.center,
              style: AppText.display(16, color: AppColors.brown)),
          const SizedBox(height: 16),
          GameButton(
            width: 130,
            height: 50,
            onTap: () => Navigator.pop(ctx),
            child: const StrokedText('OK', size: 24, stroke: AppColors.greenDark),
          ),
        ],
      ),
    ),
  );
}

Future<void> showSettingsDialog(BuildContext context) {
  final gs = GameState.instance;
  return showCartoonDialog<void>(
    context,
    builder: (ctx) => CartoonDialog(
      title: 'SETTINGS',
      ribbon: AppColors.teal,
      ribbonDark: AppColors.tealDark,
      onClose: () => Navigator.pop(ctx),
      child: ListenableBuilder(
        listenable: gs,
        builder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleRow(
                label: 'SOUND',
                icon: Icons.volume_up_rounded,
                value: gs.sound,
                onChanged: gs.setSound),
            const SizedBox(height: 10),
            _ToggleRow(
                label: 'VIBRATION',
                icon: Icons.vibration_rounded,
                value: gs.vibration,
                onChanged: gs.setVibration),
            const SizedBox(height: 14),
            Text('${AppInfo.gameName}  v${AppInfo.version}',
                style: AppText.display(12, color: AppColors.brown.withOpacity(0.7))),
          ],
        ),
      ),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.creamDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brown),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label, style: AppText.display(16, color: AppColors.brown))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.green,
          ),
        ],
      ),
    );
  }
}
