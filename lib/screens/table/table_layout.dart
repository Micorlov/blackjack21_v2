import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../models/enums.dart';
import '../../models/game_state.dart';
import '../../theme/app_spacing.dart';

/// Width classes for the table screen.
///
/// Matches the app-wide breakpoints in [AppSpacing.gutterFor] so the table and
/// the list screens agree on what "a tablet" means.
enum TableWidthClass {
  /// Phones. < 600.
  compact,

  /// Small tablets, unfolded foldables, phone landscape. 600 – 900.
  medium,

  /// Tablets and desktop. > 900.
  expanded,
}

/// Layout decisions the table screen and the felt both need, kept in one place
/// so the chrome (header, phase banner, action panel) and the felt itself never
/// disagree about how wide the screen is or where its gutters are.
class TableLayout {
  TableLayout._();

  static const double compactMax = 600;
  static const double mediumMax = 900;

  static TableWidthClass widthClassOf(double width) {
    if (width >= mediumMax) return TableWidthClass.expanded;
    if (width >= compactMax) return TableWidthClass.medium;
    return TableWidthClass.compact;
  }

  /// Horizontal inset for the table's chrome.
  ///
  /// Phones deliberately keep the tight 14px the design was drawn with — on a
  /// 320-wide screen every pixel of gutter is a pixel taken off the HIT button
  /// — while medium and expanded widths take the shared token gutters so the
  /// controls stop stretching edge to edge on a tablet.
  static double gutterOf(double width) {
    return switch (widthClassOf(width)) {
      TableWidthClass.compact => 14,
      TableWidthClass.medium || TableWidthClass.expanded => AppSpacing.gutterFor(width),
    };
  }

  /// True when the action panel should sit in a side rail rather than under
  /// the felt. Landscape is decided on the *shape of the box we were given*
  /// rather than on [MediaQuery.orientationOf], so a narrow pane inside a
  /// split-screen window is treated as portrait even on a landscape device.
  static bool isLandscape(Size available) => available.width > available.height;

  /// Width of the landscape side rail holding the action panel.
  ///
  /// Wide enough for the three-button DOUBLE/SPLIT/SURRENDER row to stay
  /// readable, capped so the felt keeps the majority of a wide screen.
  /// The floor is 320, not 280.
  ///
  /// At 280 the rail fits the action buttons but not the tutorial coach card's
  /// header — step label, progress dots and the "Full rules"/"Skip" links —
  /// once system text scaling is applied. A landscape phone at 1.3x text
  /// overflowed it by 12px on every short device (640x360, 780x360, 812x375),
  /// across every round phase. The alternatives were worse: shrinking the two
  /// links to fit would push their tap targets under the 48dp minimum, and
  /// wrapping the header cost more width than it saved. The felt gives up 40px
  /// instead — it scales, and text does not.
  static double railWidthOf(double width) {
    return (width * 0.36).clamp(320.0, 420.0);
  }
}

/// The felt's geometry for one frame, derived from the space the device
/// actually gives us.
///
/// Replaces the previous fixed 393-wide design canvas with hard-coded seat
/// offsets. Two things changed and both matter:
///
/// * **The scale is capped.** The old code took `min(width / 393, height /
///   required)` with no upper bound, so an 800x1280 tablet rendered every
///   avatar, card and number at ~2.04x — a phone layout under a magnifying
///   glass. [maxScale] stops that; the extra room becomes gutter instead.
/// * **Seat slots are fractions of the felt, not literal pixels.** The slot
///   width is half the content band rather than a fixed 196, so plates fill
///   the felt on a wide canvas instead of leaving a hole down the middle.
///
/// The vertical anatomy is still expressed in canvas units, because it is
/// driven by content that has a real intrinsic size (a card is 84 tall, an
/// avatar 40) rather than by a share of the screen. Each band below is the
/// room its contents actually need; the bands are then summed, and the whole
/// stack is scaled to fit.
@immutable
class FeltMetrics {
  /// Scale the canvas is drawn at. Never above [maxScale].
  final double scale;

  /// Logical size of the canvas the felt lays out in (device size / [scale]).
  final Size canvas;

  /// Horizontal inset of the content band inside [canvas]. Non-zero only when
  /// the canvas is wider than [maxContentWidth] — a tablet or a landscape
  /// felt — which is what keeps the seats together instead of flinging them at
  /// the far edges of a very wide box.
  final double inset;

