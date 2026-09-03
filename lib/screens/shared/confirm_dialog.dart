import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Asks before an action the player cannot undo.
///
/// "Reset bankroll to 1,000 chips" and "Sign out" both fired on a single tap —
/// a mis-tap in Settings wiped a bankroll the player had spent days building.
/// The theme styles `Dialog` (surface, radius, measured scrim), so this is a
/// plain [AlertDialog] rather than a hand-rolled sheet.
///
/// Returns true only when the player explicitly confirms; dismissing by
/// tapping the scrim or pressing Back counts as "no".
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final palette = AppPalette.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel, style: AppText.title(color: palette.mutedForeground)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel,
            style: AppText.title(color: destructive ? _destructiveText(palette) : palette.accentText),
          ),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

/// Red *as text* on the dialog surface.
///
/// `palette.lose` is a fill colour: on the dark card it measures 3.45:1, which
/// fails body text. The lighter outcome red the felt already uses clears 4.5:1
/// there. On paper the relationship inverts — the light theme's deeper red is
/// the readable one — so the choice is made per brightness rather than by
/// picking one red and hoping.
Color _destructiveText(AppPalette palette) {
  return palette.brightness == Brightness.dark ? palette.loseOnFelt : palette.lose;
}
