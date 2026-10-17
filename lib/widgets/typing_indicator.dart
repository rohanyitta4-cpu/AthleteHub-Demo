import 'package:flutter/material.dart';

/// Animated typing indicator widget (ChatGPT-style)
class TypingIndicator extends StatefulWidget {
  final Color? color;
  final double dotSize;
  final Duration animationDuration;

  const TypingIndicator({
    super.key,
    this.color,
    this.dotSize = 8.0,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat();

    _animations = List.generate(
      3,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dotColor = widget.color ?? 
        (isDark ? Colors.grey[400]! : Colors.grey[600]!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: dotColor.withOpacity(0.3 + (_animations[index].value * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

