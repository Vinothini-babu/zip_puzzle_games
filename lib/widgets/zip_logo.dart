import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'stroked_text.dart';

/// Original ZIP wordmark (orange bubble letters + numbered path nodes).
class ZipLogo extends StatelessWidget {
  const ZipLogo({super.key, this.scale = 1});
  final double scale;

  static const _outline = Color(0xFF8A3A16);

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const StrokedText('ZIP',
                  size: 112,
                  fill: AppColors.orangeLight,
                  stroke: _outline,
                  strokeWidth: 22,
                  dropShadow: 6,
                  height: 1.0),
              Positioned(left: -14, top: 8, child: _node('1')),
              Positioned(right: -12, bottom: 14, child: _node('9')),
            ],
          ),
          const SizedBox(height: 2),
          const StrokedText('PUZZLE',
              size: 40,
              fill: AppColors.orangeLight,
              stroke: _outline,
              strokeWidth: 12,
              dropShadow: 4),
        ],
      ),
    );
  }

  Widget _node(String n) => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.teal,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
    ),
    child: Text(n, style: AppText.display(17)),
  );
}
