import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_styles.dart';

/// Wraps [child] in a slowly rotating rainbow border with a soft blurred halo.
/// Holds still when the system asks to reduce motion.
class RainbowGlow extends StatefulWidget {
  final Widget child;
  final double radius;
  final double borderWidth;
  final double blurSigma;
  final double glowOpacity;

  /// Sweep colors; the first and last should match so the loop is seamless.
  final List<Color> colors;

  const RainbowGlow({
    super.key,
    required this.child,
    this.radius = 16,
    this.borderWidth = 2,
    this.blurSigma = 12,
    this.glowOpacity = 0.5,
    this.colors = rainbowColors,
  });

  @override
  State<RainbowGlow> createState() => _RainbowGlowState();
}

class _RainbowGlowState extends State<RainbowGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.radius);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final gradient = SweepGradient(
            colors: widget.colors,
            transform: GradientRotation(_controller.value * 2 * math.pi),
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: widget.blurSigma,
                    sigmaY: widget.blurSigma,
                  ),
                  child: Opacity(
                    opacity: widget.glowOpacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: borderRadius,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(widget.borderWidth),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: borderRadius,
                ),
                child: child,
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}
