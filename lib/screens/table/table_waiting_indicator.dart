import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';

/// Centered pulsing-dot + status text, used for the `npcs` ("{name} is
/// playing…") and `dealer` ("Dealer is playing…") transitional phases.
class TableWaitingIndicator extends StatefulWidget {
  final String text;
  final double fontSize;

  const TableWaitingIndicator({super.key, required this.text, this.fontSize = 17});

  @override
  State<TableWaitingIndicator> createState() => _TableWaitingIndicatorState();
}

class _TableWaitingIndicatorState extends State<TableWaitingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.pulse)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 38),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
            ),
          ),
          const SizedBox(width: 10),
          // Player names are user data and the line is a single sentence, so
          // it has to survive a long name on a narrow screen.
          Flexible(
            child: Text(
              widget.text,
              style: AppText.sora(widget.fontSize, color: AppColors.textPrimary.withValues(alpha: 0.85)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
