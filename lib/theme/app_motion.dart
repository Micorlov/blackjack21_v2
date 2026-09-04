import 'package:flutter/material.dart';

/// Motion tokens.
///
/// Durations are chosen by *what is moving and how far*, not copied from one
/// value to everything: a press tint settles in [fast], a panel cross-fade in
/// [base], a card travelling across the felt in [spatial], and a win
/// celebration gets [celebratory] because it is meant to be savoured.
///
/// Every animation in the app should route its duration through [durationOf]
/// so the player's reduced-motion setting is honoured in one place rather than
/// remembered at each call site.
class AppMotion {
  AppMotion._();

  /// Press tints, ripples, small opacity changes.
  static const Duration fast = Duration(milliseconds: 150);

  /// Cross-fades, panel swaps, state changes in place.
  static const Duration base = Duration(milliseconds: 250);

  /// Something moving across the screen — dealt cards, chips to the bet circle.
  static const Duration spatial = Duration(milliseconds: 350);

  /// Deliberately slow: blackjack and big-win moments.
  static const Duration celebratory = Duration(milliseconds: 600);

  /// A reaction drifting up over a seat and fading out.
  static const Duration float = Duration(milliseconds: 1600);

  /// One cycle of a repeating "still working" pulse.
  static const Duration pulse = Duration(milliseconds: 1200);

  /// Decelerating — for things entering or settling into place.
  static const Curve enter = Curves.easeOutCubic;

  /// Accelerating — for things leaving. Exits run shorter than entrances.
  static const Curve exit = Curves.easeInCubic;

  /// Symmetric — for things that move and stop within view, like a card flip.
  static const Curve emphasized = Curves.easeInOutCubic;

  /// Whether the player has asked the OS to reduce motion.
  ///
  /// Returns false when there is no [MediaQuery] in scope, which keeps this
  /// safe to call from widgets built in tests without a full app harness.
  static bool reduceMotion(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  /// The duration to actually animate for, collapsing to zero when the player
  /// has reduced motion enabled. The end state is still reached — it simply
  /// arrives immediately instead of being animated to.
  static Duration durationOf(BuildContext context, Duration duration) {
    return reduceMotion(context) ? Duration.zero : duration;
  }
}
