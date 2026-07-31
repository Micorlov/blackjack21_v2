import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Circular initial avatar, optionally wrapped in the gold "frame" ring.
class AvatarCircle extends StatelessWidget {
  final String initial;
  final Color color;
  final double size;
  final bool goldRing;

  const AvatarCircle({super.key, required this.initial, required this.color, this.size = 40, this.goldRing = false});

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppText.sora(size * 0.42, weight: FontWeight.w800, color: AppColors.goldInk),
      ),
    );
    if (!goldRing) return avatar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.shellBlack),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
        child: avatar,
      ),
    );
  }
}
