import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/game_data.dart';
import '../../models/enums.dart';
import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../utils/table_seats.dart';
import '../../widgets/confetti_burst.dart';
import 'chip_flight_layer.dart';
import 'dealer_area.dart';
import 'hero_hand_area.dart';
import 'seat_plate.dart';
import 'table_calc.dart';
import 'table_layout.dart';

/// The felt Stack: dealer cluster + up to 4 friend seat plates + the hero's
/// own hand, over a radial-gradient oval table.
///
/// Layout is constraint-driven: [FeltMetrics.forState] turns the box we were
/// actually handed into a canvas, a capped content scale, and fractional seat
/// slots. Nothing here is pinned to the source design's 393px width any more —
/// that number survives only as the *reference* the scale is chosen against,
/// because the parts inside (a 58x84 card, a 40px avatar) do have intrinsic
/// sizes.
///
/// The canvas is exactly `available / scale`, so no content is ever laid out
/// in a box smaller than it asks for: the [ClipRect] below exists for the
/// decorative oval, which deliberately bleeds past the canvas, not to hide
/// overflow from the layout tests. A real overflow still throws.
///
/// System text scaling applies here like anywhere else. It used to be switched
/// off outright, which covered every live number in the game — dealer total,
/// bet, hand total, balance, seat stacks — so a player at 200% got 100% on the
/// felt. Now each slot absorbs the growth by scaling its own contents down,
/// which keeps the arrangement intact without lying about the setting.
class TableFelt extends ConsumerWidget {
  const TableFelt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final midPot = TableCalc.midRoundPot(state);
    final cardBack = kCardBackDefs.firstWhere((c) => c.id == state.cardBackSkin, orElse: () => kCardBackDefs.first);
    final felt = feltById(state.themeChoice);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.biggest;
        if (!available.isFinite || available.width <= 0 || available.height <= 0) {
          return const SizedBox.shrink();
        }

