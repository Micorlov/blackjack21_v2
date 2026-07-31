import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

const List<RoundPhase> _kPhaseOrder = [
  RoundPhase.betting,
  RoundPhase.npcs,
  RoundPhase.playing,
  RoundPhase.dealer,
  RoundPhase.settlement,
];

const Map<RoundPhase, String> _kPhaseLabels = {
  RoundPhase.betting: 'Bet',
  RoundPhase.npcs: 'Table',
  RoundPhase.playing: 'You',
  RoundPhase.dealer: 'Dealer',
  RoundPhase.settlement: 'Result',
};

/// The 4-step phase tracker pills. `insurance` visually counts as the
/// "Table" step (same index as `npcs`), matching the source design.
class TablePhaseSteps extends StatelessWidget {
  final RoundPhase phase;

  const TablePhaseSteps({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    final curPhase = phase == RoundPhase.insurance ? RoundPhase.npcs : phase;
    final curIdx = _kPhaseOrder.indexOf(curPhase).clamp(0, _kPhaseOrder.length - 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      // Five pills of fixed-metric text: on a narrow phone (or with large
      // system fonts) the row is wider than the screen, so shrink the whole
      // tracker rather than clipping the last step off the edge.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _kPhaseOrder.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              _PhasePill(label: _kPhaseLabels[_kPhaseOrder[i]]!, isCurrent: i == curIdx, isPast: i < curIdx),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhasePill extends StatelessWidget {
  final String label;
  final bool isCurrent;
  final bool isPast;

  const _PhasePill({required this.label, required this.isCurrent, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final bg = isCurrent
        ? AppColors.gold.withValues(alpha: 0.18)
        : (isPast ? AppColors.gold.withValues(alpha: 0.07) : Colors.transparent);
    final color = isCurrent
        ? AppColors.gold
        : (isPast ? AppColors.gold.withValues(alpha: 0.62) : AppColors.textPrimary.withValues(alpha: 0.58));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: AppText.mono(15, letterSpacing: 0.3, color: color)),
    );
  }
}
