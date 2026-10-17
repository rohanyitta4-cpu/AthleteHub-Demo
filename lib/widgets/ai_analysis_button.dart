import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_styles.dart';
import '../theme/zuno_colors.dart';
import 'dashboard/dash_style.dart';
import 'scout_chat_sheet.dart';

/// A button that opens the Scout analysis sheet for this stat, outlined in
/// the stat accent so it stands out without overpowering the data.
class AIAnalysisButton extends StatefulWidget {
  final String statName;
  final List<Map<String, dynamic>> gameData;

  const AIAnalysisButton({
    super.key,
    required this.statName,
    required this.gameData,
  });

  @override
  State<AIAnalysisButton> createState() => _AIAnalysisButtonState();
}

class _AIAnalysisButtonState extends State<AIAnalysisButton> {
  static const _radius = 16.0;

  bool _pressed = false;

  void _openScoutChat() {
    HapticFeedback.mediumImpact();
    ScoutChatSheet.show(
      context,
      statName: widget.statName,
      gameData: widget.gameData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: _openScoutChat,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: _buildContent(isDark),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dashSurface(isDark),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: statAccent(isDark).withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? ZunoColors.darkAccent : ZunoColors.lightAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: isDark ? ZunoColors.darkOnAccent : ZunoColors.lightOnAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scout Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : ZunoColors.lightText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Performance insights & trends',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : ZunoColors.lightMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: isDark ? Colors.grey[400] : ZunoColors.lightMuted,
          ),
        ],
      ),
    );
  }
}
