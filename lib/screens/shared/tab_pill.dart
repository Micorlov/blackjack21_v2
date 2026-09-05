import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// One tab in a [TabPillRow].
class TabPillItem {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const TabPillItem({required this.label, required this.active, required this.onTap});
}

/// The app's segmented control.
///
/// This shape was copy-pasted into three screens with three different font
/// sizes (13/14/15) and two paddings, so the same control looked like a
/// different control depending on which tab bar you were standing in. One
/// implementation, one size.
class TabPillRow extends StatelessWidget {
  final List<TabPillItem> items;

  const TabPillRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: TabPill(item: items[i])),
        ],
      ],
    );
  }
}

class TabPill extends StatelessWidget {
  final TabPillItem item;

  const TabPill({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // `selected` is what tells a screen reader which tab is current — the gold
    // tint alone says it to sighted players only.
    return Semantics(
      button: true,
      selected: item.active,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.pillAll,
          onTap: item.onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTouch.minTarget),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadius.pillAll,
                // borderStrong, not border: the outline is the only thing
                // saying "this is a control", so it has to clear 3:1.
                border: Border.all(color: item.active ? AppColors.gold : AppColors.borderStrong),
                color: item.active ? AppColors.gold.withValues(alpha: AppAlpha.subtle) : Colors.transparent,
              ),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                style: AppText.sora(
                  14,
                  weight: FontWeight.w700,
                  color: item.active ? AppColors.gold : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
