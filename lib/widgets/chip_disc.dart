import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A casino chip, painted rather than tapped.
///
/// [ChipButton] already drew one, but only as part of a button, so every other
/// place the game wanted a chip — the daily-bonus dialog, chips flying across
/// the felt at settlement — reached for a flat gold circle instead. The look
/// lives here now and both use it.
class ChipDisc extends StatelessWidget {
  /// Rim colour. Denominations use [AppColors.chipColors].
  final Color color;

  final double size;

  /// Optional face text, e.g. "\$25". A chip in flight carries none.
  final String? label;

  const ChipDisc({super.key, required this.color, this.size = 60, this.label});

  @override
  Widget build(BuildContext context) {
    final text = label;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Lit from the upper left, like every other raised surface in the app.
        gradient: const RadialGradient(
          center: Alignment(-0.24, -0.4),
          colors: [Color(0xFF1E2A26), Color(0xFF0C1110)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: AppAlpha.half), blurRadius: size * 0.2, offset: Offset(0, size * 0.08)),
        ],
      ),
      child: CustomPaint(
        painter: ChipEdgePainter(color: color),
        child: text == null
            ? null
            : Center(
                child: Text(
                  text,
                  style: AppText.mono(size * 0.23, weight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
      ),
    );
  }
}

/// The rim band, edge spots and inner ring that make a circle read as a chip.
class ChipEdgePainter extends CustomPainter {
  final Color color;

  /// Six spots is what most real casino chips use; it also stays legible at
  /// 48dp, where eight would smear into a dashed line.
  static const int _spotCount = 6;

  const ChipEdgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    // Every stroke is proportional so a chip reads the same at 26px in flight
    // as at 60px in the tray.
    final unit = size.width / 60;

    canvas.drawCircle(
      centre,
      radius - 1.5 * unit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * unit
        ..color = color,
    );

    final spotPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * unit
      ..strokeCap = StrokeCap.butt
      ..color = color;
    const sweep = math.pi / 14;
    for (var i = 0; i < _spotCount; i++) {
      final start = (2 * math.pi / _spotCount) * i - sweep / 2;
      canvas.drawArc(Rect.fromCircle(center: centre, radius: radius - 2.5 * unit), start, sweep, false, spotPaint);
    }

    canvas.drawCircle(
      centre,
      radius * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit
        ..color = color.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant ChipEdgePainter old) => old.color != color;
}
