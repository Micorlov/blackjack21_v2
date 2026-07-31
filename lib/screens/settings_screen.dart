import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/buttons.dart';
import '../widgets/panel_card.dart';

/// Settings screen — account, avatar color, appearance, sound/haptics,
/// notifications, example alert previews, and reset-bankroll. Ported from
/// the `screen==='settings'` block in `Blackjack 21 v2.dc.html`
/// (lines 730-821).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final avatarInitial = _avatarInitialOf(state.displayName);

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
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel('Notifications'),
          _TogglePanel(
            rows: [
              _ToggleRowData('Social', state.notifSocial, notifier.toggleNotifSocial),
              _ToggleRowData('Leaderboard', state.notifLeaderboard, notifier.toggleNotifLeaderboard),
              _ToggleRowData('Daily reminder', state.notifDaily, notifier.toggleNotifDaily),
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel('Example alerts'),
          const _ExampleAlerts(),
          const SizedBox(height: 16),
          _ResetBankrollButton(onTap: notifier.resetBankroll),
        ],
      ),
    );
  }
}

String _avatarInitialOf(String displayName) {
  final name = displayName.isEmpty ? 'G' : displayName;
  return name[0].toUpperCase();
}

/// Signed-in profile row + sign-out, or a sign-in CTA when signed out.
class _AccountPanel extends StatelessWidget {
  final bool signedIn;
  final String avatarInitial;
  final Color avatarColor;
  final bool avatarFrameGold;
  final String displayName;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const _AccountPanel({
    required this.signedIn,
    required this.avatarInitial,
    required this.avatarColor,
    required this.avatarFrameGold,
    required this.displayName,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: signedIn ? _buildSignedIn() : GoldButton(label: 'Sign in', onPressed: onSignIn),
    );
  }

  Widget _buildSignedIn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AvatarCircle(initial: avatarInitial, color: avatarColor, size: 44, goldRing: avatarFrameGold),
            const SizedBox(width: 10),
            Text(displayName, style: AppText.sora(16, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onSignOut,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 17),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Sign out', style: AppText.sora(16, weight: FontWeight.w700)),
          ),
        ),
      ],
    );
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
        children: AppColors.avatarSwatchColors.map((color) {
          final isSelected = color == selected;
          return InkWell(
            onTap: () => onSelect(color),
            customBorder: const CircleBorder(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: isSelected ? const [BoxShadow(color: AppColors.gold, spreadRadius: 2)] : null,
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
    return InkWell(
      onTap: option.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
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
    );
  }
}

class _ToggleRowData {
  final String label;
  final bool value;
  final VoidCallback onToggle;

  const _ToggleRowData(this.label, this.value, this.onToggle);
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rows[i].label, style: AppText.sora(16, weight: FontWeight.w600)),
                  Switch(value: rows[i].value, activeThumbColor: AppColors.gold, onChanged: (_) => rows[i].onToggle()),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Static preview cards showing what a couple of notification types look
/// like — no interaction.
class _ExampleAlerts extends StatelessWidget {
  const _ExampleAlerts();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AlertPreviewCard(
          icon: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.trending_up, size: 15, color: AppColors.gold),
          ),
          title: '3-win streak! Keep it up',
          subtitle: 'Blackjack 21 · now',
        ),
        const SizedBox(height: 8),
        _AlertPreviewCard(
          icon: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withValues(alpha: 0.15)),
            alignment: Alignment.center,
            child: Text(
              'M',
              style: AppText.sora(14, weight: FontWeight.w800, color: AppColors.gold),
            ),
          ),
          title: 'Maya T. is online',
          subtitle: 'Blackjack 21 · 2m ago',
        ),
      ],
    );
  }
}

class _AlertPreviewCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;

  const _AlertPreviewCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(radius: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.sora(14.5, weight: FontWeight.w800)),
                Text(subtitle, style: AppText.sora(13, color: AppColors.textMuted)),
              ],
            ),
          ),
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
