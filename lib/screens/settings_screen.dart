import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../data/tutorial_data.dart';
import '../l10n/generated/app_localizations.dart';
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
    final t = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(t.settingsTitle),
          SectionLabel(t.settingsSectionAccount),
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
          SectionLabel(t.settingsSectionAvatarColor),
          _AvatarColorPanel(selected: state.avatarColor, onSelect: notifier.selectAvatarColor),
          const SizedBox(height: 16),
          SectionLabel(t.settingsSectionAppearance),
          _AppearancePanel(
            themeChoice: state.themeChoice,
            onSelectDefault: notifier.selectThemeDefault,
            onSelectOcean: notifier.selectThemeOcean,
            onSelectEmber: notifier.selectThemeEmber,
          ),
          const SizedBox(height: 16),
          SectionLabel(t.settingsSectionLanguage),
          _LanguagePanel(selected: state.languageOverride, onSelect: notifier.setLanguage),
          const SizedBox(height: 16),
          SectionLabel(t.settingsSectionSoundHaptics),
          _TogglePanel(
            rows: [
              _ToggleRowData(t.hapticsLabel, state.hapticsOn, notifier.toggleHaptics),
              _ToggleRowData(t.soundEffectsLabel, state.soundOn, notifier.toggleSound),
              // Greyed out while sound is off: voice plays through the same
              // output, so the switch would promise something it can't deliver.
              _ToggleRowData(
                t.voiceCalloutsLabel,
                state.voiceOn,
                notifier.toggleVoice,
                sublabel: t.voiceCalloutsSublabel,
                enabled: state.soundOn,
                disabledReason: t.voiceCalloutsDisabledReason,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionLabel(t.settingsSectionNotifications),
          // Three bare nouns told the player nothing about what each switch
          // would actually send them, which is the fastest way to have all
          // three turned off — or the whole permission revoked.
          _TogglePanel(
            rows: [
              _ToggleRowData(
                t.notifSocialLabel,
                state.notifSocial,
                notifier.toggleNotifSocial,
                sublabel: t.notifSocialSublabel,
              ),
              _ToggleRowData(
                t.notifLeaderboardLabel,
                state.notifLeaderboard,
                notifier.toggleNotifLeaderboard,
                sublabel: t.notifLeaderboardSublabel,
              ),
              _ToggleRowData(
                t.notifDailyLabel,
                state.notifDaily,
                notifier.toggleNotifDaily,
                sublabel: t.notifDailySublabel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Deliberately its own section rather than a line buried in
          // Notifications: it is the only switch here that changes what leaves
          // the device, so it gets stated plainly and can be turned off.
          //
          // Not localized yet — the rest of this screen is, but adding ARB
          // keys for ten locales belongs with the next translation pass rather
          // than half-done here.
          const SectionLabel('PRIVACY'),
          _TogglePanel(
            rows: [
              _ToggleRowData(
                'Usage & crash reports',
                state.analyticsOn,
                () => notifier.setAnalytics(!state.analyticsOn),
                sublabel: 'Anonymous counts of hands played and crashes, so problems can be found and '
                    'fixed. Never your name, your group code or your chat.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionLabel(t.settingsSectionHelp),
          _LinkPanel(
            rows: [
              _LinkRowData(
                label: t.howToPlayLabel,
                sublabel: t.howToPlaySublabel,
                onTap: () => showHowToPlaySheet(context),
              ),
              _LinkRowData(
                label: t.replayTutorialLabel,
                sublabel: t.replayTutorialSublabel(kTutorialRounds),
                onTap: notifier.restartTutorial,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // "Example alerts" used to sit here: two static fake notification
          // cards, one of them announcing that a practice bot was online.
          // Marketing chrome in a settings surface, replaced by the legal and
          // build information a player (and a store reviewer) actually needs.
          SectionLabel(t.settingsSectionAbout),
          _LinkPanel(
            rows: [
              _LinkRowData(
                label: t.termsOfServiceLabel,
                sublabel: t.termsOfServiceSublabel,
                onTap: () => showTerms(context),
              ),
              _LinkRowData(
                label: t.privacyPolicyLabel,
                sublabel: t.privacyPolicySublabel,
                onTap: () => showPrivacy(context),
              ),
            ],
            trailing: _InfoRow(label: t.versionLabel, value: kAppVersionLabel),
          ),
        ],
      ),
    );
  }
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
      child: signedIn ? _buildSignedIn(context) : _buildSignedOut(context),
    );
  }

  /// Same pending treatment as onboarding's button: `authenticate()` plus the
  /// Firebase exchange is seconds of silence otherwise.
  Widget _buildSignedOut(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GoogleSignInButton(
      child: AsyncActionBuilder(
        action: onSignIn,
        builder: (context, busy, run) => GoldButton(label: busy ? t.signingIn : t.signIn, onPressed: run),
      ),
    );
  }

  Widget _buildSignedIn(BuildContext context) {
    final t = AppLocalizations.of(context);
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
                  : Text(t.signOut, style: AppText.sora(16, weight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final confirmed = await confirmAction(
      context,
      title: t.signOutConfirmTitle,
      message: t.signOutConfirmMessage,
      confirmLabel: t.signOut,
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
    final t = AppLocalizations.of(context);
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
            label: t.avatarColorSemanticLabel(entry.key + 1, AppColors.avatarSwatchColors.length),
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
    final t = AppLocalizations.of(context);
    final options = [
      _ThemeOption(
        id: 'default',
        label: t.themeDefault,
        gradient: kFeltDefs[0].swatchGradient,
        ringColor: AppColors.gold,
        onTap: onSelectDefault,
      ),
      _ThemeOption(
        id: 'ocean',
        label: t.themeOcean,
        gradient: kFeltDefs[1].swatchGradient,
        ringColor: const Color(0xFFF5C451),
        onTap: onSelectOcean,
      ),
      _ThemeOption(
        id: 'ember',
        label: t.themeEmber,
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
      label: AppLocalizations.of(context).themeFeltSemanticLabel(option.label),
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

/// Language picker: "match device" plus one row per locale this build ships
/// ARB translations for. Voice call-outs follow the same choice — see
/// `GameNotifier.setLanguage`.
class _LanguagePanel extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _LanguagePanel({required this.selected, required this.onSelect});

  static String _displayName(AppLocalizations t, String code) => switch (code) {
    'en' => t.languageNameEn,
    'es' => t.languageNameEs,
    'fr' => t.languageNameFr,
    'de' => t.languageNameDe,
    'pt' => t.languageNamePt,
    'ru' => t.languageNameRu,
    'zh' => t.languageNameZh,
    'ja' => t.languageNameJa,
    'he' => t.languageNameHe,
    'ar' => t.languageNameAr,
    _ => code,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final codes = [
      for (final locale in AppLocalizations.supportedLocales) locale.languageCode,
    ];
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = -1; i < codes.length; i++)
            _LanguageRow(
              // i == -1 is the "match device" row, value null.
              label: i < 0 ? t.languageSystemDefault : _displayName(t, codes[i]),
              isSelected: i < 0 ? selected == null : selected == codes[i],
              isLast: i == codes.length - 1,
              onTap: () => onSelect(i < 0 ? null : codes[i]),
            ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.label,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          constraints: const BoxConstraints(minHeight: AppTouch.minTarget),
          decoration: BoxDecoration(
            border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Expanded(child: Text(label, style: AppText.sora(16, weight: FontWeight.w600))),
                if (isSelected) const Icon(Icons.check, color: AppColors.gold),
              ],
            ),
          ),
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

