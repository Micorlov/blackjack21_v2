import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Circular avatar, optionally wrapped in the gold "frame" ring. Shows
/// [photoUrl] when present (falling back to the initial on load failure),
/// otherwise shows [initial].
class AvatarCircle extends StatelessWidget {
  final String initial;
  final Color color;
  final double size;
  final bool goldRing;
  final String? photoUrl;

  const AvatarCircle({
    super.key,
    required this.initial,
    required this.color,
    this.size = 40,
    this.goldRing = false,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initialsAvatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppText.sora(size * 0.42, weight: FontWeight.w800, color: AppColors.goldInk),
      ),
    );
    final photoUrl = this.photoUrl;
    final avatar = photoUrl == null
        ? initialsAvatar
        : ClipOval(
            child: Image.network(
              photoUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => initialsAvatar,
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
