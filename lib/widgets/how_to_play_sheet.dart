import 'package:flutter/material.dart';

import '../data/tutorial_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Opens the "How to play" reference guide as a draggable bottom sheet.
///
/// A sheet rather than a screen: it can be opened from the table mid-hand (by
/// the tutorial coach card) without unwinding the round, and from Settings,
/// without either one needing a route of its own.
Future<void> showHowToPlaySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _HowToPlaySheet(),
  );
}

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.gold)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const _SheetGrabber(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('How to play', style: AppText.serifItalic(32, height: 1.1)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 22),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                itemCount: kGuideSections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (context, i) => _GuideSectionBlock(section: kGuideSections[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 4,
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
    );
  }
}

class _GuideSectionBlock extends StatelessWidget {
  final GuideSection section;

  const _GuideSectionBlock({required this.section});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title.toUpperCase(),
          style: AppText.mono(12, weight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.gold),
        ),
        const SizedBox(height: 7),
        for (final line in section.lines) _GuideLine(line: line),
      ],
    );
  }
}

/// One paragraph, or — when the line starts with '· ' — one bullet whose
/// wrapped text lines up under the first word instead of under the dot.
class _GuideLine extends StatelessWidget {
  static const String _bulletPrefix = '· ';

  final String line;

  const _GuideLine({required this.line});

  @override
  Widget build(BuildContext context) {
    final isBullet = line.startsWith(_bulletPrefix);
    final style = AppText.sora(14.5, color: const Color(0xFFD8D3C6), height: 1.5);

    if (!isBullet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(line, style: style),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('·', style: style.copyWith(color: AppColors.gold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(line.substring(_bulletPrefix.length), style: style),
          ),
        ],
      ),
    );
  }
}