  /// Width of the content band: `canvas.width - 2 * inset`.
  final double contentWidth;

  /// Width of one seat slot.
  final double seatWidth;

  /// Height of one seat slot.
  final double seatHeight;

  /// Top of the near (upper) seat row, from the top of the canvas.
  final double seatRowTop;

  /// Distance between the two seat rows.
  final double seatRowPitch;

  /// Top of the hero's own hand block.
  final double heroTop;

  /// True in the betting phase, when nothing on the felt has cards yet.
  final bool compact;

  const FeltMetrics({
    required this.scale,
    required this.canvas,
    required this.inset,
    required this.contentWidth,
    required this.seatWidth,
    required this.seatHeight,
    required this.seatRowTop,
    required this.seatRowPitch,
    required this.heroTop,
    required this.compact,
  });

  /// The width the felt's fixed-size parts were drawn for: a 66x96 card, a
  /// 46px avatar, a 19px stack figure. It is a *reference* for choosing a
  /// scale, not a canvas the layout is pinned to.
  ///
  /// 384 is a 1080-wide Android phone at 450dpi — the device this game is
  /// tuned on — so that phone draws the felt at exactly 1.0 rather than the
  /// 0.977 the old 393 reference gave it.
  static const double referenceWidth = 384;

  /// Upper bound on the content scale.
  ///
  /// Roughly a 1.4x phone: enough that a tablet's extra pixels buy legibility,
  /// far short of the ~2x blow-up the uncapped version produced.
  static const double maxScale = 1.4;

  /// Widest the content band is allowed to get, in canvas units.
  ///
  /// A landscape felt can be two or three times as wide as it is tall; without
  /// this the two seat columns would sit against the outer edges with the
  /// dealer marooned in the middle.
  static const double maxContentWidth = 560;

  /// Widest a single seat slot may get. Past this a plate stops looking like a
  /// name tag and starts looking like a banner.
  static const double maxSeatWidth = 260;

  /// Gap under the lower seat row, exposed so the tests can check the hero
  /// block starts exactly where the seats end.
  static double get seatBandGap => _seatBandGap;

  /// Gap between the two seat columns, so the left and right plates never
  /// touch on a narrow canvas.
  static const double _seatColumnGap = 8;

  // ── Vertical anatomy, in canvas units ──
  //
  // Mid-round ("spread") the dealer shows cards and the hero has a fan. In
  // the betting phase ("compact") neither is true, so those two bands shrink
  // and the felt is drawn larger on the same screen. The seat rows are the
  // same height in both: a seat is a name plate, never a card row, so the
  // plates never jump between phases.
  //
  // The whole budget is sized so a 384x832 phone draws the felt at 1.0 in
  // every phase. It used to need 615 units mid-round against ~400 available,
  // which put every card, total and balance on the felt at two-thirds size
  // for the entire hand — the part of the game that matters most.

  /// Room the dealer cluster owns before the first seat row starts.
  ///
  /// Spread: a 56 badge (46 avatar + padding + border) + 8 + the 30 pot-pill
  /// slot + 8 + a 96 card row. Compact drops the card row. The pill's slot is
  /// reserved even while the pill is hidden, so the felt does not re-scale
  /// the moment the first seat busts and a pot appears.
  static const double _dealerBandSpread = 198;
  static const double _dealerBandCompact = 102;

  /// Extra room the settled "TABLE SWEEP" banner needs: a 7px-padded pill of
  /// 24px type, plus the gap above it, all of which appears
  /// between the pot pill and the cards and pushes the whole row down.
  static const double _sweepBannerBand = 56;

  /// Painted size of one dealer/hero card, and the gap between two of them
  /// when the row has room to breathe. Every card on the felt reads these so
  /// a size change here is a size change everywhere.
  static const double cardWidth = 66;
  static const double cardHeight = 96;
  static const double cardGap = 6;

