import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_notifier.dart';

/// Wires app-lifecycle transitions to [GameNotifier] — nothing did this
/// before: no `WidgetsBindingObserver` existed anywhere in the app, so a
/// resume waited out whatever was left of the 60-second heartbeat tick to
/// roll a stale point bucket or re-sync a notification, and a background
/// could lose a save still waiting out its debounce.
///
/// Deliberately *not* responsible for deep links — a route pushed while the
/// app is already running is a distinct event (`onGenerateRoute` in
/// main.dart, via `_DeepLinkGate`), not a lifecycle transition, and
/// `WidgetsApp` claims `didPushRouteInformation` for its own Navigator
/// handling before any descendant observer would ever see it.
class AppLifecycleBridge extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleBridge({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleBridge> createState() => _AppLifecycleBridgeState();
}

class _AppLifecycleBridgeState extends ConsumerState<AppLifecycleBridge> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(gameProvider.notifier).onAppResumed();
      case AppLifecycleState.paused:
        ref.read(gameProvider.notifier).onAppPaused();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
