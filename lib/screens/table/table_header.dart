import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
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
          _HeaderIconButton(icon: Icons.chevron_left, semanticLabel: 'Leave the table', onTap: notifier.exitTable),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stake?.name ?? '',
                  style: AppText.sora(21, weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // The stake line is a single unsplittable fact — shrinking it
                // keeps "PAYS 3:2" readable where an ellipsis would eat it.
                if (stake != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '\$${stake.min} – \$${stake.max} · PAYS 3:2',
                      style: AppText.mono(15, color: AppColors.textPrimary.withValues(alpha: 0.82)),
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
              _HeaderIconButton(
                icon: Icons.chat_bubble_outline,
                semanticLabel: state.tableChatOpen ? 'Close table chat' : 'Open table chat',
                onTap: notifier.toggleTableChat,
              ),
              const SizedBox(width: AppSpacing.sm),
              _HeaderIconButton(
                icon: Icons.more_vert,
                semanticLabel: state.tableMenuOpen ? 'Close table menu' : 'Open table menu',
                onTap: notifier.toggleTableMenu,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Icon-only control, so it carries its own accessible name — the glyph says
/// nothing to a screen reader — and it is sized to [AppTouch.minTarget] rather
/// than the 46px it used to be, which missed the minimum on every device.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.semanticLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.black.withValues(alpha: 0.32),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: AppTouch.minTarget,
            height: AppTouch.minTarget,
            child: Icon(icon, color: AppColors.textPrimary, size: 21),
          ),
        ),
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
              shadowColor: Colors.black.withValues(alpha: 0.5),
              child: InkWell(
                borderRadius: AppRadius.mdAll,
                onTap: notifier.exitTable,
                child: Container(
                  constraints: const BoxConstraints(minHeight: AppTouch.minTarget),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text('Leave Table', style: AppText.sora(17, color: AppColors.loseSoft)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
