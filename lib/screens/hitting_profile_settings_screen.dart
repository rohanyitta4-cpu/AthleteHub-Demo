import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/hitting_profile.dart';
import '../services/performance_analysis/performance_analysis_service.dart';
import '../widgets/hitting_profile_picker.dart';

class HittingProfileSettingsScreen extends StatefulWidget {
  const HittingProfileSettingsScreen({super.key});

  @override
  State<HittingProfileSettingsScreen> createState() => _HittingProfileSettingsScreenState();
}

class _HittingProfileSettingsScreenState extends State<HittingProfileSettingsScreen> {
  final PerformanceAnalysisService _service = PerformanceAnalysisService();
  HittingProfile? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.getHittingProfile().then((p) {
      if (mounted) {
        setState(() {
          _selected = p;
          _loading = false;
        });
      }
    });
  }

  Future<void> _select(HittingProfile profile) async {
    final previous = _selected;
    setState(() => _selected = profile);
    try {
      await _service.setHittingProfile(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scout will grade you as a ${profile.label}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _selected = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save your hitting profile. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hitting Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Choose how Scout prioritizes your offensive performance. '
                    'Your grade is weighted toward the stats that matter most for your style, '
                    'and Scout also shows a profile-neutral Overall Offense score.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 18),
                  HittingProfilePicker(selected: _selected, onSelected: _select),
                ],
              ),
      ),
    );
  }
}
