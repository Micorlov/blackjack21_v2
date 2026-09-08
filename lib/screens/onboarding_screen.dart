import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/buttons.dart';
import '../widgets/google_signin_button.dart';
import 'legal/legal_screen.dart';
import 'shared/async_action.dart';

/// Sign-in / guest-entry screen shown before a player reaches the lobby.
/// Ported 1:1 from the `isOnboarding` block in `Blackjack 21 v2.dc.html`
/// (lines 26-40): radial felt background, gold "21" mark, title, subtitle,
/// Google sign-in, guest link, and a fixed terms disclaimer.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key, this.isWeb = kIsWeb});

  /// Overridable for tests; defaults to the real platform.
  final bool isWeb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    // Only the voice flag is watched: this screen is otherwise static, and
    // rebuilding it on every chip or friend update would be wasted work.
    final voiceOn = ref.watch(gameProvider.select((s) => s.voiceOn));

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            colors: [Color(0xFF175943), Color(0xFF0E3B2E), Color(0xFF0A2018)],
            stops: [0, 0.45, 1],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Decorative faint suit glyphs (background chrome only) — excluded
            // from the semantics tree so a screen reader doesn't open the app
            // by reading two bare suit symbols aloud.
            Positioned(
              top: -40,
              left: -30,
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: -15 * 3.14159265 / 180,
                  child: Text(
                    '♠',
                    style: TextStyle(fontSize: 220, height: 1, color: Colors.white.withValues(alpha: 0.03)),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -40,
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: 12 * 3.14159265 / 180,
                  child: Text(
                    '♦',
                    style: TextStyle(fontSize: 240, height: 1, color: AppColors.gold.withValues(alpha: AppAlpha.ghost)),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                // The consent block is the last row of the scrolling column
                // rather than a pinned overlay. Pinned, it grew tall enough —
                // once Terms and Privacy became real, full-size buttons —
                // to sit on top of the voice toggle and swallow its taps.
                //
                // LayoutBuilder + Center: the Column below is intrinsically
                // narrower than its bounds (it isn't stretched), so without an
                // explicit Center it renders pinned to the top-left instead of
                // the middle of the screen. ConstrainedBox + scroll view keeps
                // it centered when it fits, and merely scrollable instead of
                // overflowing when a short viewport doesn't leave it enough
                // height.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                margin: const EdgeInsets.only(bottom: 22),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '21',
                                  style: AppText.mono(33, weight: FontWeight.w700, color: AppColors.goldInk),
                                ),
                              ),
                              Text(
                                'Blackjack 21',
                                textAlign: TextAlign.center,
                                style: AppText.serifItalic(48, height: 1.05),
                              ),
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 280),
                                child: Text(
                                  'Beat the dealer, climb the leaderboard, and challenge your friends at the table.',
                                  textAlign: TextAlign.center,
                                  style: AppText.sora(
                                    18,
                                    color: AppColors.textPrimary.withValues(alpha: AppAlpha.scrim),
                                    height: 1.55,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 300),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: GoogleSignInButton(child: _GoogleSignInCta(onSignIn: notifier.signInGoogle)),
                                ),
                              ),
                              // Guest mode is local-only (no Firebase account), so it's
                              // hidden on web where sign-in is required.
                              if (!isWeb) ...[
                                const SizedBox(height: 12),
                                TextLinkButton(
                                  label: 'Play as Guest',
                                  onPressed: () => notifier.playGuest(),
                                  color: const Color(0xFFC7C3B7),
                                  fontSize: 16,
                                  underline: true,
                                ),
                              ],
                              // Offered up front because the table talks from
                              // the very first hand — a player who wants it
                              // silent shouldn't have to hear it once and then
                              // go hunting through Settings.
                              const SizedBox(height: 24),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 300),
                                child: _VoiceToggle(value: voiceOn, onToggle: notifier.toggleVoice),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const _ConsentLine(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Google button, with the pending state it never had.
///
/// `authenticate()` opens a system account picker and then makes two network
/// round trips; the button used to sit fully enabled and unchanged for all of
/// it, so a player who saw nothing happen tapped again — or gave up on the
/// install. While the call is in flight the label becomes "Signing in…", the
/// spinner replaces the mark, and the tap is refused rather than queued.
class _GoogleSignInCta extends StatelessWidget {
  final Future<void> Function() onSignIn;

  const _GoogleSignInCta({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return AsyncActionBuilder(
      action: onSignIn,
      builder: (context, busy, run) => Semantics(
        button: true,
        enabled: !busy,
        // Spoken while the round trip runs, so a screen-reader user gets the
        // same "something is happening" the spinner gives everyone else.
        hint: busy ? 'Signing in, please wait' : null,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: run,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: busy
                        ? const PendingSpinner(size: 20, color: Color(0xFF4285F4))
                        : ExcludeSemantics(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE4E4E4)),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'G',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF4285F4)),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      busy ? 'Signing in…' : 'Continue with Google',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The consent line — now a promise the app can keep.
///
/// It used to assert that the player had agreed to documents that existed
/// nowhere in the app or on the web. The documents are real and bundled now
/// ([kTermsDoc], [kPrivacyDoc]), and they are reached through two full-size
/// buttons rather than 13px inline spans nobody with a thumb can hit.
class _ConsentLine extends StatelessWidget {
  const _ConsentLine();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'By continuing you agree to the Terms & Privacy Policy.',
          textAlign: TextAlign.center,
          style: AppText.sora(13, color: AppColors.textPrimary.withValues(alpha: 0.7)),
        ),
        // Wrap, not Row: at the largest text scale on a 320pt phone the two
        // labels no longer fit on one line, and stacking beats ellipsing the
        // only route to the documents.
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextLinkButton(
              label: 'Terms',
              onPressed: () => showTerms(context),
              color: AppColors.gold,
              fontSize: 14,
              underline: true,
            ),
            const SizedBox(width: AppSpacing.sm),
            TextLinkButton(
              label: 'Privacy',
              onPressed: () => showPrivacy(context),
              color: AppColors.gold,
              fontSize: 14,
              underline: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// The one setting offered before the player is in: whether the table speaks.
/// A translucent pill rather than a Settings-style panel row, so it reads as
/// an option on the felt instead of a form field.
class _VoiceToggle extends StatelessWidget {
  final bool value;
  final VoidCallback onToggle;

  const _VoiceToggle({required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    // Merged so the switch is announced with the label it belongs to, instead
    // of as an unnamed toggle sitting next to some text.
    return MergeSemantics(
      child: Material(
        color: Colors.black.withValues(alpha: AppAlpha.tint),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
            child: Row(
              children: [
                Icon(
                  value ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  size: 20,
                  color: value ? AppColors.gold : AppColors.textPrimary.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 10),
                // Expanded, not Flexible: it pins the switch to the pill's right
                // edge instead of leaving dead space after it, and still lets a
                // large text scale wrap the label rather than overflow.
                Expanded(
                  child: Text(
                    'Voice call-outs',
                    style: AppText.sora(
                      15,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary.withValues(alpha: value ? 0.95 : 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Switch(value: value, activeThumbColor: AppColors.gold, onChanged: (_) => onToggle()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
