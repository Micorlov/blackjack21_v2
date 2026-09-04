import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text_styles.dart';

/// Top-of-screen toast pill, driven by `GameState.toast`.
///
/// This is the app's only error channel — all 24 failure paths end here, from
/// "Not enough chips" to "Google sign-in failed". It is therefore also the
/// only thing telling a screen-reader user that an action failed, which is why
/// the pill is a live region: it announces itself when it appears rather than
/// waiting to be found.
class ToastBanner extends StatelessWidget {
  final String text;

  const ToastBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: AppMotion.durationOf(context, AppMotion.base),
          child: text.isEmpty
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : Semantics(
                  liveRegion: true,
                  container: true,
                  key: ValueKey(text),
                  child: Container(
                    margin: const EdgeInsets.only(top: 58),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: AppText.sora(
                        15,
                        weight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Floating reaction pill that fades in, holds, then rises and fades out —
/// ported from the `bjFloatUp` keyframes. Re-triggers whenever [triggerId]
/// changes (even for a repeated [text]).
class ReactionFloatOverlay extends StatefulWidget {
  final String text;
  final int triggerId;

  const ReactionFloatOverlay({
    super.key,
    required this.text,
    required this.triggerId,
  });

  @override
  State<ReactionFloatOverlay> createState() => _ReactionFloatOverlayState();
}

class _ReactionFloatOverlayState extends State<ReactionFloatOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.float,
    );
    if (widget.text.isNotEmpty) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant ReactionFloatOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerId != oldWidget.triggerId && widget.text.isNotEmpty) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          double opacity;
          if (t < 0.15) {
            opacity = t / 0.15;
          } else if (t < 0.78) {
            opacity = 1;
          } else {
            opacity = (1 - t) / 0.22;
          }
          opacity = opacity.clamp(0.0, 1.0);
          final dy = 10 - 56 * t;
          return Align(
            alignment: const Alignment(0, -0.24),
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navSurface.withValues(alpha: 0.95),
                    border: Border.all(color: AppColors.gold),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.text,
                    style: AppText.sora(
                      15,
                      weight: FontWeight.w800,
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
