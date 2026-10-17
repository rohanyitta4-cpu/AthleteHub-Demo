import 'package:flutter/material.dart';

class GradientContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<Color>? gradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;
  final BoxShadow? shadow;
  final Border? border;

  const GradientContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.gradientColors,
    this.gradientBegin,
    this.gradientEnd,
    this.shadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final defaultGradientColors = isDark
        ? [
            const Color(0xFF111214),
            const Color(0xFF1A1C1F),
            const Color(0xFF0F1113),
            const Color(0xFF111214),
          ]
        : [
            Colors.white,
            const Color(0xFFF8FAFC),
            const Color(0xFFFFF8F0), // Light orange tint
            Colors.white,
          ];

    final defaultShadow = BoxShadow(
      color: isDark 
          ? Colors.black.withOpacity(0.5)
          : Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    );

    // Add metallic shine for light mode
    final lightModeShine = !isDark ? [
      BoxShadow(
        color: const Color(0xFFC0C0C0).withOpacity(0.2),
        blurRadius: 15,
        offset: const Offset(-2, -2),
      ),
      BoxShadow(
        color: const Color(0xFFFFF8F0).withOpacity(0.3),
        blurRadius: 10,
        offset: const Offset(-1, -1),
      ),
    ] : [];

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: gradientBegin ?? Alignment.topLeft,
          end: gradientEnd ?? Alignment.bottomRight,
          colors: gradientColors ?? defaultGradientColors,
        ),
        border: border,
        boxShadow: shadow != null ? [shadow!] : [defaultShadow, ...lightModeShine],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class SilverAccentContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isSelected;

  const SilverAccentContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12.0,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [
                  // Enhanced metallic silver gradient
                  const Color(0xFFE8E8E8).withOpacity(0.4),
                  const Color(0xFFC0C0C0).withOpacity(0.6),
                  const Color(0xFFA8A8A8).withOpacity(0.4),
                  const Color(0xFF2563eb).withOpacity(0.2),
                ]
              : isDark
                  ? [
                      const Color(0xFF1A1C1F),
                      const Color(0xFF111214),
                      const Color(0xFF0F1113),
                    ]
                  : [
                      // Light mode with silver and orange accents
                      Colors.white,
                      const Color(0xFFF8FAFC),
                      const Color(0xFFFFF8F0), // Light orange tint
                    ],
        ),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFC0C0C0)
              : isDark
                  ? Colors.grey[800]!
                  : const Color(0xFFE0E0E0), // Light silver border for light mode
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          // Enhanced metallic shine effect
          if (isSelected)
            BoxShadow(
              color: const Color(0xFFC0C0C0).withOpacity(0.5),
              blurRadius: 25,
              offset: const Offset(-3, -3),
            ),
          // Additional metallic highlight
          if (isSelected)
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(-1, -1),
            ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          // Enhanced inner metallic shine
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                    Colors.transparent,
                    const Color(0xFFC0C0C0).withOpacity(0.1),
                  ],
                )
              : !isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                        const Color(0xFFFFF8F0).withOpacity(0.2),
                      ],
                    )
                  : null,
        ),
        child: child,
      ),
    );
  }
}
