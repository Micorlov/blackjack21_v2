import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'avatar_circle.dart';
import 'buttons.dart';

/// Full-screen story overlay shown by the app shell whenever
/// `state.activeStoryId != null`. Ported from the `activeStory` block in
/// `Blackjack 21 v2.dc.html` (lines 851-873): progress segments, a header
/// with close button, a tappable felt-gradient headline card, and a
/// "Send GG" CTA.
///
/// Expected to be placed inside a `Positioned.fill` / `SizedBox.expand` by
/// the caller; renders nothing when there's no active story.
class StoryOverlay extends ConsumerWidget {
  const StoryOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    if (state.activeStoryId == null) return const SizedBox.shrink();

    final story = kStoriesData.firstWhere((s) => s.id == state.activeStoryId, orElse: () => kStoriesData.first);
    final activeIndex = kStoriesData.indexOf(story);

    return SizedBox.expand(
      child: Container(
        color: AppColors.surface,
        child: SafeArea(
          child: Column(
            children: [
              _StoryProgressBar(total: kStoriesData.length, activeIndex: activeIndex),
              _StoryHeader(story: story, onClose: notifier.closeStory),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: notifier.nextStory,
                  child: Center(child: _StoryCard(story: story)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: GoldButton(label: 'Send GG', onPressed: notifier.sendGGActiveStory, verticalPadding: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin gold progress segments, one per story, filled up to the active one.
class _StoryProgressBar extends StatelessWidget {
  final int total;
  final int activeIndex;

  const _StoryProgressBar({required this.total, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: i <= activeIndex ? AppColors.gold : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoryHeader extends StatelessWidget {
  final StoryDef story;
  final VoidCallback onClose;

  const _StoryHeader({required this.story, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          AvatarCircle(initial: story.initial, color: story.color, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(story.name, style: AppText.sora(15, weight: FontWeight.w800)),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 22),
          ),
        ],
      ),
    );
  }
}

/// Felt-gradient, gold-bordered card showing the story's headline + detail.
class _StoryCard extends StatelessWidget {
  final StoryDef story;

  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: AppColors.feltCardGradient,
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            story.headline,
            textAlign: TextAlign.center,
            style: AppText.serifItalic(38, color: AppColors.gold, height: 1.08),
          ),
          const SizedBox(height: 10),
          Text(
            story.detail,
            textAlign: TextAlign.center,
            style: AppText.sora(16, color: const Color(0xFFD8D3C6), height: 1.5),
          ),
        ],
      ),
    );
  }
}
