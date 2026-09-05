import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/buttons.dart';

/// One-time "Four things to know" primer shown between onboarding and the
/// lobby for brand-new players ("proposed · new screen" 11 in the design
/// doc). "Deal me in" keeps the three-hand tutorial armed; "I've played
/// before — skip" turns it off too. Either way the screen never comes back.
class TipsScreen extends ConsumerWidget {
  const TipsScreen({super.key});

  static const List<(String, String)> _tips = [
    (
      'Beat the dealer, not 21',
      'Get closer to 21 than the dealer without going over. Going over is a bust — you lose your bet.',
    ),
    ('Blackjack pays 3:2', 'An ace plus a ten-card on the deal is a natural 21 — the best-paying hand in the game.'),
    ('Win the sweep pot', "Every hand feeds the table's sweep pot. The best hand at the table takes the whole pot."),
    ('Never go broke', "Claim the daily bonus in the lobby and gift chips to friends — there's always a way back in."),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.6),
          radius: 1.2,
          colors: [AppColors.felt, AppColors.feltDark, AppColors.feltDarkest],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Faint club watermark, same trick as onboarding's suits.
          Positioned(
            top: -40,
            right: -30,
            child: ExcludeSemantics(
              // Background chrome: a screen reader should not open this screen
              // by announcing a club symbol.
              child: Transform.rotate(
                angle: 15 * 3.14159 / 180,
                child: Text(
                  '♣',
                  style: TextStyle(fontSize: 220, height: 1, color: Colors.white.withValues(alpha: 0.03)),
                ),
              ),
            ),
          ),
          SafeArea(
            // Scrolls on short viewports; on a full-height phone the min-height
            // constraint plus the Spacer pin the gold button to the bottom.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'BEFORE YOU SIT DOWN',
                            style: AppText.mono(13, letterSpacing: 1.6, color: AppColors.gold),
                          ),
                          const SizedBox(height: 8),
                          Text('Four things to know', style: AppText.serifItalic(40)),
                          const SizedBox(height: 22),
                          for (var i = 0; i < _tips.length; i++) _TipCard(number: i + 1, tip: _tips[i]),
                          const Spacer(),
                          const SizedBox(height: 10),
                          GoldButton(label: 'Deal me in', onPressed: () => notifier.finishTips()),
                          const SizedBox(height: 12),
                          Center(
                            child: TextLinkButton(
                              label: "I've played before — skip",
                              onPressed: () => notifier.finishTips(skipTutorial: true),
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final int number;
  final (String, String) tip;

  const _TipCard({required this.number, required this.tip});

  @override
  Widget build(BuildContext context) {
    // Merged so each card is announced as one tip — "1, Beat the dealer, …" —
    // instead of a loose number followed by two unrelated blocks of text.
    return MergeSemantics(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: AppColors.gold.withValues(alpha: AppAlpha.tint)),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withValues(alpha: 0.15)),
              alignment: Alignment.center,
              child: Text(
                '$number',
                style: AppText.mono(17, weight: FontWeight.w700, color: AppColors.gold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.$1, style: AppText.sora(17, weight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(tip.$2, style: AppText.sora(14.5, color: AppColors.textMuted, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
