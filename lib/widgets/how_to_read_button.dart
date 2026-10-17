import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard/dash_style.dart';

/// Small ⋯ button that opens a "how to read this" sheet of short sections.
class HowToReadButton extends StatelessWidget {
  final String title;
  final List<(String, String)> sections;

  const HowToReadButton({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 24,
      child: IconButton(
        onPressed: () => _show(context, isDark),
        tooltip: 'How to read this',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        iconSize: 20,
        icon: Icon(Icons.more_horiz_rounded, color: dashText(isDark)),
      ),
    );
  }

  void _show(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      backgroundColor: dashSurface(isDark),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: dashText(isDark)),
            ),
            for (final (heading, body) in sections) ...[
              const SizedBox(height: 16),
              Text(heading.toUpperCase(), style: dashLabel(isDark)),
              const SizedBox(height: 4),
              Text(
                body,
                style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: dashText(isDark)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
