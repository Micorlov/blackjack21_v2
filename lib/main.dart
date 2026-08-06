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
import 'theme/app_text_styles.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/overlays.dart';
import 'widgets/rank_strip.dart';
import 'widgets/story_overlay.dart';
import 'widgets/web_viewport_scaler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();
  runApp(const ProviderScope(child: BlackjackApp()));
}

class BlackjackApp extends StatelessWidget {
  const BlackjackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blackjack 21',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: Brightness.dark,
        ),
        textTheme: TextTheme(bodyMedium: AppText.sora(15)),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.gold
                : AppColors.border,
          ),
        ),
      ),
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
