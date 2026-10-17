import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatPickerBottomSheet extends StatefulWidget {
  final List<String> availableStats;
  final String selectedStat;
  final Function(String) onStatSelected;

  const StatPickerBottomSheet({
    super.key,
    required this.availableStats,
    required this.selectedStat,
    required this.onStatSelected,
  });

  @override
  State<StatPickerBottomSheet> createState() => _StatPickerBottomSheetState();
}

class _StatPickerBottomSheetState extends State<StatPickerBottomSheet> {
  late TextEditingController _searchController;
  List<String> _filteredStats = [];
  String _selectedCategory = 'All';

  final Map<String, List<String>> _statCategories = {
    'Batting': [
      'Batting Average',
      'On-Base Percentage',
      'Slugging Percentage',
      'On-Base Plus Slugging',
      'Isolated Power',
      'Runs Created',
      'Hard-Hit Rate',
      'Quality At-Bat Rate',
      'WAR',
      'At Bats',
      'Runs',
      'Hits',
      'Doubles',
      'Triples',
      'Home Runs',
      'Walks',
      'Intentional Walks',
      'Hit By Pitch',
      'Sacrifice Bunts',
      'Sacrifice Flies',
      'Stolen Bases',
      'Runs Batted In',
      'Two Strike Counts',
      'Two Strike Success Rate',
      'Hard-Hit Balls',
      'Quality At-Bats',
      'Strikeouts',
    ],
    'Pitching': [
      'Earned Run Average',
      'ERA',
      'Strikeout Rate',
      'Walks + Hits per Inning Pitched',
      'Innings Pitched',
      'Earned Runs',
      'Pitches Thrown',
    ],
  };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredStats = widget.availableStats;
    _searchController.addListener(_filterStats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStats() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStats = _getStatsForCategory(_selectedCategory);
      } else {
        _filteredStats = _getStatsForCategory(_selectedCategory)
            .where((stat) => stat.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  List<String> _getStatsForCategory(String category) {
    if (category == 'All') {
      return widget.availableStats;
    }
    return _statCategories[category]?.where((stat) => widget.availableStats.contains(stat)).toList() ?? [];
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _filteredStats = _getStatsForCategory(category);
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Select Stat',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search stats...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          // Category chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                _buildCategoryChip(context, 'All', isDark),
                const SizedBox(width: 8),
                _buildCategoryChip(context, 'Batting', isDark),
                const SizedBox(width: 8),
                _buildCategoryChip(context, 'Pitching', isDark),
              ],
            ),
          ),
          // Stats list
          Expanded(
            child: _filteredStats.isEmpty
                ? Center(
                    child: Text(
                      'No stats found',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredStats.length,
                    itemBuilder: (context, index) {
                      final stat = _filteredStats[index];
                      final isSelected = stat == widget.selectedStat;
                      return ListTile(
                        title: Text(
                          stat,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                            : null,
                        selected: isSelected,
                        selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () {
                          widget.onStatSelected(stat);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String category, bool isDark) {
    final theme = Theme.of(context);
    final isSelected = _selectedCategory == category;

    return ChoiceChip(
      label: Text(
        category,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? Colors.white
              : isDark
                  ? Colors.grey[300]
                  : Colors.grey[700],
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _onCategoryChanged(category);
        }
      },
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
    );
  }
}

