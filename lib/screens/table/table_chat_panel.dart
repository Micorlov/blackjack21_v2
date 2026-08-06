import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/game_data.dart';
import '../../models/social_models.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/table_seats.dart';

/// The table chat as a bottom sheet over a dimmed table (design screen 14):
/// drag-handle, "Table chat · N at the table", named message bubbles — the
/// player's own right-aligned in gold — and a row of quick-reply chips that
/// post a real "You" bubble. Canned replies only, so there is nothing to
/// moderate. Rendered by TableScreen's Stack while `state.tableChatOpen`.
class TableChatSheet extends ConsumerWidget {
  const TableChatSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final atTable = tableSeats(state).length + 1;

    return Positioned.fill(
      child: Stack(
        children: [
          // Dim the felt; tapping it closes the sheet.
          Positioned.fill(
            child: GestureDetector(
              onTap: notifier.toggleTableChat,
              child: ColoredBox(color: const Color(0xFF040806).withValues(alpha: 0.5)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.62),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.gold.withValues(alpha: 0.3))),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 50, offset: const Offset(0, -20)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Table chat', style: AppText.serifItalic(26)),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('$atTable at the table', style: AppText.mono(13, color: AppColors.textFaint)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.chatMessages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No table talk yet — say GG below.',
                                style: AppText.sora(14, color: AppColors.textFaint),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          for (final m in state.chatMessages) _ChatBubble(message: m),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: kReactions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final label = kReactions[i];
                        return OutlinedButton(
                          onPressed: () => notifier.sendChatMessage(label),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
                            backgroundColor: AppColors.gold.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(label, style: AppText.sora(14, weight: FontWeight.w700, color: AppColors.gold)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSelf = message.name == 'You';
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: isSelf ? AppColors.gold.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.07),
        border: Border.all(
          color: isSelf ? AppColors.gold.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isSelf ? 14 : 4),
          bottomRight: Radius.circular(isSelf ? 4 : 14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.name,
            style: AppText.sora(12, weight: FontWeight.w700, color: isSelf ? AppColors.gold : AppColors.textFaint),
          ),
          const SizedBox(height: 2),
          Text(message.text, style: AppText.sora(15, height: 1.4)),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [bubble],
      ),
    );
  }
}
