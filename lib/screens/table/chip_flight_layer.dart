import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../models/social_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../utils/table_seats.dart';
import '../../widgets/chip_disc.dart';
import 'table_layout.dart';

/// Chips flying from each beaten seat to the player's plate when they sweep
/// the table.
///
/// The sweep pot is what this game is built around: every losing seat forfeits
/// its bet to the best surviving hand. The audio said so — a call-out and a
/// drum flourish — and the felt said nothing at all. A number under the seats
/// changed, and that was the whole event.
///
/// Positions come straight from [FeltMetrics], which already knows where every
/// seat and the hero plate sit, so nothing here needs a `GlobalKey` or a
/// post-frame measurement.
class ChipFlightLayer extends StatefulWidget {
  final GameState state;
  final FeltMetrics metrics;

  const ChipFlightLayer({super.key, required this.state, required this.metrics});

  @override
  State<ChipFlightLayer> createState() => _ChipFlightLayerState();
}

class _ChipFlightLayerState extends State<ChipFlightLayer> with SingleTickerProviderStateMixin {
  /// Long enough to read as a journey across the felt, short enough that the
  /// player is not waiting on it before the result card lands.
  static const Duration _flight = Duration(milliseconds: 750);

  /// How far apart the seats release their chips.
  static const Duration _stagger = Duration(milliseconds: 90);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _flight);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fly());
  }

  @override
  void didUpdateWidget(covariant ChipFlightLayer old) {
    super.didUpdateWidget(old);
    if (old.state.sweepInfo != widget.state.sweepInfo) _fly();
  }

  void _fly() {
    if (!mounted || AppMotion.reduceMotion(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Which seat forfeited which bet. A contributor the seat roster does not
  /// know about is skipped rather than guessed at a position for.
  List<({int seat, SweepContributor who})> _sources() {
    final info = widget.state.sweepInfo;
    if (info == null) return const [];
    final seats = tableSeats(widget.state);
    final out = <({int seat, SweepContributor who})>[];
    for (final c in info.contributors) {
      final i = seats.indexWhere((s) => s.firstName == c.name);
      if (i >= 0 && i < 4) out.add((seat: i, who: c));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.state.sweepInfo;
    if (info == null || !info.heroTook) return const SizedBox.shrink();

    final sources = _sources();
    if (sources.isEmpty) return const SizedBox.shrink();

    final m = widget.metrics;
    // The hero's plate, which at settlement is where the winnings land.
    final target = Offset(m.canvas.width / 2, m.heroTop - 24);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isDismissed) return const SizedBox.expand();
          return Stack(
            children: [
              for (var i = 0; i < sources.length; i++) _chip(sources[i], i, sources.length, target, m),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(({int seat, SweepContributor who}) source, int index, int count, Offset target, FeltMetrics m) {
    final rightSide = source.seat.isOdd;
    final from = Offset(
      rightSide ? m.canvas.width - m.inset - m.seatWidth / 2 : m.inset + m.seatWidth / 2,
      m.seatTopOf(source.seat ~/ 2) + m.seatHeight / 2,
    );

    final offset = _stagger.inMilliseconds * index / _flight.inMilliseconds;
    final t = ((_controller.value - offset) / (1 - offset)).clamp(0.0, 1.0);
    if (t <= 0) return const SizedBox.shrink();

    final eased = AppMotion.enter.transform(t);
    final pos = Offset.lerp(from, target, eased)!;
    // Lifted off the felt mid-flight and set back down, so the chip arcs
    // rather than sliding flat across the table.
    final lift = -28 * (1 - (2 * eased - 1).abs());
    // Fades only at the very end, as it lands on the plate.
    final opacity = t > 0.85 ? (1 - (t - 0.85) / 0.15) : 1.0;
    const size = 26.0;

    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy + lift - size / 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: ChipDisc(color: AppColors.seatColors[source.seat % AppColors.seatColors.length], size: size),
      ),
    );
  }
}
