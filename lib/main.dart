import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';
import 'models/enums.dart';
import 'screens/cup_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/table_screen.dart';
import 'screens/tips_screen.dart';
import 'state/game_notifier.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/overlays.dart';
import 'widgets/rank_strip.dart';
import 'widgets/story_overlay.dart';
import 'widgets/web_viewport_scaler.dart';

/// Neither service is needed to render the first frame — the game plays offline
/// against built-in bots and sign-in is offered, not forced. Awaiting them
/// unbounded meant a stalled init left the player on the launch splash forever,
/// with no UI and no error: on a wiped install `GoogleSignIn.initialize` was
/// observed never returning. Bounding each one turns that into a slow start
/// rather than a dead app.
const _startupInitTimeout = Duration(seconds: 8);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initServices();
  runApp(const ProviderScope(child: BlackjackApp()));
}

Future<void> _initServices() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(_startupInitTimeout);
  } catch (error) {
    debugPrint('Firebase init did not complete, continuing offline: $error');
    return;
  }

  try {
    await GoogleSignIn.instance.initialize().timeout(_startupInitTimeout);
  } catch (error) {
    debugPrint('Google sign-in init did not complete, guest play still works: $error');
  }
}

class BlackjackApp extends StatelessWidget {
  const BlackjackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '21 Sweet Pot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Pinned to dark on purpose, for now.
      //
      // Both themes are built and contrast-tested (test/theme_contrast_test),
      // but the screens still read colours straight from `AppColors` rather
      // than from the palette, so `ThemeMode.system` would hand a light-mode
      // player a half-migrated UI: light chrome around dark hand-styled
      // panels. This flips to `ThemeMode.system` once the screens are
      // migrated to `AppPalette.of(context)`.
      themeMode: ThemeMode.dark,
      // The UI is a fixed-metric design port; unbounded system font scaling
      // breaks its pill rows and button labels, so cap it at +30%.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1,
        maxScaleFactor: 1.3,
        child: WebViewportScaler(child: child ?? const SizedBox.shrink()),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  Widget _buildScreen(AppScreen screen) {
    switch (screen) {
      case AppScreen.onboarding:
        return const OnboardingScreen();
      case AppScreen.tips:
        return const TipsScreen();
      case AppScreen.cup:
        return const CupScreen();
      case AppScreen.lobby:
        return const LobbyScreen();
      case AppScreen.table:
        return const TableScreen();
      case AppScreen.stats:
        return const StatsScreen();
      case AppScreen.friends:
        return const FriendsScreen();
      case AppScreen.shop:
        return const ShopScreen();
      case AppScreen.settings:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final showNav =
        state.screen != AppScreen.table &&
        state.screen != AppScreen.onboarding &&
        state.screen != AppScreen.tips &&
        state.screen != AppScreen.cup;

    void onNavSelect(AppScreen screen) {
      switch (screen) {
        case AppScreen.lobby:
          notifier.goLobby();
        case AppScreen.stats:
          notifier.goStats();
        case AppScreen.friends:
          notifier.goFriends();
        case AppScreen.shop:
          notifier.goShop();
        case AppScreen.settings:
          notifier.goSettings();
        case AppScreen.onboarding:
        case AppScreen.tips:
        case AppScreen.cup:
        case AppScreen.table:
          break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: state.screen != AppScreen.onboarding && state.screen != AppScreen.tips,
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                const RankStrip(),
                Expanded(child: _buildScreen(state.screen)),
                if (showNav)
                  AppBottomNavBar(current: state.screen, onSelect: onNavSelect),
              ],
            ),
            ToastBanner(text: state.toast),
            ReactionFloatOverlay(
              text: state.reactionFloat,
              triggerId: state.reactionId,
            ),
            if (state.activeStoryId != null)
              const Positioned.fill(child: StoryOverlay()),
          ],
        ),
      ),
    );
  }
}
