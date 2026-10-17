import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/hitting_profile.dart';
import '../services/performance_analysis/performance_analysis_service.dart';
import '../theme/zuno_colors.dart';

const Color _accent = Color(0xFF10B981);

/// Three selectable hitting profiles plus a weighting preview for the one
/// currently highlighted.
class HittingProfilePicker extends StatelessWidget {
  final HittingProfile? selected;
  final ValueChanged<HittingProfile> onSelected;

  const HittingProfilePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final profile in HittingProfile.values) ...[
          _ProfileOption(
            profile: profile,
            isSelected: profile == selected,
            isDark: isDark,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(profile);
            },
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        _WeightPreview(profile: selected ?? HittingProfile.contact, isDark: isDark, isPlaceholder: selected == null),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final HittingProfile profile;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.profile,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? ZunoColors.darkText : ZunoColors.lightText;
    final muted = isDark ? ZunoColors.darkMuted : ZunoColors.lightMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? ZunoColors.darkSurface : ZunoColors.lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _accent : (isDark ? ZunoColors.darkBorder : ZunoColors.lightBorder),
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.label,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.tagline.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: isSelected ? _accent : muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.description,
                      style: GoogleFonts.inter(fontSize: 13, color: muted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: 20,
                color: isSelected ? _accent : muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightPreview extends StatelessWidget {
  final HittingProfile profile;
  final bool isDark;
  final bool isPlaceholder;

  const _WeightPreview({required this.profile, required this.isDark, required this.isPlaceholder});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? ZunoColors.darkText : ZunoColors.lightText;
    final muted = isDark ? ZunoColors.darkMuted : ZunoColors.lightMuted;
    final track = isDark ? ZunoColors.darkSurface2 : ZunoColors.lightSurface2;
    const order = ['contact', 'power', 'discipline', 'twoStrike', 'consistency', 'momentum'];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isPlaceholder ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? ZunoColors.darkSurface : ZunoColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? ZunoColors.darkBorder : ZunoColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GRADE WEIGHTING · ${profile.label.toUpperCase()}',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: muted),
            ),
            const SizedBox(height: 6),
            Text(
              'Primary stats: ${profile.primaryStats}',
              style: GoogleFonts.inter(fontSize: 12, color: muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            for (final key in order)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 124,
                      child: Text(
                        HittingProfile.categoryLabels[key]!,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: text),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: profile.weights[key]! / 35),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          builder: (_, value, _) => LinearProgressIndicator(
                            value: value.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: track,
                            valueColor: AlwaysStoppedAnimation(key == 'momentum' ? muted : _accent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 36,
                      child: Text(
                        key == 'momentum' ? '±' : '${profile.weights[key]}%',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: text),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'The profile changes how much each category counts, never the category scores themselves. '
              'Momentum nudges the grade by at most about 2 points instead of being averaged in. '
              'These are starting weights and will be recalibrated as more player data comes in.',
              style: GoogleFonts.inter(fontSize: 11, color: muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet used from Scout. Returns the newly saved profile, or null.
class HittingProfileSheet extends StatefulWidget {
  final HittingProfile? initial;

  const HittingProfileSheet({super.key, this.initial});

  static Future<HittingProfile?> show(BuildContext context, HittingProfile? current) {
    return showModalBottomSheet<HittingProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HittingProfileSheet(initial: current),
    );
  }

  @override
  State<HittingProfileSheet> createState() => _HittingProfileSheetState();
}

class _HittingProfileSheetState extends State<HittingProfileSheet> {
  late HittingProfile? _selected = widget.initial;
  bool _saving = false;

  Future<void> _save() async {
    final profile = _selected;
    if (profile == null) return;
    if (profile == widget.initial) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await PerformanceAnalysisService().setHittingProfile(profile);
      if (mounted) Navigator.of(context).pop(profile);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save your hitting profile. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? ZunoColors.darkText : ZunoColors.lightText;
    final muted = isDark ? ZunoColors.darkMuted : ZunoColors.lightMuted;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? ZunoColors.darkBg : ZunoColors.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? ZunoColors.darkBorder : ZunoColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Text(
                    'Hitting Profile',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose how Scout prioritizes your offensive performance.',
                    style: GoogleFonts.inter(fontSize: 13, color: muted),
                  ),
                  const SizedBox(height: 18),
                  HittingProfilePicker(
                    selected: _selected,
                    onSelected: (p) => setState(() => _selected = p),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _selected == null || _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? ZunoColors.darkAccent : ZunoColors.lightAccent,
                      foregroundColor: isDark ? ZunoColors.darkOnAccent : ZunoColors.lightOnAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                            _selected == widget.initial ? 'Done' : 'Use this profile',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
