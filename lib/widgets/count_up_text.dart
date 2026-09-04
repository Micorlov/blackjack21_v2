import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';
import '../utils/formatters.dart';

/// A number that rolls to its new value instead of snapping to it.
///
/// The game is scored entirely in chips, and every figure that mattered — the
/// balance in the table header, the net on the settlement card, the points
/// delta in the rank strip — simply changed between one frame and the next.
/// Winning $400 and losing $50 looked exactly alike: a number was one thing,
/// then it was another.
///
/// Counts up *and* down, so a loss is felt too, and honours reduced motion by
/// arriving at the value immediately.
class CountUpText extends StatelessWidget {
  final int value;
  final TextStyle style;

  /// Rendered before the digits, e.g. `$`. Kept out of [value] so the digits
  /// can be formatted with thousands separators.
  final String prefix;

  /// Rendered after the digits.
  final String suffix;

  /// Shows an explicit `+` for positive values, as the net and points figures
  /// do.
  final bool signed;

  /// Ticks a selection haptic as the digits move. Rate-capped internally, so a
  /// four-figure win is a short run of ticks rather than a buzz.
  final bool haptic;

  final Duration duration;
  final TextAlign? textAlign;

  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.signed = false,
    this.haptic = false,
    this.duration = AppMotion.celebratory,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return _CountUpBody(
      value: value,
      style: style,
      prefix: prefix,
      suffix: suffix,
      signed: signed,
      haptic: haptic,
      duration: AppMotion.durationOf(context, duration),
      textAlign: textAlign,
    );
  }
}

class _CountUpBody extends StatefulWidget {
  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final bool signed;
  final bool haptic;
  final Duration duration;
  final TextAlign? textAlign;

  const _CountUpBody({
    required this.value,
    required this.style,
    required this.prefix,
    required this.suffix,
    required this.signed,
    required this.haptic,
    required this.duration,
    required this.textAlign,
  });

  @override
  State<_CountUpBody> createState() => _CountUpBodyState();
}

class _CountUpBodyState extends State<_CountUpBody> {
  /// Where the roll starts from. The first build shows the real figure
  /// straight away — a balance that counts up from zero every time the table
  /// opens is a slot machine, not a bankroll.
  late int _from = widget.value;
  DateTime? _lastTick;

  @override
  void didUpdateWidget(covariant _CountUpBody old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _from = old.value;
  }

  void _tick() {
    if (!widget.haptic) return;
    final now = DateTime.now();
    // Eight ticks a second at most: past that the taptic engine runs them
    // together into one long buzz and the effect is lost.
    if (_lastTick != null && now.difference(_lastTick!) < const Duration(milliseconds: 125)) return;
    _lastTick = now;
    HapticFeedback.selectionClick();
  }

  String _format(int v) {
    final sign = widget.signed && v > 0 ? '+' : (v < 0 ? '-' : '');
    return '$sign${widget.prefix}${formatChips(v.abs())}${widget.suffix}';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      // Keyed on the target so a value that changes mid-roll restarts from
      // where the digits actually are rather than snapping.
      key: ValueKey(widget.value),
      tween: IntTween(begin: _from, end: widget.value),
      duration: widget.duration,
      curve: AppMotion.enter,
      builder: (context, v, _) {
        if (v != widget.value) _tick();
        return Text(_format(v), style: widget.style, textAlign: widget.textAlign, maxLines: 1);
      },
    );
  }
}
