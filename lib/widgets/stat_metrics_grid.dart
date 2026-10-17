import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/chart_data_preparer.dart';
import '../utils/stat_calculations.dart';
import '../utils/stat_key_map.dart';

class StatMetricsGrid extends StatelessWidget {
  final String statName;
  final List<Map<String, dynamic>> gameData;

  const StatMetricsGrid({
    super.key,
    required this.statName,
    required this.gameData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statValues = ChartDataPreparer.getStatValues(statName, gameData);
    
    if (statValues.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate all metrics
    final mean = StatCalculations.mean(statValues);
    final median = StatCalculations.median(statValues);
    final stdDev = StatCalculations.standardDeviation(statValues);
    final range = StatCalculations.range(statValues);
    final iqr = StatCalculations.interquartileRange(statValues);
    final minMax = StatCalculations.minMax(statValues);
    final recentForm5 = StatCalculations.recentForm(statValues, 5);
    final recentForm10 = StatCalculations.recentForm(statValues, 10);
    final consistencyScore = StatCalculations.consistencyScore(statValues);
    final bestStreak = StatCalculations.longestStreakAbove(statValues, mean);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Central Tendencies
          _buildSection(
            context,
            'Central Tendencies',
            isDark,
            [
              _buildStatRow(context, 'Mean', _formatValue(mean), isDark),
              _buildStatRow(context, 'Median', _formatValue(median), isDark),
            ],
          ),
          const SizedBox(height: 32),
          // Dispersion
          _buildSection(
            context,
            'Dispersion',
            isDark,
            [
              _buildStatRow(context, 'Std Dev', _formatValue(stdDev), isDark),
              _buildStatRow(context, 'Range', _formatValue(range), isDark),
              _buildStatRow(context, 'IQR', _formatValue(iqr), isDark),
            ],
          ),
          const SizedBox(height: 32),
          // Extremes
          _buildSection(
            context,
            'Extremes',
            isDark,
            [
              _buildStatRow(context, 'Min', _formatValue(minMax['min']!), isDark, Colors.red),
              _buildStatRow(context, 'Max', _formatValue(minMax['max']!), isDark, Colors.green),
            ],
          ),
          const SizedBox(height: 32),
          // Performance - Reworked
          _buildPerformanceSection(context, isDark, recentForm5, recentForm10, bestStreak, consistencyScore),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    bool isDark,
    List<Widget> statRows,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Single card with all stats in rows
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: statRows,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    bool isDark, [
    Color? accentColor,
  ]) {
    final valueColor = accentColor ?? (isDark ? Colors.white : Colors.black87);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(
    BuildContext context,
    bool isDark,
    double recentForm5,
    double recentForm10,
    int bestStreak,
    double consistencyScore,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Recent Performance
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildStatRow(context, 'Last 5', _formatValue(recentForm5), isDark),
              _buildStatRow(context, 'Last 10', _formatValue(recentForm10), isDark),
            ],
          ),
        ),
        // Highlights
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildHighlightRow(
                context,
                Icons.local_fire_department,
                'Best Streak',
                '$bestStreak games',
                Colors.orange,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildHighlightRow(
                context,
                Icons.trending_up,
                'Consistency',
                '${(consistencyScore * 100).toStringAsFixed(0)}%',
                Colors.blue,
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color accentColor,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  String _formatValue(double value) {
    return formatStatValue(statName, value);
  }
}