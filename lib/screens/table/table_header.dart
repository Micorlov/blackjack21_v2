import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/buttons.dart';
import 'table_layout.dart';

/// Table-screen header: back chevron, centered stake name + range, and
/// chat/kebab-menu icon buttons. Screen-specific chrome (not the shared app
/// shell), since the bottom nav and shell header are hidden on this screen.
class TableHeader extends ConsumerWidget {
  const TableHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final stake = state.stake;
    final gutter = TableLayout.gutterOf(MediaQuery.sizeOf(context).width);

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, AppSpacing.xxs, gutter, AppSpacing.xs),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.chevron_left,
            semanticLabel: 'Leave the table',
            onPressed: notifier.exitTable,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stake?.name ?? '',
                  style: AppText.sora(24, weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // The stake line is a single unsplittable fact — shrinking it
                // keeps "3:2" readable where an ellipsis would eat it. It is
                // short on purpose: between the three round buttons the title
                // column is ~200px, and the old "$100 – $1000 · PAYS 3:2" was
                // being shrunk to 14px type however large it was asked to be.
                if (stake != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '\$${formatChips(stake.min)}–\$${formatChips(stake.max)} · 3:2',
                      style: AppText.mono(17, color: AppColors.textPrimary.withValues(alpha: 0.82)),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleIconButton(
                icon: Icons.chat_bubble_outline,
                semanticLabel: state.tableChatOpen ? 'Close table chat' : 'Open table chat',
                onPressed: notifier.toggleTableChat,
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleIconButton(
                icon: Icons.more_vert,
                semanticLabel: state.tableMenuOpen ? 'Close table menu' : 'Open table menu',
                onPressed: notifier.toggleTableMenu,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small floating "Leave Table" dropdown shown near the kebab-menu icon
/// when `state.tableMenuOpen` is true.
///
/// Fills the screen so the transparent area around the menu acts as a dismiss
/// barrier: before this the only way out was to find and press the kebab a
/// second time, which is not how a menu behaves anywhere else on the platform.
class TableMenuDropdown extends ConsumerWidget {
  const TableMenuDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final gutter = TableLayout.gutterOf(MediaQuery.sizeOf(context).width);
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              label: 'Close the table menu',
              button: true,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: notifier.toggleTableMenu),
            ),
          ),
          Positioned(
            top: 50,
            right: gutter,
            child: Material(
              color: AppColors.navSurface,
              borderRadius: AppRadius.mdAll,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: AppAlpha.half),
              child: InkWell(
                borderRadius: AppRadius.mdAll,
                onTap: notifier.exitTable,
                child: Container(
                  constraints: const BoxConstraints(minHeight: AppTouch.minTarget),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: Colors.white.withValues(alpha: AppAlpha.hairline)),
                  ),
                  child: Text('Leave Table', style: AppText.sora(19, color: AppColors.loseSoft)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
