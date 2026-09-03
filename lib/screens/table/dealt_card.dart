import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';
import '../../widgets/card_animations.dart';

/// A card that eases into place the first time it appears — the design's
/// `bjDeal` — and simply *is* there when the player has asked the OS to reduce
/// motion.
///
/// Wrapping [DealInCard] rather than calling it directly is what makes the
/// reduced-motion branch possible: [DealInCard] owns its own controller and
/// duration, so the only way to honour the setting from here is to not build
/// it at all. The end state is identical either way; only the arrival differs.
///
/// Give every card a stable [key] so a later card joining the row does not
/// restart its neighbours' animations.
class DealtCard extends StatelessWidget {
  final Widget child;

  const DealtCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return child;
    return DealInCard(child: child);
  }
}
