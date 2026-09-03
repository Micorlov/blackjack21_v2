import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Runs an awaited action and hands its builder a pending flag.
///
/// The app had no loading state anywhere: `grep CircularProgressIndicator lib/`
/// returned nothing, so the Google button stayed fully enabled and idle for
/// the whole round trip through `authenticate()` and Firebase — which reads as
/// "the button is broken", and costs the sign-in.
///
/// The notifier is not ours to change, so pending state is held here, around
/// the `await` of the notifier call: [builder] gets `busy` and a `run` callback
/// that is null while the action is in flight, which disables the control for
/// free wherever a null callback already means disabled.
class AsyncActionBuilder extends StatefulWidget {
  final Future<void> Function() action;
  final Widget Function(BuildContext context, bool busy, VoidCallback? run) builder;

  /// When false the control is disabled for a reason of the caller's own (not
  /// enough chips, empty field) and [builder] receives a null `run`.
  final bool enabled;

  const AsyncActionBuilder({super.key, required this.action, required this.builder, this.enabled = true});

  @override
  State<AsyncActionBuilder> createState() => _AsyncActionBuilderState();
}

class _AsyncActionBuilderState extends State<AsyncActionBuilder> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.action();
    } finally {
      // The action can outlive the screen — sign-in swaps the whole screen out
      // on success — so the flag is only cleared if we are still mounted.
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canRun = widget.enabled && !_busy;
    return widget.builder(context, _busy, canRun ? _run : null);
  }
}

/// The app's one loading indicator: a small ring sized to sit inside a button
/// label without changing the button's height.
class PendingSpinner extends StatelessWidget {
  final double size;
  final Color color;

  const PendingSpinner({super.key, this.size = 18, this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2.4, color: color),
    );
  }
}
