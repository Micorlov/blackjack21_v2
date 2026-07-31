import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
      child: Row(
        children: [
          _HeaderIconButton(icon: Icons.chevron_left, onTap: notifier.exitTable),
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
              _HeaderIconButton(icon: Icons.chat_bubble_outline, onTap: notifier.toggleTableChat),
              const SizedBox(width: 8),
              _HeaderIconButton(icon: Icons.more_vert, onTap: notifier.toggleTableMenu),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Icon(icon, color: AppColors.textPrimary, size: 21)),
      ),
    );
  }
}

/// Small floating "Leave Table" dropdown shown near the kebab-menu icon
/// when `state.tableMenuOpen` is true.
class TableMenuDropdown extends ConsumerWidget {
  const TableMenuDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    return Positioned(
      top: 50,
      right: 14,
      child: Material(
        color: AppColors.navSurface,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: notifier.exitTable,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text('Leave Table', style: AppText.sora(17, color: AppColors.loseSoft)),
          ),
        ),
      ),
    );
  }
}
