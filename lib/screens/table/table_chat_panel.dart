import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/game_data.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Chat overlay shown above the phase panel when `state.tableChatOpen`:
/// recent messages (most-recent-first) plus a row of quick-reaction chips.
class TableChatPanel extends ConsumerWidget {
  const TableChatPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final messages = state.chatMessages.reversed.toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${m.name}: ',
                        style: AppText.sora(15, weight: FontWeight.w700, color: AppColors.gold),
                      ),
                      TextSpan(
                        text: m.text,
                        style: AppText.sora(15, color: const Color(0xFFD8D3C6)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kReactions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final label = kReactions[i];
                return OutlinedButton(
                  onPressed: () => notifier.sendReaction(label),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.gold.withValues(alpha: 0.28)),
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(
                    label,
                    style: AppText.sora(15, weight: FontWeight.w600, color: AppColors.gold),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
