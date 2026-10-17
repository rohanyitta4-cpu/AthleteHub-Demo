import 'package:flutter/material.dart';

/// Keeps the phone-designed layouts at a readable width on iPad and in wide
/// windows (iPadOS split view / Stage Manager). Content is centered, and the
/// [MediaQuery] below reports the limited width so size-relative layouts and
/// sheets lay out as they would on a large phone.
class AppWidthLimit extends StatelessWidget {
  const AppWidthLimit({
    super.key,
    required this.child,
    required this.backgroundColor,
  });

  static const double maxWidth = 700;

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= maxWidth) return child;

    EdgeInsets noSides(EdgeInsets e) => e.copyWith(left: 0, right: 0);
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: MediaQuery(
            data: mq.copyWith(
              size: Size(maxWidth, mq.size.height),
              padding: noSides(mq.padding),
              viewPadding: noSides(mq.viewPadding),
              viewInsets: noSides(mq.viewInsets),
            ),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
