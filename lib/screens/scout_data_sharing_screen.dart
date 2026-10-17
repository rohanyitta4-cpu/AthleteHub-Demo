import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_urls.dart';
import '../services/performance_analysis/performance_analysis_service.dart';

/// Opt-in for contributing season numbers to Scout's standards. Off by default.
class ScoutDataSharingScreen extends StatefulWidget {
  const ScoutDataSharingScreen({super.key});

  @override
  State<ScoutDataSharingScreen> createState() => _ScoutDataSharingScreenState();
}

class _ScoutDataSharingScreenState extends State<ScoutDataSharingScreen> {
  static const Color _accent = Color(0xFF10B981);

  final PerformanceAnalysisService _service = PerformanceAnalysisService();
  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;
  CompetitionLevel? _level;

  @override
  void initState() {
    super.initState();
    _service.getDataSharing().then((s) {
      if (!mounted) return;
      setState(() {
        _enabled = s.enabled;
        _level = s.competitionLevel;
        _loading = false;
      });
    });
  }

  Future<void> _save({required bool enabled, CompetitionLevel? level}) async {
    final before = (_enabled, _level);
    setState(() {
      _enabled = enabled;
      _level = level;
      _saving = true;
    });
    try {
      await _service.setDataSharing(enabled: enabled, competitionLevel: level);
      if (!mounted) return;
      if (enabled != before.$1) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(enabled
              ? 'Thanks. Your season numbers will be included next time Scout analyzes your stats.'
              : 'Sharing is off and the numbers you shared were deleted.'),
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enabled = before.$1;
        _level = before.$2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save that. Check your connection and try again.")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final body = isDark ? Colors.grey[300]! : Colors.grey[800]!;
    final muted = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!;

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 8),
          child: Text(
            text.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: muted,
            ),
          ),
        );

    Widget bullet(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 10),
                child: Container(width: 4, height: 4, color: muted),
              ),
              Expanded(
                child: Text(text, style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: body)),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('Help Improve Scout', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Text(
                    'Scout\'s grades use provisional standards we set by hand. With your '
                    'permission, Scout saves a summary of your season so we can check those '
                    'standards against real players and improve them over time.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: body),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _enabled ? _accent.withValues(alpha: 0.6) : border),
                    ),
                    child: SwitchListTile(
                      value: _enabled,
                      onChanged: _saving ? null : (v) => _save(enabled: v, level: _level),
                      activeThumbColor: _accent,
                      title: Text(
                        'Share my season numbers',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Off unless you turn it on. Turn it off any time.',
                        style: GoogleFonts.inter(fontSize: 12, color: muted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'If you\'re under 18, check with a parent or guardian before turning this on.',
                    style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: muted),
                  ),
                  heading('What\'s shared'),
                  bullet('Season totals and rates: games, at-bats, plate appearances, AVG, OBP, SLG, ISO, K%, BB%, two-strike average.'),
                  bullet('Hard-hit and quality at-bat rates, if you log them.'),
                  bullet('Your hitting profile and competition level (if you pick one below).'),
                  bullet('Which version of Scout\'s standards graded you.'),
                  heading('What\'s never shared'),
                  bullet('Your name, email, account ID, team, opponents, or game dates.'),
                  bullet('Your chats with Scout or Zuno.'),
                  bullet('The summary is saved under a scrambled ID that only our server can match to your account, so it can be deleted when you turn this off or delete your account.'),
                  heading('What it changes'),
                  bullet('Nothing about your grade. Standards only change in a reviewed update, and Scout tells you when your report was graded under older standards.'),
                  bullet('Turning this off deletes the numbers you already shared.'),
                  heading('Competition level (optional)'),
                  Text(
                    'Helps us tell whether standards should differ by level. You can leave it blank.',
                    style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CompetitionLevel.values.map((level) {
                      final selected = _level == level;
                      return ChoiceChip(
                        label: Text(level.label),
                        selected: selected,
                        onSelected: _saving
                            ? null
                            : (on) => _save(enabled: _enabled, level: on ? level : null),
                        showCheckmark: false,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : body,
                        ),
                        selectedColor: _accent,
                        side: BorderSide(color: selected ? _accent : border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(AppUrls.privacyPolicy),
                        mode: LaunchMode.externalApplication,
                      ),
                      style: TextButton.styleFrom(foregroundColor: _accent, padding: EdgeInsets.zero),
                      child: Text(
                        'Read the privacy policy',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
