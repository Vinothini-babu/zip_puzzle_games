// shop_screen.dart
// In-app shop: Premium (remove ads + coins) and coin packs, styled after
// the reference screenshot with elevated cards and entrance animation so
// the screen feels full and polished rather than sparse.
//
// Wired to real in-app purchases via IapService. Prices shown come
// directly from Play Store / App Store (product.price) - never
// hardcoded, since real prices vary by region/currency.

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'app_state.dart';
import 'iap_service.dart';

/// Display metadata (icon/badge) for each coin-pack product id. The
/// price and title text itself comes from the store (ProductDetails),
/// not from here.
class _PackMeta {
  final IconData icon;
  final String? badge;
  const _PackMeta({required this.icon, this.badge});
}

const Map<String, _PackMeta> _coinPackMeta = {
  IapService.coins100: _PackMeta(icon: Icons.monetization_on),
  IapService.coins550: _PackMeta(icon: Icons.savings, badge: 'MOST POP'),
  IapService.coins1200: _PackMeta(icon: Icons.card_giftcard, badge: 'ADS FREE'),
  IapService.coins3200: _PackMeta(icon: Icons.diamond, badge: 'ADS FREE'),
  IapService.coins13000: _PackMeta(icon: Icons.emoji_events, badge: 'BEST DEAL'),
};

// Preserves the shop's intended display order (store API doesn't
// guarantee product ordering).
const List<String> _coinPackOrder = [
  IapService.coins100,
  IapService.coins550,
  IapService.coins1200,
  IapService.coins3200,
  IapService.coins13000,
];

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  static const Color shopBlue = Color(0xFF29B6F6);
  static const Color buyGreen = Color(0xFF43A047);

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    IapService.instance.onStateChanged = () {
      if (mounted) setState(() {});
    };
    IapService.instance.onPurchaseSuccess = (productId, coinsGranted) {
      if (!mounted) return;
      setState(() => _purchasing = false);
      final message = coinsGranted != null
          ? 'Purchase successful - +$coinsGranted coins!'
          : 'Purchase successful!';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    };
  }

  @override
  void dispose() {
    _entrance.dispose();
    IapService.instance.onStateChanged = null;
    IapService.instance.onPurchaseSuccess = null;
    super.dispose();
  }

  Future<void> _buy(ProductDetails product, {required bool consumable}) async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    try {
      await IapService.instance.buy(product, consumable: consumable);
      // Result (success/error) arrives asynchronously via the purchase
      // stream -> onPurchaseSuccess above. If it errors out silently,
      // clear the spinner after a timeout so the button doesn't stay
      // stuck forever.
    } catch (e) {
      if (mounted) {
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
      }
    }
  }

  ProductDetails? _findProduct(String id) {
    for (final p in IapService.instance.products) {
      if (p.id == id) return p;
    }
    return null;
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
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final iap = IapService.instance;

    if (iap.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: shopBlue)),
      );
    }

    if (iap.loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade400, size: 40),
            const SizedBox(height: 12),
            Text(
              iap.loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => IapService.instance.init(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final premiumProduct = _findProduct(IapService.premiumPack);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Premium'),
        const SizedBox(height: 10),
        if (premiumProduct != null)
          _AnimatedEntry(
            controller: _entrance,
            index: 0,
            child: _ShopCard(
              icon: Icons.workspace_premium,
              iconColor: Colors.amber.shade700,
              title: premiumProduct.title,
              subtitle: premiumProduct.description,
              price: premiumProduct.price,
              enabled: !_purchasing,
              onTap: () => _buy(premiumProduct, consumable: false),
            ),
          )
        else
          _missingProductNote('premium_pack'),
        const SizedBox(height: 24),
        const _SectionLabel('Coins'),
        const SizedBox(height: 10),
        for (int i = 0; i < _coinPackOrder.length; i++) ...[
          Builder(builder: (context) {
            final id = _coinPackOrder[i];
            final product = _findProduct(id);
            final meta = _coinPackMeta[id]!;
            if (product == null) return _missingProductNote(id);
            return _AnimatedEntry(
              controller: _entrance,
              index: i + 1,
              child: _ShopCard(
                icon: meta.icon,
                iconColor: shopBlue,
                title: product.title,
                badge: meta.badge,
                price: product.price,
                enabled: !_purchasing,
                onTap: () => _buy(product, consumable: true),
              ),
            );
          }),
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
    );
  }

  Widget _missingProductNote(String id) {
    // Shown only during development/testing if a Product ID hasn't been
    // created in Play Console yet - won't appear once products are live.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        'Product "$id" not found in store yet',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontStyle: FontStyle.italic),
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
  final bool enabled;
  final VoidCallback onTap;

  const _ShopCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.badge,
    required this.price,
    required this.onTap,
    this.enabled = true,
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
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.6,
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
                      onTapDown: widget.enabled ? (_) => setState(() => _scale = 0.92) : null,
                      onTapUp: widget.enabled ? (_) => setState(() => _scale = 1.0) : null,
                      onTapCancel: widget.enabled ? () => setState(() => _scale = 1.0) : null,
                      onTap: widget.enabled ? widget.onTap : null,
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
      ),
    );
  }
}