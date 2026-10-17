import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../widgets/rank_accent_switch.dart';

class ThemesSettingsScreen extends StatefulWidget {
  const ThemesSettingsScreen({super.key});

  @override
  State<ThemesSettingsScreen> createState() => _ThemesSettingsScreenState();
}

class _ThemesSettingsScreenState extends State<ThemesSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selected = canonicalThemeId(themeProvider.currentTheme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'AthleteHub uses a simple black-and-white look. Pick dark or light — that’s it.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            _buildThemeCard(
              context,
              title: 'Dark',
              subtitle: 'Black background, white accents',
              themeId: 'dark_bw_simple',
              backgroundColor: const Color(0xFF121212),
              accentColor: Colors.white,
              isDark: true,
              isSelected: selected == 'dark_bw_simple',
            ),
            const SizedBox(height: 12),
            _buildThemeCard(
              context,
              title: 'Light',
              subtitle: 'White background, black accents',
              themeId: 'light_bw',
              backgroundColor: Colors.white,
              accentColor: Colors.black,
              isDark: false,
              isSelected: selected == 'light_bw',
            ),
            const SizedBox(height: 24),
            const RankAccentSwitch(),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              const RankPreviewSlider(),
            ],
          ],
        ),
      ),
    );
  }

  void _selectTheme(String themeId) {
    final id = canonicalThemeId(themeId);
    Provider.of<ThemeProvider>(context, listen: false).setTheme(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(id == 'dark_bw_simple' ? 'Dark theme applied' : 'Light theme applied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String themeId,
    required Color backgroundColor,
    required Color accentColor,
    required bool isDark,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectTheme(themeId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
              width: isSelected ? 3 : 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            color: isDark ? Colors.grey[900] : Colors.grey[50],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white30 : Colors.black12,
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 20,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: (isDark ? Colors.white70 : Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                  ),
                  child: Icon(
                    Icons.check,
                    color: isDark ? Colors.black : Colors.white,
                    size: 16,
                  ),
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white30 : Colors.grey[400]!,
                      width: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
