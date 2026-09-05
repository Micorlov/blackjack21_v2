import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../models/enums.dart';
import '../models/social_models.dart';
import '../state/game_notifier.dart';
import '../utils/xp.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/panel_card.dart';
import '../widgets/playing_card_widget.dart';
import 'shared/avatar_initial.dart';
import 'shared/empty_state.dart';

/// Shop screen — VIP banner, two social "highlight" feed cards, chip packs,
/// cosmetics (card backs / table felt / avatar frame), and the "watch an ad"
/// free-chips row. Ported from the `screen==='shop'` block in
/// `Blackjack 21 v2.dc.html` (lines 613-728).
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final avatarInitial = avatarInitialOf(state.displayName);
    // The two highlight cards were captioned with practice-bot names, so a
    // player with no friends was shown a social feed of people who do not
    // exist. They belong to the live group or to nobody.
    final liveFriends = state.friendsAreLive ? state.friends : const <Friend>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle('Shop'),
          _VipBanner(onLearnMore: notifier.vipLearnMore),
          const SizedBox(height: 20),
          if (liveFriends.isNotEmpty)
            _HighlightCard(
              avatarInitial: liveFriends[0].initial,
              avatarColor: AppColors.gold,
              name: liveFriends[0].name,
              subtitle: 'Just now · Bronze Table',
              accentColor: AppColors.gold,
              headline: 'Blackjack! +450 chips',
              liked: state.highlight1Liked,
              likeCount: state.highlight1Count,
              onToggleLike: notifier.toggleLike1,
              onSendGG: notifier.sendGGHighlight1,
            )
          else
            EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: 'No highlights yet',
              message:
                  'Big hands from your friends group show up here. Invite someone and their '
                  'blackjacks land in this feed.',
              actionLabel: 'Invite via WhatsApp',
              onAction: notifier.shareInviteWhatsApp,
            ),
          const SizedBox(height: 20),
          const SectionLabel('Chip packs'),
          _ChipPacksGrid(onBuy: notifier.buyPack),
          const SizedBox(height: AppSpacing.sm),
          // Said plainly, because the tiles show real-looking prices: this
          // build takes no payment, and the Privacy Policy says the same.
          Text(
            'Preview pricing — no payment is taken and the chips are added straight away.',
            style: AppText.caption(),
          ),
          const SizedBox(height: 10),
          const SectionLabel('Card backs'),
          _CardBacksRow(
            equippedId: state.cardBackSkin,
            onSelect: notifier.selectCardBack,
            level: Xp.levelFor(state.xp),
          ),
          const SizedBox(height: 10),
          const SectionLabel('Table felt'),
          _TableFeltRow(
            equippedId: state.themeChoice,
            onSelect: notifier.selectFelt,
            level: Xp.levelFor(state.xp),
          ),
          const SizedBox(height: 10),
          const SectionLabel('Avatar frame'),
          _AvatarFrameRow(
            avatarInitial: avatarInitial,
            goldFrame: state.avatarFrameGold,
            onSelect: notifier.setAvatarFrame,
          ),
          const SizedBox(height: 10),
          const SectionLabel('Free chips'),
          _FreeChipsRow(adState: state.adState, onWatchAd: notifier.watchAd),
          if (liveFriends.length > 1) ...[
            const SizedBox(height: 14),
            _HighlightCard(
              avatarInitial: liveFriends[1].initial,
              avatarColor: AppColors.win,
              name: liveFriends[1].name,
              subtitle: '10m ago · Silver Table',
              accentColor: AppColors.win,
              headline: '5-win streak!',
              liked: state.highlight2Liked,
              likeCount: state.highlight2Count,
              onToggleLike: notifier.toggleLike2,
              onSendGG: notifier.sendGGHighlight2,
            ),
          ],
        ],
      ),
    );
  }
}

/// Gold-bordered "VIP Club" promo banner at the top of the shop.
class _VipBanner extends StatelessWidget {
  final VoidCallback onLearnMore;

  const _VipBanner({required this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2E14), Color(0xFF121917)],
          stops: [0, 0.65],
        ),
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: AppColors.gold, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VIP Club', style: AppText.sora(17, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Unlock exclusive tables & bonuses', style: AppText.sora(14, color: const Color(0xFFCBBF9A))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PillButton(label: 'Learn more', onTap: onLearnMore),
        ],
      ),
    );
  }
}

/// Small gold outlined pill button (e.g. "Learn more").
class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold),
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppText.sora(15, weight: FontWeight.w800, color: AppColors.gold),
          ),
        ),
      ),
    );
  }
}

