import 'package:flutter/material.dart';

import '../core/ad_service.dart';
import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../core/upi_payment.dart';
import '../widgets/coin_pill.dart';
import '../widgets/dialogs.dart';
import '../widgets/flower_background.dart';
import '../widgets/game_button.dart';
import '../widgets/stroked_text.dart';

/// Buy buttons open a real UPI payment intent (GPay/PhonePe/etc). See
/// core/upi_payment.dart for what still needs a backend before this can
/// safely handle real money.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const List<(int, String, num, String?)> _packs = [
    (500, '₹79', 79, null),
    (1200, '₹149', 149, 'POPULAR'),
    (3000, '₹349', 349, 'BEST VALUE'),
    (7500, '₹799', 799, null),
  ];

  Future<void> _buyCoins(BuildContext context, int coins, num rupees) async {
    final opened = await UpiPayment.launch(
        amountRupees: rupees, note: '$coins coins - ${AppInfo.gameName}');
    if (!context.mounted) return;
    if (!opened) {
      // No UPI app found (very common on an emulator) — fall back to a
      // demo credit so testing isn't blocked.
      GameState.instance.addCoins(coins);
      await showMessageDialog(context,
          title: 'NO UPI APP FOUND',
          message: 'Credited $coins coins for testing instead.',
          ribbon: AppColors.purple,
          ribbonDark: AppColors.purpleDark);
      return;
    }
    // We opened GPay/PhonePe for real, but without a backend we can't
    // verify the payment actually completed — see the warning in
    // core/upi_payment.dart before using this for real money.
    GameState.instance.addCoins(coins);
    await showMessageDialog(context, title: 'YAY!', message: 'You got $coins coins!');
  }

  Future<void> _buyPremium(BuildContext context) async {
    final opened = await UpiPayment.launch(
        amountRupees: 1150, note: 'Premium - ${AppInfo.gameName}');
    if (!context.mounted) return;
    if (!opened) {
      GameState.instance.buyPremium();
      GameState.instance.addCoins(500);
      await showMessageDialog(context,
          title: 'NO UPI APP FOUND',
          message: 'Activated Premium for testing instead.',
          ribbon: AppColors.purple,
          ribbonDark: AppColors.purpleDark);
      return;
    }
    GameState.instance.buyPremium();
    GameState.instance.addCoins(500);
    await showMessageDialog(context,
        title: 'PREMIUM ON', message: 'No ads, unlimited moves and 500 coins!');
  }

  Future<void> _freeCoins(BuildContext context) async {
    final ok = await AdService.showRewarded();
    if (!ok || !context.mounted) return;
    GameState.instance.addCoins(50);
    await showMessageDialog(context, title: 'NICE!', message: 'You earned 50 free coins.');
  }

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    return Scaffold(
      body: FlowerBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: gs,
            builder: (context, _) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      GameButton(
                        width: 44,
                        height: 40,
                        radius: 12,
                        style: GameButtonStyle.orange,
                        padding: EdgeInsets.zero,
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const Spacer(),
                      const StrokedText('SHOP', size: 30),
                      const Spacer(),
                      CoinPill(coins: gs.coins),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _premiumCard(context, gs),
                      const SizedBox(height: 16),
                      _card(
                        child: Row(
                          children: [
                            const CoinIcon(size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('FREE COINS',
                                  style: AppText.display(20, color: AppColors.brown)),
                            ),
                            GameButton(
                              height: 46,
                              radius: 14,
                              style: GameButtonStyle.purple,
                              onTap: () => _freeCoins(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const StrokedText('+50',
                                      size: 20, stroke: AppColors.purpleDark),
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
                          ],
                        ),
                      ),
                      for (final p in _packs) ...[
                        const SizedBox(height: 16),
                        _packCard(context, p.$1, p.$2, p.$3, p.$4),
                      ],
                      const SizedBox(height: 18),
                      Center(
                        child: Text('Opens GPay/PhonePe for payment — see upi_payment.dart',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4), fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.cream,
        border: Border.all(color: AppColors.orange, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.orangeDark, offset: Offset(0, 5))],
      ),
      child: child,
    );
  }

  Widget _packCard(BuildContext context, int coins, String price, num rupees, String? tag) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _card(
          child: Row(
            children: [
              const CoinIcon(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StrokedText('$coins', size: 30, stroke: AppColors.orangeDark),
                ),
              ),
              GameButton(
                width: 100,
                height: 46,
                radius: 14,
                onTap: () => _buyCoins(context, coins, rupees),
                child: StrokedText(price, size: 20, stroke: AppColors.greenDark),
              ),
            ],
          ),
        ),
        if (tag != null)
          Positioned(
            top: -10,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: AppColors.tealDark, offset: Offset(0, 3))],
              ),
              child: Text(tag, style: AppText.display(11)),
            ),
          ),
      ],
    );
  }

  Widget _premiumCard(BuildContext context, GameState gs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE2E4FF), Color(0xFFB9BDFF)],
        ),
        border: Border.all(color: AppColors.purple, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.purpleDark, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.favorite_rounded, size: 92, color: Color(0xFFF0555F)),
              Icon(Icons.all_inclusive_rounded, size: 44, color: Colors.white),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StrokedText('PREMIUM', size: 26, stroke: AppColors.purpleDark),
                const SizedBox(height: 4),
                Text('No ads\nUnlimited moves\n+500 coins',
                    style: AppText.display(13, color: AppColors.purpleDark)),
                const SizedBox(height: 10),
                GameButton(
                  height: 44,
                  radius: 14,
                  onTap: gs.premium ? null : () => _buyPremium(context),
                  child: StrokedText(gs.premium ? 'OWNED' : AppInfo.premiumPrice,
                      size: 18, stroke: AppColors.greenDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}