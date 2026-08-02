import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/game_data.dart';
import '../../models/enums.dart';
import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../utils/table_seats.dart';
import 'dealer_area.dart';
import 'hero_hand_area.dart';
import 'seat_plate.dart';
import 'table_calc.dart';

class _SeatPos {
  final double? left;
  final double? right;
  final double top;
  final double width;
  final bool originLeft;

  const _SeatPos({
    this.left,
    this.right,
    required this.top,
    required this.width,
    this.originLeft = true,
  });
}

/// All four seats share one slot width and no per-row scale, so every friend's
/// plate renders at exactly the same size. The design shrank the far pair to
/// 0.9 for a perspective hint, but that made two identically-built plates read
/// as two different components, which is worse than the lost depth cue.
///
/// [_SeatPos.originLeft] has to match the edge its slot is anchored to. A plate
/// that shrinks inside its slot collapses toward that origin, so a right-hand
/// seat left on the default `true` drifts away from the table's right edge and
/// leaves the two right-hand plates visibly out of line with each other.
const List<_SeatPos> _kSeatPositions = [
  _SeatPos(left: 0, top: 164, width: 196),
  _SeatPos(right: 0, top: 164, width: 196, originLeft: false),
  _SeatPos(left: 0, top: 262, width: 196),
  _SeatPos(right: 0, top: 262, width: 196, originLeft: false),
];

/// Height of one seat slot: a card row (38) over a name plate (~50), plus a
/// few pixels of slack.
const double _kSeatHeight = 92;

/// Vertical space the seat plates own, measured from the top of the felt
/// canvas: the lower pair sits at y=262 and is [_kSeatHeight] tall, plus a
/// breathing gap. The hero's hand is never allowed to grow past this line.
const double _kSeatsBottom = 362;

/// Room the hero's own hand block wants below [_kSeatsBottom]: a card row
/// (84) over the bet circle (70) over the name plate (~52), plus the gaps
/// between them. Anything tighter than this and the block scales itself down.
const double _kHeroMinHeight = 217;

/// Same block before any cards are dealt (the betting phase): no card row and
/// no gap beneath it, just the bet circle over the name plate. Reserving the
/// full [_kHeroMinHeight] this early forces the whole felt canvas — every
/// seat plate, avatar, and badge on it — to scale down for a card row that
/// isn't on screen yet.
const double _kHeroMinHeightNoCards = 128;

/// The felt Stack: dealer cluster + up to 4 friend seat plates + the hero's
/// own hand, over a radial-gradient oval table.
///
/// Everything inside is laid out on a design canvas — the source design's
/// 393-wide felt, with its literal edge-anchored pixel offsets (`seatPos` in
/// `renderVals()`) — which is scaled down only as far as the space the device
/// actually gives us demands. That keeps the arrangement identical to the
/// design at every screen size instead of letting fixed offsets collide on
/// shorter or narrower phones.
///
/// The height the canvas asks for is what the *current* phase actually needs
/// ([_requiredHeight]), never a fixed maximum. The design's felt is a
/// `flex:1` box that simply clips, so demanding its full extent at all times
/// would shrink the whole table to a thin, over-wide sliver whenever the
/// bottom panel is tall — during settlement the hero's hand is hidden, so
/// that space is not needed and the felt should stay full size.
class TableFelt extends ConsumerWidget {
  static const double _designWidth = 393;

  const TableFelt({super.key});

  /// Vertical extent the felt's contents occupy in this phase. Settlement
  /// hides the hero's hand (the bottom result card recaps it instead), so the
  /// seat rows are the whole story. Before the deal (betting phase) the hero
  /// block has no cards yet, so it only needs [_kHeroMinHeightNoCards].
  static double _requiredHeight(GameState state) {
    if (state.phase == RoundPhase.settlement) return _kSeatsBottom;
    final hasCards = state.hands.any((h) => h.cards.isNotEmpty);
    return _kSeatsBottom + (hasCards ? _kHeroMinHeight : _kHeroMinHeightNoCards);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final midPot = TableCalc.midRoundPot(state);
    final cardBack = kCardBackDefs.firstWhere((c) => c.id == state.cardBackSkin, orElse: () => kCardBackDefs.first);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.biggest;
        if (available.width <= 0 || available.height <= 0) return const SizedBox.shrink();

        final required = _requiredHeight(state);
        // No upper cap: on a device with more room than the 393-wide design
        // assumes, the felt should grow to fill it rather than sit pinned at
        // 1:1 pixel scale with black space around it.
        final scale = math.min(available.width / _designWidth, available.height / required);
        final canvas = Size(available.width / scale, available.height / scale);

        return ClipRect(
          // The felt is a scaled graphic canvas, so its metrics already adapt;
          // letting system font scaling stretch text inside it would
          // reintroduce the overlaps this canvas exists to prevent.
          child: MediaQuery.withNoTextScaling(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: canvas.width,
              maxWidth: canvas.width,
              minHeight: canvas.height,
              maxHeight: canvas.height,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: canvas.width,
                  height: canvas.height,
                  child: Stack(
                    children: [
                      _feltOval(),
                      _topVignette(),
                      _chipTray(),
                      _discardPile(),
                      DealerArea(state: state, midPot: midPot, cardBack: cardBack),
                      if (kShowFriendsAtTable) ..._seatPlates(state),
                      if (state.phase != RoundPhase.settlement)
                        HeroHandArea(state: state, top: _kSeatsBottom),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _seatPlates(GameState state) {
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
      final pos = _kSeatPositions[i];
      final alignment = pos.originLeft ? Alignment.topLeft : Alignment.topRight;
      widgets.add(
        Positioned(
          left: pos.left,
          right: pos.right,
          top: pos.top,
          width: pos.width,
          // Every seat gets exactly its design slot. Content that runs long
          // (a seven-figure stack, a four-card hand) shrinks inside the slot
          // instead of growing down into the seat row below it.
          height: _kSeatHeight,
          // Anchored at the top edge so an over-long plate shrinks upward,
          // away from the seat row directly below it.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: SizedBox(
              width: pos.width,
              child: SeatPlate(data: data),
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
  Widget _feltOval() {
    return Positioned(
      left: -58,
      right: -58,
      top: 52,
      height: 540,
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
                gradient: const RadialGradient(
                  center: Alignment(0, -0.48),
                  radius: 0.9,
                  colors: [Color(0xFF2A8F70), Color(0xFF166248), Color(0xFF0B3527), Color(0xFF082A20)],
                  stops: [0.0, 0.42, 0.78, 1.0],
                ),
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

  /// Decorative shoe + discard-pile glyph in the top-right corner.
  Widget _discardPile() {
    return Positioned(
      right: 10,
      top: 4,
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
    );
  }

  /// Decorative chip tray in the top-left corner.
  Widget _chipTray() {
    return Positioned(
      left: 10,
      top: 10,
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
    );
  }
}
