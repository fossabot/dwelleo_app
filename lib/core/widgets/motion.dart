import 'dart:async';

import 'package:flutter/material.dart';

/// Lightweight motion primitives shared across the app. All are
/// performance-safe: single short-lived controllers, RepaintBoundary
/// isolation, and no third-party packages.

/// One-shot entrance: fades in while sliding up a few pixels.
/// Use on section roots so the home feels alive as it builds.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = 20,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = curve;
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(curve);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }
}

/// Endless soft "breathing" glow + scale for hero controls
/// (e.g. the AI Search bottom-nav button, the MARKET DATA dot).
/// [strength] scales the halo for small vs large elements.
/// Isolated in its own layer.
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double strength;

  const PulseGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.strength = 1,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          final s = widget.strength;
          return Transform.scale(
            scale: 1 + 0.045 * t,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.30 + 0.25 * t),
                    blurRadius: (12 + 10 * t) * s,
                    spreadRadius: (1 + 2 * t) * s,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Endless subtle opacity pulse for skeleton placeholders.
class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.45,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(opacity: _controller, child: widget.child),
    );
  }
}