  /// Horizontal distance between the left edges of two consecutive dealer
  /// cards, given how many there are and how much band they have.
  ///
  /// A dealer who keeps drawing (soft 17s, a five-card 21) would otherwise run
  /// the row past the felt: six cards at the full step are 426 units wide on
  /// a 384 canvas. Past that point the cards overlap into a fan instead, which
  /// keeps every rank corner visible and the row inside the table.
  static double dealerCardStep(int count, double available) {
    if (count <= 1) return cardWidth + cardGap;
    final full = cardWidth + cardGap;
    if (cardWidth + (count - 1) * full <= available) return full;
    final fitted = (available - cardWidth) / (count - 1);
    // Below this the corner index disappears under the next card.
    return math.max(fitted, 20);
  }

  /// Distance from one seat row to the next: the slot plus a 6 gap.
  static const double _seatPitch = 66;

  /// One seat slot: a name plate of ~58 (46 avatar + padding + border; 60
  /// with the acting seat's 2px border).
  static const double _seatHeight = 60;

  /// Breathing room under the lower seat row before the hero's block starts.
  static const double _seatBandGap = 6;

  /// The hero's block: a card row (96) over one row holding the bet circle,
  /// the total circle (78 each) and the name plate, plus the gap between and
  /// a little for the fanned cards' rotated corners.
  static const double _heroBandWithCards = 182;

  /// The same block before any card is dealt — the circle-and-plate row alone.
  /// Reserving the full [_heroBandWithCards] this early would shrink every
  /// seat plate on the felt for a row that is not on screen yet.
  static const double _heroBandNoCards = 80;

  /// The betting phase is the only compact one: no dealer cards and no hero
  /// fan. From the first deal onward the spread layout holds steady so nothing
  /// on the felt jumps mid-hand.
  static bool isCompactPhase(GameState state) => state.phase == RoundPhase.betting;

  /// How much of the dealer band is type rather than fixed geometry.
  ///
  /// The badge total, the "DEALER" caption, the pot pill and the sweep banner
  /// are all text, so they grow with the system font setting while the 46px
  /// avatar and the 96px cards do not. Without this the band stayed a
  /// constant at 1.3x and the cards were pushed down onto the seats again.
  static const double _dealerBandTextShare = 0.45;

  factory FeltMetrics.forState(GameState state, Size available, {double textScale = 1.0}) {
    final compact = isCompactPhase(state);
    final rawDealerBand =
        (compact ? _dealerBandCompact : _dealerBandSpread) + (state.sweepAmount > 0 ? _sweepBannerBand : 0);
    final dealerBand = rawDealerBand * (1 + (textScale - 1) * _dealerBandTextShare);
    const pitch = _seatPitch;
    const seatHeight = _seatHeight;
    final seatsBottom = dealerBand + pitch + seatHeight + _seatBandGap;

    // Settlement hides the hero's hand — the bottom result card recaps it
    // instead — so the seat rows are the whole story and the felt keeps its
    // full size rather than reserving room for a block that is not drawn.
    final double heroBand;
    if (state.phase == RoundPhase.settlement) {
      heroBand = 0;
    } else if (compact) {
      heroBand = _heroBandNoCards;
    } else {
      final hasCards = state.hands.any((h) => h.cards.isNotEmpty);
      heroBand = hasCards ? _heroBandWithCards : _heroBandNoCards;
    }
    final required = seatsBottom + heroBand;

    final fit = math.min(available.width / referenceWidth, available.height / required);
    final scale = math.min(fit, maxScale);
    final canvas = Size(available.width / scale, available.height / scale);

    final contentWidth = math.min(canvas.width, maxContentWidth);
    final inset = (canvas.width - contentWidth) / 2;
    final seatWidth = math.min((contentWidth - _seatColumnGap) / 2, maxSeatWidth);

    return FeltMetrics(
      scale: scale,
      canvas: canvas,
      inset: inset,
      contentWidth: contentWidth,
      seatWidth: seatWidth,
      seatHeight: seatHeight,
      seatRowTop: dealerBand,
      seatRowPitch: pitch,
      heroTop: seatsBottom,
      compact: compact,
    );
  }

  /// Top of seat row [row] (0 = near the dealer, 1 = near the player).
  double seatTopOf(int row) => seatRowTop + row * seatRowPitch;

  /// How far the decorative felt oval bleeds past the content band on each
  /// side, kept proportional to the band so the ellipse holds its shape at
  /// every width.
  double get ovalBleed => 58 * contentWidth / referenceWidth;

  /// Height of the decorative oval, likewise proportional.
  double get ovalHeight => 540 * contentWidth / referenceWidth;
}
