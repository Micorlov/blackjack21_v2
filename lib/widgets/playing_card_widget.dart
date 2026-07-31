import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/playing_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Face-up playing card, sized relative to the reference 58x84 card.
class PlayingCardFace extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final double height;

  const PlayingCardFace({super.key, required this.card, this.width = 58, this.height = 84});

  @override
  Widget build(BuildContext context) {
    final color = card.isRed ? AppColors.cardRed : AppColors.cardBlack;
    final scale = width / 58;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardFaceTop, AppColors.cardFaceBottom],
        ),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 16 * scale, offset: Offset(0, 8 * scale)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 7 * scale,
            top: 4 * scale,
            child: Text(
              card.rank,
              style: AppText.sora(25 * scale, weight: FontWeight.w800, color: color, height: 1),
            ),
          ),
          Positioned(
            left: 9 * scale,
            top: 33 * scale,
            child: Text(card.suit, style: AppText.sora(17 * scale, color: color, height: 1)),
          ),
          Positioned(
            right: 6 * scale,
            bottom: 5 * scale,
            child: Text(card.suit, style: AppText.sora(32 * scale, color: color, height: 1)),
          ),
        ],
      ),
    );
  }
}

/// Face-down card back using the equipped [CardBackDef] skin.
class PlayingCardBack extends StatelessWidget {
  final double width;
  final double height;
  final CardBackDef skin;

  const PlayingCardBack({super.key, this.width = 58, this.height = 84, required this.skin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: skin.borderColor, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 26, offset: const Offset(0, 12)),
        ],
      ),
      child: skin.pattern == CardBackPattern.stripe
          ? CustomPaint(painter: _DiagonalStripePainter(skin.colorA, skin.colorB), size: Size(width, height))
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [skin.colorA, skin.colorB],
                ),
              ),
            ),
    );
  }
}

class _DiagonalStripePainter extends CustomPainter {
  final Color background;
  final Color stripe;
  static const double _stripeWidth = 6;

  const _DiagonalStripePainter(this.background, this.stripe);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()..color = stripe;
    final span = size.width + size.height;
    for (double x = -span; x < span; x += _stripeWidth * 2) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + _stripeWidth, 0)
        ..lineTo(x + _stripeWidth - size.height, size.height)
        ..lineTo(x - size.height, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripePainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.stripe != stripe;
}
