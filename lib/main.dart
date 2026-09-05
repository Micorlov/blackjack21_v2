import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'models/enums.dart';
import 'models/game_state.dart';
import 'screens/friends_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/table_screen.dart';
import 'state/game_notifier.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/app_lifecycle_bridge.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/overlays.dart';
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
  // Resolves an invite link's `/join/CODE` from the real URL path instead of
  // the default `#/` hash fragment — see utils/invite_link.dart.
  if (kIsWeb) usePathUrlStrategy();
  await _initServices();
  runApp(const ProviderScope(child: BlackjackApp()));
}

Future<void> _initServices() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).timeout(_startupInitTimeout);
  } catch (error) {
    debugPrint('Firebase init did not complete, continuing offline: $error');
    return;
  }

  _installErrorHandlers();

  try {
    await GoogleSignIn.instance.initialize().timeout(_startupInitTimeout);
  } catch (error) {
    debugPrint('Google sign-in init did not complete, guest play still works: $error');
  }
}

/// Routes framework and platform errors to Crashlytics.
///
/// The app shipped with neither handler: a Flutter framework error printed a
/// red box in debug and did nothing in release, and an error off the main
/// isolate simply vanished. Every failure a real player hit was invisible, so
/// there was no way to tell a broken build from a quiet week.
///
/// Only installed on platforms Crashlytics supports — it has no web
/// implementation, and calling into it there throws on first use.
void _installErrorHandlers() {
  if (kIsWeb) return;
  try {
    final crashlytics = FirebaseCrashlytics.instance;
    final priorOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      priorOnError?.call(details);
      crashlytics.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (error) {
    debugPrint('Crash reporting unavailable: $error');
  }
}

class BlackjackApp extends ConsumerWidget {
  const BlackjackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `select` so this only rebuilds the whole MaterialApp (and its Navigator)
    // when the language actually changes, not on every other state change.
    final languageOverride = ref.watch(gameProvider.select((s) => s.languageOverride));
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: languageOverride == null ? null : Locale(languageOverride),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
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
      // Capped at +30%, and this is now the app's weakest accessibility point
      // rather than a settled decision.
      //
      // The felt no longer needs the cap: it used to disable text scaling
      // outright (`MediaQuery.withNoTextScaling`), so every live number in the
      // game — dealer total, bet, hand total, balance — ignored the system
      // setting entirely. It is now constraint-driven and scales properly.
      //
      // The cap survives because of the screens *around* the table. Measured
      // at 1.5x, the lobby's story tiles overflow by 2px and the daily-bonus
      // dialog by 21px; at 1.6x and 2.0x the failures spread widely (311
      // overflow cases across the sweep). Raising this is a real accessibility
      // win and the next thing worth doing — it needs those screens reworked
      // first, not a bigger number here.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1,
        maxScaleFactor: 1.3,
        child: WebViewportScaler(child: child ?? const SizedBox.shrink()),
      ),
      // Not `home:` — the app has exactly one screen-shaped route (the
      // enum-driven `AppShell`, never a `Navigator` stack), but an invite
      // link's `/join/CODE` still arrives as a named route: on cold start via
      // `onGenerateInitialRoutes`, or — because `MainActivity` is
      // `singleTop` — as a fresh `onGenerateRoute` call while the app is
      // already running. `_DeepLinkGate` reads the route once, hands it to
      // the notifier, and always renders the same shell either way.
      onGenerateInitialRoutes: (initialRoute) => [_deepLinkRoute(initialRoute)],
      onGenerateRoute: (settings) => _deepLinkRoute(settings.name ?? '/'),
    );
  }
}

/// One `PageRouteBuilder` for every route this app ever navigates to,
/// [route] included only so [_DeepLinkGate] can parse it. A route pushed
/// while the app is already running (the `onGenerateRoute` path) pops itself
/// on the next frame — the shell underneath already reflects whatever the
/// link changed, so a second stacked copy of it would only be a dead page a
/// user has to Back out of.
Route<void> _deepLinkRoute(String route) {
  return PageRouteBuilder<void>(
    settings: RouteSettings(name: route),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => _DeepLinkGate(route: route),
  );
}

