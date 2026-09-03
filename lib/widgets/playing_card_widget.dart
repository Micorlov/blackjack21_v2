import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/playing_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Face-up playing card, sized relative to the reference 58x84 card.
///
/// ## Why the suits are painted rather than typed
///
/// The pips used to be `Text('♥')` — Unicode glyphs, whose shape, weight and
/// vertical alignment are whatever the resolved font decides. On a device
/// missing the glyph the card renders a tofu box, and the app fetches its
/// fonts at runtime, so a cold first launch drew the suits in a fallback face.
/// Painting them makes a card look the same everywhere and stay crisp at any
/// size — cards scale from 24px in the settlement strip to ~118px on a tablet.
///
/// ## Why a card announces itself
///
/// A card was three positioned `Text`s, so a screen reader read the rank and
/// then the suit glyph *twice* — "10 ♦ ♦". Now the card carries one label,
/// "10 of diamonds", and its painted parts are hidden from the tree.
class PlayingCardFace extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final double height;

  const PlayingCardFace({
    super.key,
    required this.card,
    this.width = 58,
    this.height = 84,
  });

  @override
  Widget build(BuildContext context) {
    final color = card.isRed ? AppColors.cardRed : AppColors.cardBlack;
    final scale = width / 58;
    return Semantics(
      label: describeCard(card),
      excludeSemantics: true,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cardFaceTop, AppColors.cardFaceBottom],
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm * scale),
          border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 16 * scale,
              offset: Offset(0, 8 * scale),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 7 * scale,
              top: 4 * scale,
              child: Text(
                card.rank,
                style: AppText.sora(
                  25 * scale,
                  weight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
            ),
            // The small corner pip, under the rank.
            Positioned(
              left: 9 * scale,
              top: 34 * scale,
              child: SuitSymbol(suit: card.suit, size: 15 * scale, color: color),
            ),
            // The large face pip.
            Positioned(
              right: 6 * scale,
              bottom: 6 * scale,
              child: SuitSymbol(suit: card.suit, size: 30 * scale, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single painted suit pip.
class SuitSymbol extends StatelessWidget {
  final String suit;
  final double size;
  final Color color;

  const SuitSymbol({
    super.key,
    required this.suit,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SuitPainter(suit: suit, color: color),
    );
  }
}

/// Draws the four suits from paths defined in a unit square, then scaled.
class _SuitPainter extends CustomPainter {
  final String suit;
  final Color color;

  const _SuitPainter({required this.suit, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final w = size.width;
    final h = size.height;

    switch (suit) {
      case '♥':
        canvas.drawPath(_heart(w, h), paint);
      case '♦':
        canvas.drawPath(_diamond(w, h), paint);
      case '♠':
        canvas.drawPath(_spade(w, h), paint);
      case '♣':
        _club(canvas, paint, w, h);
      default:
        // An unknown suit should be visible as a defect, not silently absent.
        canvas.drawPath(_diamond(w, h), paint);
    }
  }

  /// Two lobes meeting at a bottom point.
  static Path _heart(double w, double h) {
    return Path()
      ..moveTo(0.5 * w, h)
      ..cubicTo(-0.06 * w, 0.62 * h, 0.11 * w, 0.02 * h, 0.5 * w, 0.30 * h)
      ..cubicTo(0.89 * w, 0.02 * h, 1.06 * w, 0.62 * h, 0.5 * w, h)
      ..close();
  }

  static Path _diamond(double w, double h) {
    return Path()
      ..moveTo(0.5 * w, 0)
      ..lineTo(0.94 * w, 0.5 * h)
      ..lineTo(0.5 * w, h)
      ..lineTo(0.06 * w, 0.5 * h)
      ..close();
  }

  /// An inverted heart on a tapered stem.
  static Path _spade(double w, double h) {
    final body = Path()
      ..moveTo(0.5 * w, 0.03 * h)
      ..cubicTo(0.5 * w, 0.30 * h, 0.02 * w, 0.40 * h, 0.02 * w, 0.62 * h)
      ..cubicTo(0.02 * w, 0.80 * h, 0.30 * w, 0.84 * h, 0.5 * w, 0.68 * h)
      ..cubicTo(0.70 * w, 0.84 * h, 0.98 * w, 0.80 * h, 0.98 * w, 0.62 * h)
      ..cubicTo(0.98 * w, 0.40 * h, 0.5 * w, 0.30 * h, 0.5 * w, 0.03 * h)
      ..close();
    return Path.combine(PathOperation.union, body, _stem(w, h));
  }

  /// Three lobes on the same stem.
  static void _club(Canvas canvas, Paint paint, double w, double h) {
    final r = 0.26 * w;
    canvas.drawCircle(Offset(0.5 * w, 0.26 * h), r, paint);
    canvas.drawCircle(Offset(0.24 * w, 0.60 * h), r, paint);
    canvas.drawCircle(Offset(0.76 * w, 0.60 * h), r, paint);
    canvas.drawPath(_stem(w, h), paint);
  }

  /// The flared foot shared by spade and club.
  static Path _stem(double w, double h) {
    return Path()
      ..moveTo(0.42 * w, 0.58 * h)
      ..cubicTo(0.44 * w, 0.80 * h, 0.36 * w, 0.92 * h, 0.26 * w, h)
      ..lineTo(0.74 * w, h)
      ..cubicTo(0.64 * w, 0.92 * h, 0.56 * w, 0.80 * h, 0.58 * w, 0.58 * h)
      ..close();
  }

  @override
  bool shouldRepaint(_SuitPainter oldDelegate) =>
      oldDelegate.suit != suit || oldDelegate.color != color;
}

/// "Ace of spades", "10 of diamonds" — what a screen reader should say.
String describeCard(PlayingCard card) =>
    '${_rankName(card.rank)} of ${_suitName(card.suit)}';

String _rankName(String rank) {
  switch (rank) {
    case 'A':
      return 'Ace';
    case 'K':
      return 'King';
    case 'Q':
      return 'Queen';
    case 'J':
      return 'Jack';
    default:
      return rank;
  }
}

String _suitName(String suit) {
  switch (suit) {
    case '♠':
      return 'spades';
    case '♥':
      return 'hearts';
    case '♦':
      return 'diamonds';
    case '♣':
      return 'clubs';
    default:
      return 'unknown suit';
  }
}

/// Face-down card back using the equipped [CardBackDef] skin.
class PlayingCardBack extends StatelessWidget {
  final double width;
  final double height;
  final CardBackDef skin;

  /// What this hidden card means here. The dealer's hole card and a card in
  /// an opponent's hand are both face down but are not the same thing, so the
  /// caller names it.
  final String semanticLabel;

  const PlayingCardBack({
    super.key,
    this.width = 58,
    this.height = 84,
    required this.skin,
    this.semanticLabel = 'Face-down card',
  });

  @override
  Widget build(BuildContext context) {
    final scale = width / 58;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm * scale),
          border: Border.all(color: skin.borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 26 * scale,
              offset: Offset(0, 12 * scale),
            ),
          ],
        ),
        child: skin.pattern == CardBackPattern.stripe
            ? CustomPaint(
                painter: _DiagonalStripePainter(skin.colorA, skin.colorB),
                size: Size(width, height),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [skin.colorA, skin.colorB],
                  ),
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
