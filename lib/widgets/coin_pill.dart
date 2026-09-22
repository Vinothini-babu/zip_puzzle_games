import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE97A), AppColors.coin],
        ),
        border: Border.all(color: AppColors.coinDark, width: size * 0.09),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Text('\$',
          style: AppText.display(size * 0.58, color: AppColors.coinDark)),
    );
  }
}

/// Coin counter with a small green "+" (like the reference top bar).
class CoinPill extends StatelessWidget {
  const CoinPill({super.key, required this.coins, this.onAdd});
  final int coins;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: SizedBox(
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 6, bottom: 6),
              child: Container(
                height: 28,
                padding: const EdgeInsets.only(left: 24, right: 12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.orange, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: coins.toDouble()),
                      duration: const Duration(milliseconds: 600),
                      builder: (_, v, __) => Text('${v.round()}',
                          style: AppText.display(16, color: AppColors.brown)),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(left: 0, top: 2, child: CoinIcon(size: 36)),
            if (onAdd != null)
              Positioned(
                left: 20,
                bottom: -1,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.greenDark, width: 1.5),
                  ),
                  child: const Icon(Icons.add, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