/// Hands an incoming route to [GameNotifier.handleIncomingLink] once, then
/// renders the app shell. Split out from [BlackjackApp] because reading the
/// notifier this way needs a [WidgetRef], which a raw `pageBuilder` does not
/// have.
class _DeepLinkGate extends ConsumerStatefulWidget {
  final String route;

  const _DeepLinkGate({required this.route});

  @override
  ConsumerState<_DeepLinkGate> createState() => _DeepLinkGateState();
}

class _DeepLinkGateState extends ConsumerState<_DeepLinkGate> {
  @override
  void initState() {
    super.initState();
    if (widget.route == '/') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(gameProvider.notifier).handleIncomingLink(widget.route);
      // This route only ever existed to deliver the link; a route pushed
      // while the app was already running (the framework calls
      // `onGenerateRoute` again on `MainActivity`'s `singleTop` re-delivery)
      // has somewhere to pop back to. The very first route of the app
      // — cold start — never does, and `Navigator.canPop` guards that.
      final navigator = Navigator.maybeOf(context);
      if (navigator != null && navigator.canPop()) navigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) => const AppLifecycleBridge(child: AppShell());
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  Widget _buildScreen(AppScreen screen) {
    switch (screen) {
      case AppScreen.onboarding:
        return const OnboardingScreen();
      case AppScreen.lobby:
        return const LobbyScreen();
      case AppScreen.table:
        return const TableScreen();
      case AppScreen.stats:
        return const StatsScreen();
      case AppScreen.friends:
        return const FriendsScreen();
      case AppScreen.settings:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Screen views are logged from here rather than from each `goX()` method:
    // navigation is a single enum field, so one listener covers every route
    // into every screen, including the back button and deep links.
    ref.listen(gameProvider.select((s) => s.screen), (previous, next) {
      if (previous != next) ref.read(gameProvider.notifier).logScreenView(next);
    });

    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final showNav = state.screen != AppScreen.table && state.screen != AppScreen.onboarding;

    void onNavSelect(AppScreen screen) {
      switch (screen) {
        case AppScreen.lobby:
          notifier.goLobby();
        case AppScreen.stats:
          notifier.goStats();
        case AppScreen.friends:
          notifier.goFriends();
        case AppScreen.settings:
          notifier.goSettings();
        case AppScreen.onboarding:
        case AppScreen.table:
          break;
      }
    }

    // Android Back, for the whole app.
    //
    // Navigation here is an enum on the state, not a `Navigator` stack, so
    // there is nothing for the framework to pop and Back quit the app from
    // wherever the player happened to be. Fixing it only on the table left the
    // same trap everywhere else: leaving Stats, Friends or Settings still
    // dropped the player onto their home screen. Found on a real device.
    //
    // Handled in one place rather than per screen so the peel order is
    // consistent: overlays first, then the screen, then the app.
    final canLeaveApp =
        !state.tableChatOpen &&
        !state.tableMenuOpen &&
        (state.screen == AppScreen.lobby || state.screen == AppScreen.onboarding);

    return PopScope(
      canPop: canLeaveApp,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (state.tableChatOpen) {
          notifier.toggleTableChat();
          return;
        }
        if (state.tableMenuOpen) {
          notifier.toggleTableMenu();
          return;
        }
        switch (state.screen) {
          // `exitTable` rather than `goLobby`: it also cancels the round's
          // timers, the same way the header's chevron does.
          case AppScreen.table:
            notifier.exitTable();
          case AppScreen.stats:
          case AppScreen.friends:
          case AppScreen.settings:
            notifier.goLobby();
          // Nothing sits behind these, so Back means "leave", which `canPop`
          // has already allowed.
          case AppScreen.lobby:
          case AppScreen.onboarding:
            break;
        }
      },
      child: _buildShell(context, state, onNavSelect, showNav),
    );
  }

  Widget _buildShell(BuildContext context, GameState state, void Function(AppScreen) onNavSelect, bool showNav) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: state.screen != AppScreen.onboarding,
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(child: _buildScreen(state.screen)),
                if (showNav) AppBottomNavBar(current: state.screen, onSelect: onNavSelect),
              ],
            ),
            ToastBanner(text: state.toast),
            ReactionFloatOverlay(text: state.reactionFloat, triggerId: state.reactionId),
          ],
        ),
      ),
    );
  }
}
