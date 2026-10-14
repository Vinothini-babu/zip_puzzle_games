import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'coin_pill.dart';

/// Plays a handful of coin icons flying up and fading out from
/// [originKey]'s current position — the classic "coins collected" burst
/// seen in most real games. Await the returned future to know when the
/// animation has finished (e.g. before navigating away).
Future<void> playCoinBurst(BuildContext context, {required GlobalKey originKey}) async {
  final overlayState = Overlay.of(context);
  final renderObject = originKey.currentContext?.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.attached) return;
  final origin = renderObject.localToGlobal(renderObject.size.center(Offset.zero));

  final completer = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CoinBurst(
      origin: origin,
      onDone: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );
  overlayState.insert(entry);
  return completer.future;
}

class _CoinSpec {
  _CoinSpec({required this.delay, required this.dx, required this.dyTarget, required this.size});
  final double delay;
  final double dx;
  final double dyTarget;
  final double size;
}

class _CoinBurst extends StatefulWidget {
  const _CoinBurst({required this.origin, required this.onDone});
  final Offset origin;
  final VoidCallback onDone;

  @override
  State<_CoinBurst> createState() => _CoinBurstState();
}

class _CoinBurstState extends State<_CoinBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 950))
    ..forward().whenComplete(widget.onDone);

  late final List<_CoinSpec> _coins = List.generate(10, (i) {
    final rnd = math.Random(i * 31 + 7);
    return _CoinSpec(
      delay: rnd.nextDouble() * 0.28,
      dx: (rnd.nextDouble() - 0.5) * 190,
      dyTarget: -(300 + rnd.nextDouble() * 160),
      size: 18 + rnd.nextDouble() * 10,
    );
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _coins.map((c) {
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = ((_c.value - c.delay) / (1 - c.delay)).clamp(0.0, 1.0);
              final eased = Curves.easeOut.transform(t);
              final wobble = math.sin(t * math.pi * 2) * 10 * (1 - t);
              final x = widget.origin.dx + c.dx * eased + wobble;
              final y = widget.origin.dy + c.dyTarget * eased;
              final fadeStart = 0.72;
              final opacity = t < fadeStart ? 1.0 : (1 - (t - fadeStart) / (1 - fadeStart));
              final scale = 1.0 - 0.25 * eased;
              return Positioned(
                left: x - c.size / 2,
                top: y - c.size / 2,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale.clamp(0.0, 1.0),
                    child: CoinIcon(size: c.size),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}