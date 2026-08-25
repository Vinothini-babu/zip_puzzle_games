// shop_screen.dart
// In-app shop: Premium (remove ads + coins) and coin packs, styled after
// the reference screenshot with elevated cards and entrance animation so
// the screen feels full and polished rather than sparse.

import 'package:flutter/material.dart';
import 'app_state.dart';

class CoinPack {
  final String label;
  final int coins;
  final String price;
  final String? badge;
  final IconData icon;
  const CoinPack({
    required this.label,
    required this.coins,
    required this.price,
    required this.icon,
    this.badge,
  });
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  static const Color shopBlue = Color(0xFF29B6F6);
  static const Color buyGreen = Color(0xFF43A047);

  static const List<CoinPack> packs = [
    CoinPack(label: '100 coins', coins: 100, price: '\$0.99', icon: Icons.monetization_on),
    CoinPack(
        label: '550 coins',
        coins: 550,
        price: '\$4.99',
        badge: 'MOST POP',
        icon: Icons.savings),
    CoinPack(
        label: '1200 coins',
        coins: 1200,
        price: '\$9.99',
        badge: 'ADS FREE',
        icon: Icons.card_giftcard),
    CoinPack(
        label: '3200 coins',
        coins: 3200,
        price: '\$24.99',
        badge: 'ADS FREE',
        icon: Icons.diamond),
    CoinPack(
        label: '13000 coins',
        coins: 13000,
        price: '\$99.99',
        badge: 'BEST DEAL',
        icon: Icons.emoji_events),
  ];

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  void _purchase(BuildContext context, int coins, String label) {
    // Demo purchase: credits coins immediately. Replace with a real
    // in-app purchase flow (e.g. in_app_purchase package) before release.
    AppState.instance.addBonusCoins(coins);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Purchased $label - +$coins coins!')),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: shopBlue,
            foregroundColor: Colors.white,
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Shop'),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Premium'),
                  const SizedBox(height: 10),
                  _AnimatedEntry(
                    controller: _entrance,
                    index: 0,
                    child: _ShopCard(
                      icon: Icons.workspace_premium,
                      iconColor: Colors.amber.shade700,
                      title: 'Premium',
                      subtitle: 'No ads, +100 coins',
                      price: '\$2.99',
                      onTap: () => _purchase(context, 100, 'Premium'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel('Coins'),
                  const SizedBox(height: 10),
                  for (int i = 0; i < packs.length; i++) ...[
                    _AnimatedEntry(
                      controller: _entrance,
                      index: i + 1,
                      child: _ShopCard(
                        icon: packs[i].icon,
                        iconColor: shopBlue,
                        title: packs[i].label,
                        badge: packs[i].badge,
                        price: packs[i].price,
                        onTap: () => _purchase(context, packs[i].coins, packs[i].label),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.lock, color: Colors.grey.shade400, size: 18),
                        const SizedBox(height: 6),
                        Text(
                          'Secure payments processed by the App Store / Play Store',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Colors.grey.shade600,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 1,
      ),
    );
  }
}

/// Fades + slides each card in with a slight stagger so the shop feels
/// alive on open rather than appearing all at once.
class _AnimatedEntry extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;
  const _AnimatedEntry({required this.controller, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.08).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
        parent: controller, curve: Interval(start, end, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, 16 * (1 - anim.value)), child: c),
      ),
      child: child,
    );
  }
}

class _ShopCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? badge;
  final String price;
  final VoidCallback onTap;

  const _ShopCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.badge,
    required this.price,
    required this.onTap,
  });

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: widget.iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(widget.subtitle!,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTapDown: (_) => setState(() => _scale = 0.92),
                    onTapUp: (_) => setState(() => _scale = 1.0),
                    onTapCancel: () => setState(() => _scale = 1.0),
                    onTap: widget.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: _ShopScreenState.buyGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(widget.price,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.badge != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: Text(widget.badge!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}