/// Social "highlight" feed card: header (avatar/name/subtitle), a felt-card
/// headline, and a footer with a like toggle + "Send GG".
class _HighlightCard extends StatelessWidget {
  final String avatarInitial;
  final Color avatarColor;
  final String name;
  final String subtitle;
  final Color accentColor;
  final String headline;
  final bool liked;
  final int likeCount;
  final VoidCallback onToggleLike;
  final VoidCallback onSendGG;

  const _HighlightCard({
    required this.avatarInitial,
    required this.avatarColor,
    required this.name,
    required this.subtitle,
    required this.accentColor,
    required this.headline,
    required this.liked,
    required this.likeCount,
    required this.onToggleLike,
    required this.onSendGG,
  });

  @override
  Widget build(BuildContext context) {
    final likeColor = liked ? accentColor : AppColors.textMuted;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: panelDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                AvatarCircle(initial: avatarInitial, color: avatarColor, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppText.sora(15, weight: FontWeight.w800)),
                      Text(subtitle, style: AppText.sora(13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.feltCardGradient,
                border: Border.all(color: accentColor),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                headline,
                textAlign: TextAlign.center,
                style: AppText.serifItalic(31, color: accentColor),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  toggled: liked,
                  // A heart and a bare number say nothing about whose hand
                  // this is or what tapping does.
                  label: 'Like $name\'s hand, $likeCount likes',
                  excludeSemantics: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onToggleLike,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        constraints: AppTouch.minTargetConstraints,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(liked ? Icons.favorite : Icons.favorite_border, size: 18, color: likeColor),
                            const SizedBox(width: 8),
                            Text(
                              '$likeCount',
                              style: AppText.sora(15, weight: FontWeight.w700, color: likeColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Send GG to $name',
                  excludeSemantics: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onSendGG,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        constraints: AppTouch.minTargetConstraints,
                        alignment: Alignment.center,
                        child: Text(
                          'Send GG',
                          style: AppText.sora(15, weight: FontWeight.w700, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2-column grid of purchasable chip packs.
class _ChipPacksGrid extends StatelessWidget {
  final void Function(ShopPackDef pack) onBuy;

  const _ChipPacksGrid({required this.onBuy});

  @override
  Widget build(BuildContext context) {
    // A pack tile is three stacked text lines, so its height has to follow the
    // user's font scale — a fixed aspect ratio clipped the price line off the
    // bottom of every tile at large type.
    final textScale = (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 1.3);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.15 / textScale,
      children: kShopPacks.map((pack) {
        return _ChipPackCard(pack: pack, onTap: () => onBuy(pack));
      }).toList(),
    );
  }
}

class _ChipPackCard extends StatelessWidget {
  final ShopPackDef pack;
  final VoidCallback onTap;

  const _ChipPackCard({required this.pack, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: panelDecoration(),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // The tile grows with the font scale, but a narrow phone can
              // still leave a pack line a couple of pixels short — scaling the
              // block down absorbs that instead of clipping the price.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_outlined, color: AppColors.gold, size: 30),
                    const SizedBox(height: 6),
                    Text(
                      '${formatChips(pack.amount)} chips',
                      textAlign: TextAlign.center,
                      style: AppText.sora(17, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pack.price,
                      style: AppText.sora(15, weight: FontWeight.w700, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
              if (pack.badge.isNotEmpty)
                Positioned(
                  top: -8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      pack.badge,
                      // Was 9px — below the app's 12px floor and unreadable
                      // for anyone who needs larger type.
                      style: AppText.sora(12, weight: FontWeight.w800, color: AppColors.goldInk),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row of small selectable swatches shared by "Card backs" and "Table felt".
class _SwatchOptionsRow extends StatelessWidget {
  final List<Widget> children;

  const _SwatchOptionsRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(14),
      child: Row(children: children.map((c) => Expanded(child: c)).toList()),
    );
  }
}

class _SelectableSwatch extends StatelessWidget {
  final Widget preview;
  final String label;
  final bool equipped;
  final VoidCallback onTap;

  /// Level needed to equip this, when it is not available yet.
  ///
  /// Everything in the shop used to be free and unlocked from the first hand,
  /// so the cosmetics section was a wall of things there was no reason to
  /// want. A locked swatch is still tappable — it says what it needs rather
  /// than doing nothing.
  final int? lockedAtLevel;

  const _SelectableSwatch({
    required this.preview,
    required this.label,
    required this.equipped,
    required this.onTap,
    this.lockedAtLevel,
  });

  @override
  Widget build(BuildContext context) {
    final locked = lockedAtLevel != null;
    return Semantics(
      button: true,
      selected: equipped,
      label: locked ? '$label, locked until level $lockedAtLevel' : (equipped ? '$label, equipped' : label),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Opacity(opacity: locked ? 0.4 : 1, child: preview),
                  if (equipped)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
                        child: const Icon(Icons.check, size: 10, color: AppColors.goldInk),
                      ),
                    ),
                  if (locked) const Icon(Icons.lock, size: 16, color: AppColors.textPrimary),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                locked ? 'Level $lockedAtLevel' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sora(
                  12.5,
                  weight: FontWeight.w700,
                  color: locked ? AppColors.textFaint : (equipped ? AppColors.gold : AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBacksRow extends StatelessWidget {
  final String equippedId;
  final void Function(String id) onSelect;
  final int level;

  const _CardBacksRow({required this.equippedId, required this.onSelect, required this.level});

  @override
  Widget build(BuildContext context) {
    return _SwatchOptionsRow(
      children: kCardBackDefs.map((cb) {
        return _SelectableSwatch(
          equipped: equippedId == cb.id,
          label: cb.label,
          lockedAtLevel: cb.requiredLevel > level ? cb.requiredLevel : null,
          onTap: () => onSelect(cb.id),
          preview: PlayingCardBack(width: 50, height: 34, skin: cb),
        );
      }).toList(),
    );
  }
}

class _TableFeltRow extends StatelessWidget {
  final String equippedId;
  final void Function(String id) onSelect;
  final int level;

  const _TableFeltRow({required this.equippedId, required this.onSelect, required this.level});

  @override
  Widget build(BuildContext context) {
    return _SwatchOptionsRow(
      children: kFeltDefs.map((ft) {
        return _SelectableSwatch(
          equipped: equippedId == ft.id,
          label: ft.label,
          lockedAtLevel: ft.requiredLevel > level ? ft.requiredLevel : null,
          onTap: () => onSelect(ft.id),
          preview: Container(
            width: 50,
            height: 34,
            decoration: BoxDecoration(
              gradient: ft.swatchGradient,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: ft.borderColor, width: 2),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// "None" / "Gold Ring" avatar-frame picker.
class _AvatarFrameRow extends StatelessWidget {
  final String avatarInitial;
  final bool goldFrame;
  final void Function(bool gold) onSelect;

  const _AvatarFrameRow({required this.avatarInitial, required this.goldFrame, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _AvatarFrameOption(
            label: 'None',
            selected: !goldFrame,
            avatar: AvatarCircle(initial: avatarInitial, color: AppColors.gold, size: 48),
            onTap: () => onSelect(false),
          ),
          const SizedBox(width: 16),
          _AvatarFrameOption(
            label: 'Gold Ring',
            selected: goldFrame,
            avatar: AvatarCircle(initial: avatarInitial, color: AppColors.gold, size: 48, goldRing: true),
            onTap: () => onSelect(true),
          ),
        ],
      ),
    );
  }
}

class _AvatarFrameOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Widget avatar;
  final VoidCallback onTap;

  const _AvatarFrameOption({required this.label, required this.selected, required this.avatar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$label avatar frame, equipped' : '$label avatar frame',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(height: 6),
            Text(
              label,
              style: AppText.sora(
                12.5,
                weight: FontWeight.w700,
                color: selected ? AppColors.gold : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Watch an ad" free-chips row.
class _FreeChipsRow extends StatelessWidget {
  final AdState adState;
  final VoidCallback onWatchAd;

  const _FreeChipsRow({required this.adState, required this.onWatchAd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withValues(alpha: 0.15)),
            alignment: Alignment.center,
            child: const Icon(Icons.play_arrow, color: AppColors.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Watch an ad', style: AppText.sora(16, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Get 200 free chips', style: AppText.sora(14, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _AdButton(adState: adState, onTap: onWatchAd),
        ],
      ),
    );
  }
}

class _AdButton extends StatelessWidget {
  final AdState adState;
  final VoidCallback onTap;

  const _AdButton({required this.adState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = switch (adState) {
      AdState.ready => 'Watch',
      AdState.watching => 'Watching…',
      AdState.cooldown => 'Come back later',
    };
    // Ready and watching both read as "gold" — watching is a disabled
    // mid-animation state, not yet the greyed-out cooldown state.
    final isGold = adState != AdState.cooldown;
    final isEnabled = adState == AdState.ready;

    return Semantics(
      button: true,
      enabled: isEnabled,
      // Disabled controls in this app used to state no reason at all.
      hint: switch (adState) {
        AdState.ready => null,
        AdState.watching => 'Your reward is on its way',
        AdState.cooldown => 'Available again shortly',
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: isEnabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            constraints: AppTouch.minTargetConstraints,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isGold ? AppColors.goldGradient : null,
              color: isGold ? null : AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: AppText.sora(15, weight: FontWeight.w800, color: isGold ? AppColors.goldInk : AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