        // The dealer cluster is largely type, so the room it needs grows with
        // the system font setting. Clamped to the same 1.0–1.3 range the app
        // allows anywhere else.
        final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final m = FeltMetrics.forState(state, available, textScale: textScale.clamp(1.0, 1.3));

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: m.canvas.width,
            maxWidth: m.canvas.width,
            minHeight: m.canvas.height,
            maxHeight: m.canvas.height,
            child: Transform.scale(
              scale: m.scale,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: m.canvas.width,
                height: m.canvas.height,
                child: Stack(
                  children: [
                    _feltOval(felt, m),
                    _lampFalloff(m),
                    _topVignette(),
                    _chipTray(m),
                    _discardPile(m),
                    DealerArea(
                      state: state,
                      midPot: midPot,
                      cardBack: cardBack,
                      inset: m.inset,
                      contentWidth: m.contentWidth,
                    ),
                    if (kShowFriendsAtTable) ..._seatPlates(state, m),
                    if (state.phase != RoundPhase.settlement)
                      HeroHandArea(state: state, top: m.heroTop, inset: m.inset),
                    // Celebration sits above the felt's contents and below
                    // nothing: both layers ignore pointers, so the READY
                    // button underneath stays tappable through them.
                    if (state.phase == RoundPhase.settlement) ...[
                      Positioned.fill(child: ChipFlightLayer(state: state, metrics: m)),
                      if (_deservesConfetti(state))
                        Positioned.fill(
                          child: ConfettiBurst(trigger: state.roundNet, origin: Alignment(0, _confettiOrigin(m))),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Which results are worth confetti.
  ///
  /// Not every win: a $50 hand that beats the dealer by a point is the game
  /// working normally, and celebrating it every time would make the gesture
  /// mean nothing by the tenth hand. Reserved for a natural blackjack and for
  /// sweeping the table, which is what this game is actually about.
  static bool _deservesConfetti(GameState state) {
    final blackjack = state.hands.any((h) => h.status == HandStatus.blackjack);
    if (blackjack && state.messageType == MessageType.win) return true;
    return (state.sweepInfo?.heroTook ?? false) && state.sweepAmount > 0;
  }

  /// Bursts from the hero's own plate rather than the middle of the screen, so
  /// the chips appear to come off the player's own hand.
  static double _confettiOrigin(FeltMetrics m) {
    if (m.canvas.height <= 0) return 0;
    return ((m.heroTop / m.canvas.height) * 2 - 1).clamp(-1.0, 1.0);
  }

  /// All four seats share one slot width and no per-row scale, so every
  /// friend's plate renders at exactly the same size. The design shrank the far
  /// pair to 0.9 for a perspective hint, but that made two identically-built
  /// plates read as two different components, which is worse than the lost
  /// depth cue.
  ///
  /// A plate that shrinks inside its slot collapses toward the slot's origin,
  /// so each seat is anchored to the edge of the content band it belongs to —
  /// a right-hand seat aligned left would drift inward and leave the two
  /// right-hand plates visibly out of line with each other.
  List<Widget> _seatPlates(GameState state, FeltMetrics m) {
    final widgets = <Widget>[];
    final seats = tableSeats(state);
    final count = math.min(4, seats.length);
    for (var i = 0; i < count; i++) {
      final friend = seats[i];
      final npc = i < state.npcSeats.length ? state.npcSeats[i] : null;
      final takesPot =
          state.phase == RoundPhase.settlement &&
          state.sweepInfo != null &&
          !state.sweepInfo!.heroTook &&
          state.sweepInfo!.winner == friend.firstName;
      final data = SeatPlateData.fromState(
        friend: friend,
        npc: npc,
        acting: state.actingSeat == i,
        rightSide: i.isOdd,
        avatarBg: AppColors.seatColors[i % AppColors.seatColors.length],
        takesPot: takesPot,
        sweepTotalWin: state.sweepInfo?.totalWin ?? 0,
        hourly: state.badgeHourly,
      );
      // Seats alternate left, right, left, right — two columns of two.
      final rightSide = i.isOdd;
      final alignment = rightSide ? Alignment.topRight : Alignment.topLeft;
      widgets.add(
        Positioned(
          left: rightSide ? null : m.inset,
          right: rightSide ? m.inset : null,
          top: m.seatTopOf(i ~/ 2),
          width: m.seatWidth,
          // Every seat gets exactly its slot. Content that runs long (a
          // seven-figure stack, a four-card hand, a 200% text setting) shrinks
          // inside the slot instead of growing down into the row below it.
          height: m.seatHeight,
          // Anchored at the top edge so an over-long plate shrinks upward,
          // away from the seat row directly below it.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: SizedBox(
              width: m.seatWidth,
              child: SeatPlate(data: data, compact: m.compact),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  /// The table: an ellipse with a wooden rim, tipped away from the viewer so
  /// the far edge recedes. The design builds this with `perspective:760px` /
  /// `perspective-origin:50% 0%` on the frame and `rotateX(50deg)` /
  /// `transform-origin:50% 0%` on the ellipse itself, which is what the
  /// matrix below reproduces — a flat ellipse reads as a green pill instead
  /// of a table seen from a player's seat.
  Widget _feltOval(FeltDef felt, FeltMetrics m) {
    return Positioned(
      left: m.inset - m.ovalBleed,
      right: m.inset - m.ovalBleed,
      top: 52,
      height: m.ovalHeight,
      child: Transform(
        alignment: Alignment.topCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 1 / 760)
          // Negative because Flutter's perspective entry treats +z as
          // receding, the opposite of the CSS the design is written in: the
          // near (bottom) edge has to come toward the viewer so the table
          // widens as it approaches and its far edge tapers to the top arc.
          ..rotateX(-50 * math.pi / 180),
        child: DecoratedBox(
          // Wooden rim.
          decoration: ShapeDecoration(
            shape: const OvalBorder(),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7A4A2C), Color(0xFF4A2A18), Color(0xFF2A170E)],
              stops: [0.0, 0.4, 1.0],
            ),
            shadows: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.65), blurRadius: 60, offset: const Offset(0, 30)),
            ],
          ),
          child: Padding(
            // The design insets the felt 20px inside the rim.
            padding: const EdgeInsets.all(20),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: OvalBorder(side: BorderSide(color: AppColors.gold.withValues(alpha: 0.16), width: 2)),
                // The player's chosen felt (Casino Green / Deep Ocean / Ember).
                gradient: felt.ovalGradient,
              ),
              // Stands in for the design's `inset 0 26px 60px` felt shadow.
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: const OvalBorder(),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                    stops: const [0.0, 0.34],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A single lamp hanging over the middle of the table.
  ///
  /// One soft radial falloff — bright where the dealer stands, dropping away
  /// toward the corners — rather than another drop shadow. The 3D/hyperrealism
  /// style profile is explicit that stacking heavy shadows on top of an
  /// already-3D surface reads as mud, so the depth here is bought with light.
  Widget _lampFalloff(FeltMetrics m) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              // Above centre, where the dealer's cluster sits.
              center: const Alignment(0, -0.45),
              radius: 0.95,
              colors: [
                Colors.transparent,
                Colors.transparent,
                const Color(0xFF040806).withValues(alpha: 0.28),
                const Color(0xFF040806).withValues(alpha: 0.55),
              ],
              stops: const [0.0, 0.42, 0.78, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topVignette() {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: IgnorePointer(
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF040806),
                const Color(0xFF040806).withValues(alpha: 0.55),
                const Color(0x00040806),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Decorative shoe + discard-pile glyph in the top-right corner. Excluded
  /// from the semantics tree — it is scenery, and a screen reader announcing
  /// it would only get in the way of the hand being played.
  Widget _discardPile(FeltMetrics m) {
    return Positioned(
      right: m.inset + 10,
      top: 4,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(i == 0 ? 0 : -19.0 * i, 0),
                child: Container(
                  width: 26,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9A332E), Color(0xFF5A1B18)],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Container(
                width: 13,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: Colors.black.withValues(alpha: 0.6),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Decorative chip tray in the top-left corner. Scenery, like the discard
  /// pile — not the player's own chips.
  Widget _chipTray(FeltMetrics m) {
    return Positioned(
      left: m.inset + 10,
      top: 10,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A2018), Color(0xFF15100B)],
            ),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Container(width: 15, height: 13, color: const Color(0xFFB98F3E)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
