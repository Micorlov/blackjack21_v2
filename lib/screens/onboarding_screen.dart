import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/buttons.dart';
import '../widgets/google_signin_button.dart';

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
            // Decorative faint suit glyphs (background chrome only).
            Positioned(
              top: -40,
              left: -30,
              child: Transform.rotate(
                angle: -15 * 3.14159265 / 180,
                child: Text(
                  '♠',
                  style: TextStyle(
                    fontSize: 220,
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -40,
              child: Transform.rotate(
                angle: 12 * 3.14159265 / 180,
                child: Text(
                  '♦',
                  style: TextStyle(
                    fontSize: 240,
                    height: 1,
                    color: AppColors.gold.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                // LayoutBuilder + Center: the Column below is intrinsically
                // narrower than this Stack child's own bounds (it isn't
                // stretched), so without an explicit Center it renders
                // pinned to the Stack's default top-left alignment instead
                // of the middle of the screen. ConstrainedBox + scroll view
                // keeps it centered when it fits, and merely scrollable
                // instead of overflowing when a short/wide web viewport
                // doesn't leave it enough height.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                margin: const EdgeInsets.only(bottom: 22),
                                decoration: BoxDecoration(
                                  gradient: AppColors.goldGradient,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.goldDark.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '21',
                                  style: AppText.mono(
                                    33,
                                    weight: FontWeight.w700,
                                    color: AppColors.goldInk,
                                  ),
                                ),
                              ),
                              Text(
                                '21 Sweet Pot',
                                textAlign: TextAlign.center,
                                style: AppText.serifItalic(48, height: 1.05),
                              ),
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 280,
                                ),
                                child: Text(
                                  'Beat the dealer, climb the leaderboard, and challenge your friends at the table.',
                                  textAlign: TextAlign.center,
                                  style: AppText.sora(
                                    18,
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.85,
                                    ),
                                    height: 1.55,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 300,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: GoogleSignInButton(
                                    child: Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () => notifier.signInGoogle(),
                                        child: Padding(
                                          padding: const EdgeInsets.all(15),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white,
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFE4E4E4,
                                                    ),
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: const Text(
                                                  'G',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF4285F4),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Text(
                                                  'Continue with Google',
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF1A1A1A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 28,
              right: 28,
              child: Text(
                'By continuing you agree to the Terms & Privacy Policy.',
                textAlign: TextAlign.center,
                style: AppText.sora(
                  13,
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
