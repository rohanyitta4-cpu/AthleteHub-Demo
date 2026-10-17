import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/chart_data_preparer.dart';
import '../utils/stat_key_map.dart';

class StatGameLog extends StatelessWidget {
  final String statName;
  final List<Map<String, dynamic>> gameData;

  const StatGameLog({
    super.key,
    required this.statName,
    required this.gameData,
  });

  List<_GameEntry> _buildEntries() {
    final statValues = ChartDataPreparer.getStatValues(statName, gameData);
    final statKey = getStatKey(statName) ?? '';
    final isHigherBetter = statKey != 'earnedRunAverage' && statKey != 'strikeoutRate';

    final entries = <_GameEntry>[];
    for (int i = 0; i < statValues.length && i < gameData.length; i++) {
      final value = statValues[i];
      String comparisonType = 'same';
      if (i > 0) {
        final previousValue = statValues[i - 1];
        if (value > previousValue) {
          comparisonType = isHigherBetter ? 'better' : 'worse';
        } else if (value < previousValue) {
          comparisonType = isHigherBetter ? 'worse' : 'better';
        }
      }
      entries.add(_GameEntry(
        gameNumber: i + 1,
        date: gameData[i]['date'] as DateTime? ?? DateTime.now(),
        value: value,
        comparisonType: comparisonType,
      ));
    }

    entries.sort((a, b) => b.gameNumber.compareTo(a.gameNumber));
    return entries;
  }

  void _open(BuildContext context, List<_GameEntry> entries, bool isDark) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final sheetBg = isDark ? const Color(0xFF111214) : Colors.white;
          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Game Log',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              '$statName · ${entries.length} games · vs previous game',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      24 + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) =>
                        _buildGameEntry(context, entries[index], isDark, theme),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = _buildEntries();
    if (entries.isEmpty) return const SizedBox.shrink();

    final latest = entries.first;
    final Color cardBg = isDark ? Colors.white.withOpacity(0.04) : Colors.grey[50]!;
    final Color cardBorder = isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context, entries, isDark),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game Log',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entries.length} games · last: ${_formatValue(latest.value)} '
                      'on ${DateFormat('MMM d').format(latest.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameEntry(BuildContext context, _GameEntry entry, bool isDark, ThemeData theme) {
    final dateFormat = DateFormat('MMM d, y');
    
    IconData indicatorIcon;
    String indicatorText;
    Color indicatorColor;
    
    if (entry.comparisonType == 'better') {
      indicatorIcon = Icons.arrow_upward;
      indicatorText = 'Better';
      indicatorColor = Colors.green;
    } else if (entry.comparisonType == 'worse') {
      indicatorIcon = Icons.arrow_downward;
      indicatorText = 'Worse';
      indicatorColor = Colors.red;
    } else {
      indicatorIcon = Icons.remove;
      indicatorText = 'Same';
      indicatorColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Game number badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'G${entry.gameNumber}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Date and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(entry.date),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatValue(entry.value),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Indicator - text + icon only, no background
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                indicatorIcon,
                size: 16,
                color: indicatorColor,
              ),
              const SizedBox(width: 4),
              Text(
                indicatorText,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: indicatorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    return formatStatValue(statName, value);
  }
}

class _GameEntry {
  final int gameNumber;
  final DateTime date;
  final double value;
  final String comparisonType; // 'better', 'worse', 'same'

  _GameEntry({
    required this.gameNumber,
    required this.date,
    required this.value,
    required this.comparisonType,
  });
}