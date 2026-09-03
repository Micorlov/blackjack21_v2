import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../data/tutorial_data.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/buttons.dart';
import '../widgets/google_signin_button.dart';
import '../widgets/how_to_play_sheet.dart';
import '../widgets/panel_card.dart';
import 'legal/legal_content.dart';
import 'legal/legal_screen.dart';
import 'shared/async_action.dart';
import 'shared/avatar_initial.dart';
import 'shared/confirm_dialog.dart';

/// Settings screen — account, avatar color, appearance, sound/haptics,
/// notifications, help, the legal documents and build version, and
/// reset-bankroll.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final avatarInitial = avatarInitialOf(state.displayName);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle('Settings'),
          const SectionLabel('Account'),
          _AccountPanel(
            signedIn: state.signedIn,
            avatarInitial: avatarInitial,
            avatarColor: state.avatarColor,
            avatarFrameGold: state.avatarFrameGold,
            displayName: state.displayName,
            photoUrl: state.photoUrl,
            onSignIn: notifier.signInGoogle,
            onSignOut: notifier.signOutUser,
          ),
          const SizedBox(height: 16),
          const SectionLabel('Avatar color'),
          _AvatarColorPanel(selected: state.avatarColor, onSelect: notifier.selectAvatarColor),
          const SizedBox(height: 16),
          const SectionLabel('Appearance'),
          _AppearancePanel(
            themeChoice: state.themeChoice,
            onSelectDefault: notifier.selectThemeDefault,
            onSelectOcean: notifier.selectThemeOcean,
            onSelectEmber: notifier.selectThemeEmber,
          ),
          const SizedBox(height: 16),
          const SectionLabel('Sound & haptics'),
          _TogglePanel(
            rows: [
              _ToggleRowData('Haptics', state.hapticsOn, notifier.toggleHaptics),
              _ToggleRowData('Sound effects', state.soundOn, notifier.toggleSound),
              // Greyed out while sound is off: voice plays through the same
              // output, so the switch would promise something it can't deliver.
              _ToggleRowData(
                'Voice call-outs',
                state.voiceOn,
                notifier.toggleVoice,
                sublabel: 'Your hand total, results and the sweep pot, spoken aloud',
                enabled: state.soundOn,
                disabledReason: 'Turn sound effects on to use voice call-outs',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel('Notifications'),
          // Three bare nouns told the player nothing about what each switch
          // would actually send them, which is the fastest way to have all
          // three turned off — or the whole permission revoked.
          _TogglePanel(
            rows: [
              _ToggleRowData(
                'Social',
                state.notifSocial,
                notifier.toggleNotifSocial,
                sublabel: 'When a friend joins your group, comes online or passes you',
              ),
              _ToggleRowData(
                'Leaderboard',
                state.notifLeaderboard,
                notifier.toggleNotifLeaderboard,
                sublabel: 'When your place on the hourly or daily board changes',
              ),
              _ToggleRowData(
                'Daily reminder',
                state.notifDaily,
                notifier.toggleNotifDaily,
                sublabel: 'One nudge a day, once your daily bonus is ready to claim',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel('Help'),
          _LinkPanel(
            rows: [
              _LinkRowData(
                label: 'How to play',
                sublabel: 'Rules, moves, payouts and the sweep pot',
                onTap: () => showHowToPlaySheet(context),
              ),
              _LinkRowData(
                label: 'Replay the tutorial',
                sublabel: 'Coaching cards on your next $kTutorialRounds hands',
                onTap: notifier.restartTutorial,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // "Example alerts" used to sit here: two static fake notification
          // cards, one of them announcing that a practice bot was online.
          // Marketing chrome in a settings surface, replaced by the legal and
          // build information a player (and a store reviewer) actually needs.
          const SectionLabel('About'),
          _LinkPanel(
            rows: [
              _LinkRowData(
                label: 'Terms of Service',
                sublabel: 'What you agree to by playing',
                onTap: () => showTerms(context),
              ),
              _LinkRowData(
                label: 'Privacy Policy',
                sublabel: 'What stays on this device, and what does not',
                onTap: () => showPrivacy(context),
              ),
            ],
            trailing: _InfoRow(label: 'Version', value: kAppVersionLabel),
          ),
          const SizedBox(height: 16),
          _ResetBankrollButton(onTap: () => _confirmResetBankroll(context, notifier)),
        ],
      ),
    );
  }
}

/// A bankroll is days of play. Losing it to a stray tap in a settings list —
/// which is what a bare, unconfirmed button invited — is not recoverable.
Future<void> _confirmResetBankroll(BuildContext context, GameNotifier notifier) async {
  final confirmed = await confirmAction(
    context,
    title: 'Reset your bankroll?',
    message:
        'Your chips go back to 1,000. Stats, awards, friends and cosmetics are untouched, '
        'but the chips you have now cannot be brought back.',
    confirmLabel: 'Reset chips',
    destructive: true,
  );
  if (confirmed) notifier.resetBankroll();
}

/// Signed-in profile row + sign-out, or a sign-in CTA when signed out.
class _AccountPanel extends StatelessWidget {
  final bool signedIn;
  final String avatarInitial;
  final Color avatarColor;
  final bool avatarFrameGold;
  final String displayName;
  final String? photoUrl;

  /// Both are awaited so the panel can show a pending state around them.
  final Future<void> Function() onSignIn;
  final Future<void> Function() onSignOut;

  const _AccountPanel({
    required this.signedIn,
    required this.avatarInitial,
    required this.avatarColor,
    required this.avatarFrameGold,
    required this.displayName,
    required this.photoUrl,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: signedIn ? _buildSignedIn(context) : _buildSignedOut(),
    );
  }

  /// Same pending treatment as onboarding's button: `authenticate()` plus the
  /// Firebase exchange is seconds of silence otherwise.
  Widget _buildSignedOut() {
    return GoogleSignInButton(
      child: AsyncActionBuilder(
        action: onSignIn,
        builder: (context, busy, run) => GoldButton(label: busy ? 'Signing in…' : 'Sign in', onPressed: run),
      ),
    );
  }

  Widget _buildSignedIn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AvatarCircle(
              initial: avatarInitial,
              color: avatarColor,
              size: 44,
              goldRing: avatarFrameGold,
              photoUrl: photoUrl,
            ),
            const SizedBox(width: 10),
            // Google account names run far longer than "Guest" — without a
            // flex the name ran straight off the panel's right edge.
            Expanded(
              child: Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.sora(16, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          // Signing out on a single tap dropped a signed-in player back to
          // guest — losing the live friends group until they signed in again.
          // Confirm first, then hold the button while both sign-outs resolve.
          child: AsyncActionBuilder(
            action: () => _confirmSignOut(context),
            builder: (context, busy, run) => OutlinedButton(
              onPressed: run,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 17),
                side: const BorderSide(color: AppColors.borderStrong),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: busy
                  ? const PendingSpinner(size: 20)
                  : Text('Sign out', style: AppText.sora(16, weight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out?',
      message:
          'Your chips and stats stay on this device, but you leave your friends group and '
          'your leaderboard entry until you sign back in.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (confirmed) await onSignOut();
  }
}

/// Wrap of avatar-color swatches; the swatch matching [selected] gets a gold
/// ring.
class _AvatarColorPanel extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onSelect;

  const _AvatarColorPanel({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: AppColors.avatarSwatchColors.asMap().entries.map((entry) {
          final color = entry.value;
          final isSelected = color == selected;
          // A bare coloured circle has no name at all. Numbering them is not
          // poetry, but it is announceable and it says which one is on.
          return Semantics(
            button: true,
            selected: isSelected,
            label: 'Avatar colour ${entry.key + 1} of ${AppColors.avatarSwatchColors.length}',
            child: InkWell(
              onTap: () => onSelect(color),
              customBorder: const CircleBorder(),
              child: Container(
                width: AppTouch.minTarget,
                height: AppTouch.minTarget,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: isSelected ? const [BoxShadow(color: AppColors.gold, spreadRadius: 2)] : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeOption {
  final String id;
  final String label;
  final RadialGradient gradient;
  final Color ringColor;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.id,
    required this.label,
    required this.gradient,
    required this.ringColor,
    required this.onTap,
  });
}

/// Default / Ocean / Ember appearance picker — reuses the felt swatch
/// gradients since `themeChoice` drives both the shop's table felt and this
/// selector.
class _AppearancePanel extends StatelessWidget {
  final String themeChoice;
  final VoidCallback onSelectDefault;
  final VoidCallback onSelectOcean;
  final VoidCallback onSelectEmber;

  const _AppearancePanel({
    required this.themeChoice,
    required this.onSelectDefault,
    required this.onSelectOcean,
    required this.onSelectEmber,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      _ThemeOption(
        id: 'default',
        label: 'Default',
        gradient: kFeltDefs[0].swatchGradient,
        ringColor: AppColors.gold,
        onTap: onSelectDefault,
      ),
      _ThemeOption(
        id: 'ocean',
        label: 'Ocean',
        gradient: kFeltDefs[1].swatchGradient,
        ringColor: const Color(0xFFF5C451),
        onTap: onSelectOcean,
      ),
      _ThemeOption(
        id: 'ember',
        label: 'Ember',
        gradient: kFeltDefs[2].swatchGradient,
        ringColor: const Color(0xFFFFB457),
        onTap: onSelectEmber,
      ),
    ];

    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 18),
            _ThemeSwatch(option: options[i], selected: themeChoice == options[i].id),
          ],
        ],
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final _ThemeOption option;
  final bool selected;

  const _ThemeSwatch({required this.option, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.label} table felt',
      excludeSemantics: true,
      child: InkWell(
        onTap: option.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppTouch.minTarget,
              height: AppTouch.minTarget,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: option.gradient,
                boxShadow: selected ? [BoxShadow(color: option.ringColor, spreadRadius: 2)] : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.label,
              style: AppText.sora(13, weight: FontWeight.w700, color: selected ? AppColors.gold : AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRowData {
  final String label;
  final bool value;
  final VoidCallback onToggle;

  /// Optional second line explaining what the switch does, for rows whose
  /// label alone doesn't say it.
  final String? sublabel;

  /// False for a row whose effect depends on another switch that is currently
  /// off — the row renders dimmed and ignores taps, keeping its own value.
  final bool enabled;

  /// Why the row is off-limits, spoken as a hint and shown in place of the
  /// sublabel. A disabled control with no stated reason is a dead end.
  final String? disabledReason;

  const _ToggleRowData(
    this.label,
    this.value,
    this.onToggle, {
    this.sublabel,
    this.enabled = true,
    this.disabledReason,
  });
}

/// Panel of label + `Switch` rows, separated by hairlines — used for both
/// "Sound & haptics" and "Notifications".
class _TogglePanel extends StatelessWidget {
  final List<_ToggleRowData> rows;

  const _TogglePanel({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
              ),
              child: _ToggleRow(data: rows[i]),
            ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final _ToggleRowData data;

  const _ToggleRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final sublabel = data.enabled ? data.sublabel : (data.disabledReason ?? data.sublabel);
    // Expanded, not the bare Row: the sublabel is a full sentence and ran off
    // the panel's right edge into the switch without a flex to wrap inside.
    final row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.label, style: AppText.sora(16, weight: FontWeight.w600)),
              if (sublabel != null) ...[
                const SizedBox(height: 2),
                Text(sublabel, style: AppText.sora(13, color: AppColors.textMuted)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: data.value,
          activeThumbColor: AppColors.gold,
          onChanged: data.enabled ? (_) => data.onToggle() : null,
        ),
      ],
    );

    // Merged so the switch is announced as "<label>, on" rather than as an
    // anonymous toggle sitting beside some text.
    final merged = MergeSemantics(child: row);

    // Dimming the whole row, rather than recolouring the label and switch
    // separately: the app theme resolves switch track colour on `selected`
    // alone, so a disabled switch keeps its gold and reads as live otherwise.
    return data.enabled ? merged : Opacity(opacity: 0.45, child: merged);
  }
}

class _LinkRowData {
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _LinkRowData({required this.label, required this.sublabel, required this.onTap});
}

/// Panel of tappable label + sublabel rows with a chevron, separated by
/// hairlines — the same shape as [_TogglePanel], for actions rather than
/// switches.
class _LinkPanel extends StatelessWidget {
  final List<_LinkRowData> rows;

  /// Optional non-interactive last row, e.g. the build version.
  final Widget? trailing;

  const _LinkPanel({required this.rows, this.trailing});

  @override
  Widget build(BuildContext context) {
    final extra = trailing;
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            InkWell(
              onTap: rows[i].onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                constraints: const BoxConstraints(minHeight: AppTouch.minTarget),
                decoration: BoxDecoration(
                  border: i < rows.length - 1 || extra != null
                      ? const Border(bottom: BorderSide(color: AppColors.border))
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rows[i].label, style: AppText.sora(16, weight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(rows[i].sublabel, style: AppText.sora(13, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    // The label already says where the row goes; the chevron is
                    // decoration on top of it.
                    const ExcludeSemantics(child: Icon(Icons.chevron_right, color: AppColors.textLabel)),
                  ],
                ),
              ),
            ),
          if (extra != null) Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: extra),
        ],
      ),
    );
  }
}

/// A read-only label/value row — used for the build version, which a player
/// needs to hand over in a bug report and had no way to find.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppText.sora(16, weight: FontWeight.w600)),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(value, style: AppText.mono(15, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ResetBankrollButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ResetBankrollButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppColors.lose.withValues(alpha: 0.12),
          side: const BorderSide(color: Color(0xFF3E211C)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          'Reset bankroll to 1,000 chips',
          style: AppText.sora(16, weight: FontWeight.w700, color: AppColors.lose),
        ),
      ),
    );
  }
}
