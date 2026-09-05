import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

BoxDecoration panelDecoration({Color? borderColor, Color? background, double radius = 16}) {
  return BoxDecoration(
    color: background ?? AppColors.panel,
    border: Border.all(color: borderColor ?? AppColors.border),
    borderRadius: BorderRadius.circular(radius),
  );
}

/// Section header, e.g. "Tables". Rendered as written — no more forced
/// capitals.
class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry margin;
  final Color color;

  const SectionLabel(
    this.text, {
    super.key,
    this.margin = const EdgeInsets.fromLTRB(2, 4, 2, 10),
    this.color = AppColors.textFaint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Text(text, style: AppText.sectionLabel(color: color)),
    );
  }
}

/// Instrument-Serif italic screen title, e.g. "Stats", "Friends".
class ScreenTitle extends StatelessWidget {
  final String text;

  const ScreenTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text, style: AppText.serifItalic(32, height: 1.1)),
    );
  }
}
