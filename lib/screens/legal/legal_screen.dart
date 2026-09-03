import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'legal_content.dart';

/// Reader for [kTermsDoc] and [kPrivacyDoc].
///
/// A pushed route rather than another `AppScreen` enum case: these are read
/// once and dismissed, they must be reachable from onboarding — which is
/// outside the bottom-nav shell entirely — and Back has to return the player
/// exactly where they were, mid sign-up.
class LegalScreen extends StatelessWidget {
  final LegalDoc doc;

  const LegalScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    // Icon-only, so it needs a spoken name of its own.
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(doc.title, style: AppText.serifItalic(28, height: 1.15))),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.updated, style: AppText.caption()),
                    const SizedBox(height: AppSpacing.md),
                    Text(doc.intro, style: AppText.body()),
                    for (final section in doc.sections) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text(section.heading, style: AppText.title(color: AppColors.gold)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(section.body, style: AppText.body(color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens one of the legal documents.
///
/// The transition duration goes through [AppMotion] so a player with
/// reduced motion enabled gets the page immediately instead of a slide.
Future<void> showLegalDoc(BuildContext context, LegalDoc doc) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: AppMotion.durationOf(context, AppMotion.base),
      reverseTransitionDuration: AppMotion.durationOf(context, AppMotion.fast),
      pageBuilder: (_, _, _) => LegalScreen(doc: doc),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
        child: child,
      ),
    ),
  );
}

Future<void> showTerms(BuildContext context) => showLegalDoc(context, kTermsDoc);

Future<void> showPrivacy(BuildContext context) => showLegalDoc(context, kPrivacyDoc);
