import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/chart_data_preparer.dart';
import '../utils/stat_calculations.dart';
import '../utils/stat_key_map.dart';

class StatComparisonSection extends StatelessWidget {
  final String statName;
  final List<Map<String, dynamic>> gameData;

  const StatComparisonSection({
    super.key,
    required this.statName,
    required this.gameData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statValues = ChartDataPreparer.getStatValues(statName, gameData);
    
    if (statValues.length < 10) {
      return const SizedBox.shrink();
    }

    // Calculate comparisons
    final last10 = StatCalculations.recentForm(statValues, 10);
    final first10 = StatCalculations.mean(statValues.take(10).toList());
    final delta = first10 != 0 ? ((last10 - first10) / first10) * 100 : 0.0;
    final isImproving = delta > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          'Comparisons',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Comparison container
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Comparison label
              Text(
                'Last 10 vs First 10',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              // Side-by-side values
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn(context, 'Last 10', last10, isDark),
                  _buildStatColumn(context, 'First 10', first10, isDark),
                ],
              ),
              const SizedBox(height: 16),
              // Inline delta result
              Row(
                children: [
                  Icon(
                    isImproving ? Icons.trending_up : Icons.trending_down,
                    color: isImproving ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isImproving ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, double value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatValue(value),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatValue(double value) {
    return formatStatValue(statName, value);
  }
}