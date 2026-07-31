import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The design's `bjDeal` keyframe — a card easing into place as it is dealt:
/// `opacity 0→1`, `translateY(-12px)→0`, `scale(.92)→1` over 350ms.
///
/// Plays once, when the card first appears in the tree. Give each card a
/// stable key so a later card joining the row does not restart its
/// neighbours' animations.
class DealInCard extends StatefulWidget {
  final Widget child;

  const DealInCard({super.key, required this.child});

  @override
  State<DealInCard> createState() => _DealInCardState();
}

class _DealInCardState extends State<DealInCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.ease.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -12 * (1 - t)),
            child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A card that turns face up in place when [revealed] flips true — the
/// dealer opening their hole card.
///
/// Half a rotation about the vertical axis, swapping [back] for [face] as the
/// card passes edge-on so neither side is ever seen mirrored. Going back to
/// face-down (a new round) resets instantly rather than un-flipping, since
/// nothing is being revealed there.
class FlipRevealCard extends StatefulWidget {
  final bool revealed;
  final Widget back;
  final Widget face;

  const FlipRevealCard({super.key, required this.revealed, required this.back, required this.face});

  @override
  State<FlipRevealCard> createState() => _FlipRevealCardState();
}

class _FlipRevealCardState extends State<FlipRevealCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: widget.revealed ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant FlipRevealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed == oldWidget.revealed) return;
    if (widget.revealed) {
      _controller.forward();
    } else {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final isFaceUp = t >= 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(t * math.pi),
          child: isFaceUp
              // Counter-rotated: the parent has carried the card past
              // edge-on by now, so the face would otherwise read mirrored.
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: widget.face,
                )
              : widget.back,
        );
      },
    );
  }
}
