import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// A one-shot confetti burst, painted rather than packaged.
///
/// Sweeping the table is the signature moment of this game and the felt did
/// nothing to mark it: the audio side was fully built — tone, spoken call-out,
/// drum flourish — while the screen simply changed some numbers.
///
/// Hand-rolled on purpose. A confetti package would be a dependency, an entry
/// in the README and a second animation system to keep in step with
/// [AppMotion]; this is one controller and a painter, and it honours reduced
/// motion by never starting.
class ConfettiBurst extends StatefulWidget {
  /// Restarting the burst: pass a new value (the settled hand's amount, a
  /// level number) and the confetti fires again.
  final Object? trigger;

  /// Where the burst originates, in fractions of the box.
  final Alignment origin;

  final int particleCount;

  const ConfettiBurst({super.key, this.trigger, this.origin = const Alignment(0, -0.35), this.particleCount = 60});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  static const Duration _fall = Duration(milliseconds: 1400);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _fall);
  late List<_Particle> _particles = _spawn();

  final math.Random _rng = math.Random();

  List<_Particle> _spawn() {
    const palette = [AppColors.gold, AppColors.goldLight, AppColors.win, AppColors.textPrimary, AppColors.goldDark];
    return [
      for (var i = 0; i < widget.particleCount; i++)
        _Particle(
          // Fired upward and outward in a fan, so the burst reads as thrown
          // rather than as rain.
          angle: -math.pi / 2 + (_rng.nextDouble() - 0.5) * 2.2,
          speed: 0.55 + _rng.nextDouble() * 0.75,
          spin: (_rng.nextDouble() - 0.5) * 12,
          size: 5 + _rng.nextDouble() * 6,
          color: palette[_rng.nextInt(palette.length)],
          delay: _rng.nextDouble() * 0.15,
          wide: _rng.nextBool(),
        ),
    ];
  }

  @override
  void didUpdateWidget(covariant ConfettiBurst old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _fire();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fire());
  }

  void _fire() {
    if (!mounted) return;
    if (AppMotion.reduceMotion(context)) return;
    setState(() => _particles = _spawn());
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isDismissed) return const SizedBox.expand();
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
              origin: widget.origin,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;

  /// Fraction of the animation to wait before launching, so the burst is a
  /// spray rather than a single ring.
  final double delay;

  /// Rectangular scraps read better mixed with squarer ones.
  final bool wide;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.delay,
    required this.wide,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Alignment origin;

  /// Downward pull, in fractions of the box height over the full flight.
  static const double _gravity = 1.35;

  const _ConfettiPainter({required this.particles, required this.progress, required this.origin});

  @override
  void paint(Canvas canvas, Size size) {
    final start = origin.alongSize(size);
    final reach = size.shortestSide;

    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final dx = math.cos(p.angle) * p.speed * reach * t;
      final dy = math.sin(p.angle) * p.speed * reach * t + _gravity * reach * t * t;
      // Held at full opacity for most of the flight, then faded — a scrap that
      // dims from the first frame reads as a rendering glitch.
      final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);

      canvas.save();
      canvas.translate(start.dx + dx, start.dy + dy);
      canvas.rotate(p.spin * t);
      final w = p.wide ? p.size : p.size * 0.55;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w, height: p.size),
        Paint()..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress || old.particles != particles;
}
