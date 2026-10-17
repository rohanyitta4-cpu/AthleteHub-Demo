import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/rank_accent.dart';
import '../utils/player_rank.dart';
import 'dashboard/dash_style.dart';

/// Themes toggle: match app accents to the player's rank.
class RankAccentSwitch extends StatelessWidget {
  final bool card;

  const RankAccentSwitch({super.key, this.card = true});

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: RankAccent.instance, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = RankAccent.instance;
    final tier = accent.tier;
    final subtitle = !accent.enabled
        ? 'Accents use AthleteHub blue.'
        : tier == null
        ? 'Unranked for now, so accents stay blue until you get a rank.'
        : accent.previewScore != null
        ? 'Previewing ${tier.name} (${accent.previewScore}) (dev preview score).'
        : 'Accents follow your rank: ${tier.name}.';

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Match accents to my rank',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: dashText(isDark)),
              ),
            ),
            Switch.adaptive(
              value: accent.enabled,
              activeTrackColor: accent.color(isDark),
              onChanged: (v) => accent.setEnabled(v),
            ),
          ],
        ),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 12.5, height: 1.35, color: dashMuted(isDark))),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final t in rankTiers)
              Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(colors: [t.deep, t.bright]),
                    border: t == tier ? Border.all(color: dashText(isDark), width: 1) : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    if (!card) return body;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 14),
      decoration: dashCard(isDark, radius: 16),
      child: body,
    );
  }
}

/// Debug-only score slider (Themes). Temporary; remove before release polish.
class RankPreviewSlider extends StatelessWidget {
  const RankPreviewSlider({super.key});

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: RankAccent.instance, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = RankAccent.instance;
    final real = accent.score;
    final value = accent.previewScore ?? real ?? 50;
    final tier = rankFor(value);
    final color = isDark ? tier.bright : tier.deep;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: dashCard(isDark, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: dashWarning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEV',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: dashWarning,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('PREVIEW SCORE', style: dashLabel(isDark)),
              const Spacer(),
              Text(
                '$value · ${tier.name}',
                style: dashMono(size: 12, weight: FontWeight.w700, color: color),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: dashBorder(isDark),
              overlayColor: color.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value.toDouble(),
              max: 100,
              divisions: 100,
              onChanged: (v) => accent.setPreviewScore(v.round()),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  accent.previewScore == null
                      ? 'Showing your real score${real == null ? ' (unranked)' : ''}.'
                      : 'Faking $value on the dashboard until you reset or restart.',
                  style: GoogleFonts.inter(fontSize: 11.5, height: 1.35, color: dashMuted(isDark)),
                ),
              ),
              if (accent.previewScore != null)
                TextButton(onPressed: () => accent.setPreviewScore(null), child: const Text('Use my score')),
            ],
          ),
        ],
      ),
    );
  }
}
