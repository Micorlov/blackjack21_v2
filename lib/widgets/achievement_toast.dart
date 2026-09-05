import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// The banner that announces an achievement the moment it is earned.
///
/// The seven achievements existed for the app's whole life as a list on the
/// Stats screen, recomputed from stats on every build. Crossing one produced
/// nothing: no chips, no sound, no acknowledgement. A player could hit their
/// hundredth hand and find out days later by opening a tab.
///
/// Slides down from the top of the screen over whatever is there, announces
/// itself to screen readers, and clears on tap or after a few seconds.
class AchievementToast extends ConsumerStatefulWidget {
  const AchievementToast({super.key});

  @override
  ConsumerState<AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends ConsumerState<AchievementToast> {
  /// Long enough to read a two-line banner without stopping play.
  static const Duration _visible = Duration(seconds: 4);

  @override
  Widget build(BuildContext context) {
    final id = ref.watch(gameProvider.select((s) => s.achievementBanner));
    final notifier = ref.read(gameProvider.notifier);
    final def = id == null ? null : kAchievementDefs.where((d) => d.id == id).firstOrNull;

    return AnimatedSwitcher(
      duration: AppMotion.durationOf(context, AppMotion.base),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween(begin: const Offset(0, -0.6), end: Offset.zero).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: def == null
          ? const SizedBox.shrink(key: ValueKey('no-achievement'))
          : _Banner(
              key: ValueKey(def.id),
              def: def,
              visibleFor: _visible,
              onDismiss: notifier.clearAchievementBanner,
            ),
    );
  }
}

class _Banner extends StatefulWidget {
  final AchievementDef def;
  final Duration visibleFor;
  final VoidCallback onDismiss;

  const _Banner({super.key, required this.def, required this.visibleFor, required this.onDismiss});

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.visibleFor, () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    return Semantics(
      liveRegion: true,
      label: 'Achievement unlocked: ${def.name}. ${def.desc}. ${formatChips(def.reward)} chips',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.lgAll,
            onTap: widget.onDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: AppRadius.lgAll,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.military_tech, color: AppColors.goldInk, size: 26),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          def.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sora(15, weight: FontWeight.w800, color: AppColors.goldInk),
                        ),
                        Text(
                          def.desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sora(12, color: AppColors.goldInk.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '+${formatChips(def.reward)}',
                    style: AppText.mono(18, weight: FontWeight.w700, color: AppColors.goldInk),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
