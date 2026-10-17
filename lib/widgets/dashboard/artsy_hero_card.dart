import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/hitting_profile.dart';
import '../../player_stats.dart';
import '../../services/performance_analysis/performance_report_model.dart';
import '../../utils/player_rank.dart';
import 'dash_style.dart';

/// Scout grades from 5 games; fewer than that is always unranked.
const _gamesForRank = 5;

/// Rank score, or null if unranked. Ignores a cached report when games dipped below 5.
int? rankedScore(PerformanceReport? report, int gamesLogged) {
  if (gamesLogged < _gamesForRank) return null;
  if (report == null || report.grade == '--') return null;
  return report.overallScore;
}

const _phrasePrefsKey = 'rankPhrase.last';
/// Always-dark palette for the share graphic.
const _ink = Color(0xFF0A0D14);
const _paper = Colors.white;

/// Live card colors that follow the app theme.
class _HeroPalette {
  final bool isDark;
  const _HeroPalette(this.isDark);

  Color get ink => isDark ? const Color(0xFF0A0D14) : Colors.white;
  Color get paper => isDark ? Colors.white : const Color(0xFF111111);
  Color muted([double a = 0.55]) => paper.withValues(alpha: a);
  Color hairline() => paper.withValues(alpha: isDark ? 0.08 : 0.10);
  Color accent(Color deep, Color bright) => isDark ? bright : deep;
}

String _rate(double v) {
  final s = v.toStringAsFixed(3);
  return s.startsWith('0.') ? s.substring(1) : s;
}

/// Rank card: dial, tier, rotating phrase. Phrase and count-up only replay when
/// [refreshTick] changes (open / pull-to-refresh), not on ordinary rebuilds.
class ArtsyHeroCard extends StatefulWidget {
  final String name;
  final String? photoUrl;
  final HittingProfile? profile;
  final PerformanceReport? report;
  final PlayerStats seasonTotals;
  final int gamesLogged;
  final bool loading;
  final bool generating;
  final VoidCallback onGenerate;
  final VoidCallback? onChangeProfile;
  final int refreshTick;

  /// Dev Themes slider override.
  final int? scoreOverride;

  const ArtsyHeroCard({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.profile,
    required this.report,
    required this.seasonTotals,
    required this.gamesLogged,
    required this.loading,
    required this.generating,
    required this.onGenerate,
    required this.refreshTick,
    this.onChangeProfile,
    this.scoreOverride,
  });

  @override
  State<ArtsyHeroCard> createState() => _ArtsyHeroCardState();
}

class _ArtsyHeroCardState extends State<ArtsyHeroCard> with SingleTickerProviderStateMixin {
  late final AnimationController _dial = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  late Animation<double> _value = const AlwaysStoppedAnimation(0);
  String? _phrase;
  RankTier? _phraseTier;

  /// Grow bars from empty on open/refresh only (not slider drags).
  bool _barsFromZero = true;

  int? get _score {
    if (widget.scoreOverride != null) return widget.scoreOverride;
    return rankedScore(widget.report, widget.gamesLogged);
  }

  _HeroPalette get _c => _HeroPalette(Theme.of(context).brightness == Brightness.dark);

  @override
  void initState() {
    super.initState();
    _replay();
  }

  @override
  void didUpdateWidget(ArtsyHeroCard old) {
    super.didUpdateWidget(old);
    final oldScore = old.scoreOverride ?? rankedScore(old.report, old.gamesLogged);
    if (old.refreshTick != widget.refreshTick || (oldScore == null && _score != null)) {
      _replay();
    } else if (oldScore != _score && _score != null) {
      _barsFromZero = false;
      _animateTo(_score! / 100, from: _value.value);
      if (rankFor(_score!) != _phraseTier) _rollPhrase();
    }
  }

  @override
  void dispose() {
    _dial.dispose();
    super.dispose();
  }

  void _replay() {
    final score = _score;
    if (score == null) return;
    _barsFromZero = true;
    _rollPhrase();
    _animateTo(score / 100, from: 0);
  }

  void _animateTo(double target, {required double from}) {
    final reduceMotion = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _value = Tween(begin: from, end: target).animate(CurvedAnimation(parent: _dial, curve: Curves.easeOutCubic));
    if (reduceMotion) {
      _dial.value = 1;
    } else {
      _dial
        ..duration = Duration(milliseconds: from == 0 ? 1700 : 600)
        ..forward(from: 0);
    }
    if (from == 0 && !reduceMotion) HapticFeedback.lightImpact();
  }

  Future<void> _rollPhrase() async {
    final score = _score;
    if (score == null) return;
    final tier = rankFor(score);
    var previous = _phrase;
    if (previous == null) {
      final prefs = await SharedPreferences.getInstance();
      previous = prefs.getString(_phrasePrefsKey);
    }
    final phrase = pickPhrase(tier, previous: previous);
    if (!mounted) return;
    setState(() {
      _phrase = phrase;
      _phraseTier = tier;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phrasePrefsKey, phrase);
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final score = _score;
    final tier = score == null ? null : rankFor(score);
    final deep = tier?.deep ?? const Color(0xFF334155);
    final bright = tier?.bright ?? const Color(0xFF64748B);
    final accent = c.accent(deep, bright);
    final shadow = c.isDark ? deep.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: shadow, blurRadius: c.isDark ? 30 : 18, offset: Offset(0, c.isDark ? 14 : 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _dial,
                  builder: (_, _) => CustomPaint(
                    painter: _PosterPainter(
                      deep: deep,
                      bright: bright,
                      glow: 0.6 + 0.4 * _dial.value,
                      isDark: c.isDark,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.hairline()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(accent),
                    const SizedBox(height: 20),
                    if (widget.loading)
                      SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: c.paper)),
                      )
                    else
                      _rankRow(score, tier, accent, deep, bright),
                    const SizedBox(height: 18),
                    if (!widget.loading) _tierTrack(score, tier, accent),
                    const SizedBox(height: 16),
                    _hairline(),
                    if (score != null && widget.report != null && widget.scoreOverride == null) ...[
                      _keyRow(widget.report!),
                      _hairline(),
                    ],
                    _slashLine(tier),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hairline() => Container(height: 1, color: _c.hairline());

  Widget _header(Color accent) {
    final c = _c;
    final trimmed = widget.name.trim();
    final muted = c.muted(0.55);
    final score = _score;

    final seasonPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
        color: accent.withValues(alpha: c.isDark ? 0.08 : 0.10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 13, color: accent),
          const SizedBox(width: 4),
          Text(
            '${DateTime.now().year}',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: accent),
          ),
        ],
      ),
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trimmed.isEmpty ? 'Player' : trimmed,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: c.paper,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: widget.onChangeProfile,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.profile?.label ?? 'Set hitting profile',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: muted),
                      ),
                    ),
                    if (widget.onChangeProfile != null) Icon(Icons.expand_more_rounded, size: 15, color: muted),
                    Text(
                      ' · ${widget.gamesLogged} G',
                      style: dashMono(size: 12, weight: FontWeight.w500, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  seasonPill,
                  if (score != null) ...[
                    const SizedBox(width: 8),
                    _RoundIcon(
                      icon: Icons.ios_share_rounded,
                      tooltip: 'Share your rank',
                      onTap: () => _showShareCard(context, score),
                      fg: c.paper,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        _Avatar(name: trimmed, photoUrl: widget.photoUrl, color: accent, ink: c.ink, radius: 38),
      ],
    );
  }

  Widget _rankRow(int? score, RankTier? tier, Color accent, Color deep, Color bright) {
    final c = _c;
    final muted = c.muted(0.55);
    final needed = _gamesForRank - widget.gamesLogged;

    final dial = SizedBox(
      width: 146,
      height: 146,
      child: AnimatedBuilder(
        animation: _dial,
        builder: (_, _) {
          final v = score == null ? 0.0 : _value.value;
          return CustomPaint(
            painter: _DialPainter(value: v, deep: deep, bright: bright, isDark: c.isDark),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score == null ? '—' : '${(v * 100).round()}',
                    style: GoogleFonts.inter(
                      fontSize: 50,
                      fontWeight: FontWeight.w900,
                      color: c.paper,
                      height: 1,
                      letterSpacing: -2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/ 100',
                    style: dashMono(size: 12, weight: FontWeight.w600, color: muted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final Widget words;
    if (score == null || tier == null) {
      words = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rankLabel(muted, 'YOUR RANK'),
          const SizedBox(height: 8),
          _brushTitle('UNRANKED', const Color(0xFF475569), const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            needed > 0
                ? 'Log $needed more ${needed == 1 ? 'game' : 'games'} to get ranked.'
                : 'You have enough games to get ranked.',
            style: GoogleFonts.inter(fontSize: 12.5, height: 1.35, color: muted),
          ),
          if (needed <= 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.paper,
                  foregroundColor: c.ink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: widget.generating ? null : widget.onGenerate,
                child: widget.generating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Get my rank', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      );
    } else {
      final headline = widget.scoreOverride == null ? widget.report?.headline ?? '' : '';
      words = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rankLabel(accent, 'YOUR RANK'),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(a), child: child),
            ),
            child: KeyedSubtree(key: ValueKey(tier.name), child: _brushTitle(tier.name.toUpperCase(), deep, bright)),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _rollPhrase,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                  child: child,
                ),
              ),
              child: Text(
                (_phrase ?? '').toUpperCase(),
                key: ValueKey(_phrase),
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  height: 1.3,
                  color: c.paper,
                ),
              ),
            ),
          ),
          if (headline.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              headline,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, height: 1.35, color: muted),
            ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        dial,
        const SizedBox(width: 16),
        Expanded(child: words),
      ],
    );
  }

  Widget _rankLabel(Color color, String text) => Row(
    children: [
      Icon(Icons.military_tech_rounded, size: 15, color: color),
      const SizedBox(width: 5),
      Text(
        text,
        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: color),
      ),
    ],
  );

  Widget _brushTitle(String text, Color deep, Color bright) {
    final c = _c;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -2,
          right: 8,
          bottom: -7,
          height: 13,
          child: CustomPaint(
            painter: _BrushStrokePainter(deep: deep, bright: bright),
          ),
        ),
        Transform(
          transform: Matrix4.skewX(-0.12)..rotateZ(-0.05),
          alignment: Alignment.bottomLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text.replaceFirst(' ', '\n'),
              maxLines: 2,
              style: GoogleFonts.permanentMarker(
                fontSize: 30,
                height: 0.98,
                color: c.paper,
                shadows: [
                  Shadow(
                    color: deep.withValues(alpha: c.isDark ? 0.9 : 0.35),
                    offset: const Offset(2, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tierTrack(int? score, RankTier? tier, Color accent) {
    final c = _c;
    final muted = c.muted(0.55);
    final next = tier == null ? null : nextRank(tier);
    final deep = tier?.deep ?? const Color(0xFF475569);
    final bright = tier?.bright ?? const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: () => _showTierLadder(context, score),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 14,
            child: AnimatedBuilder(
              animation: _dial,
              builder: (_, _) {
                final animatedScore = score == null ? 0.0 : _value.value * 100;
                final progress = score == null || tier == null
                    ? 0.0
                    : progressTowardNextRank(animatedScore, tier);
                return CustomPaint(
                  painter: _NextRankTrackPainter(
                    value: progress,
                    deep: deep,
                    bright: bright,
                    isDark: c.isDark,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                score == null
                    ? 'Not ranked yet'
                    : next == null
                    ? 'Top tier'
                    : '${score - (tier?.min ?? 0)} / ${next.min - (tier?.min ?? 0)} to next',
                style: dashMono(size: 11.5, weight: FontWeight.w600, color: muted),
              ),
              const Spacer(),
              if (score != null && tier != null)
                Text.rich(
                  TextSpan(
                    children: next == null
                        ? [
                            TextSpan(
                              text: 'All ranks',
                              style: TextStyle(color: accent),
                            ),
                          ]
                        : [
                            const TextSpan(text: 'Next: '),
                            TextSpan(
                              text: next.name,
                              style: TextStyle(
                                color: c.isDark ? next.bright : next.deep,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: '  +${next.min - score}'),
                          ],
                  ),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: muted),
                ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 16, color: muted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyRow(PerformanceReport r) {
    final c = _c;
    final muted = c.muted(0.5);
    final (trend, trendColor, trendIcon) = switch (r.overallTrend) {
      'improving' => ('Heating up', dashPositive, Icons.trending_up_rounded),
      'declining' => ('Cooling off', dashWarning, Icons.trending_down_rounded),
      _ => ('Steady', c.paper, Icons.trending_flat_rounded),
    };
    Widget cell(String label, Widget value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: muted),
          ),
          const SizedBox(height: 5),
          value,
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cell(
            'FOCUS AREA',
            Text(
              r.focusArea.isEmpty ? '—' : r.focusArea,
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: c.paper, height: 1.25),
            ),
          ),
          Container(
            width: 1,
            height: 38,
            color: c.hairline(),
            margin: const EdgeInsets.symmetric(horizontal: 14),
          ),
          cell(
            'RECENT FORM',
            Row(
              children: [
                Icon(trendIcon, size: 17, color: trendColor),
                const SizedBox(width: 6),
                Text(
                  trend,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: trendColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slashLine(RankTier? tier) {
    final c = _c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
      child: AnimatedBuilder(
        animation: _dial,
        builder: (_, _) => _StatBars(
          stats: widget.seasonTotals,
          deep: tier?.deep ?? const Color(0xFF475569),
          bright: tier?.bright ?? const Color(0xFF94A3B8),
          progress: _barsFromZero ? Curves.easeOutCubic.transform(_dial.value) : 1,
          fg: c.paper,
          isDark: c.isDark,
        ),
      ),
    );
  }


  void _showTierLadder(BuildContext context, int? score) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F131B),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AthleteHub ranks*',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _paper),
              ),
              const SizedBox(height: 4),
              Text(
                'Your rank comes from your Scout score.',
                style: GoogleFonts.inter(fontSize: 12.5, height: 1.35, color: _paper.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 14,
                child: CustomPaint(
                  painter: _TierTrackPainter(
                    value: score == null ? 0 : (score.clamp(0, 100) / 100),
                    isDark: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                score == null ? 'Not ranked yet' : '$score / 100',
                style: dashMono(size: 12, weight: FontWeight.w600, color: _paper.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 16),
              for (final t in rankTiers.reversed)
                Builder(
                  builder: (_) {
                    final current = score != null && t.contains(score);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: current ? t.bright.withValues(alpha: 0.12) : Colors.transparent,
                        border: Border.all(
                          color: current ? t.bright.withValues(alpha: 0.6) : _paper.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [t.deep, t.bright]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.name,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: current ? t.bright : _paper,
                              ),
                            ),
                          ),
                          if (current)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                'YOU',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: t.bright,
                                ),
                              ),
                            ),
                          Text('${t.min}–${t.max}', style: dashMono(size: 12, color: _paper.withValues(alpha: 0.55))),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              Text(
                '*AthleteHub ranks are a fun way to track your own performance, based only on the games you log. '
                'They are not recruiting or scouting information and are not reviewed or endorsed by any coach, scout, school or league.',
                style: GoogleFonts.inter(fontSize: 11, height: 1.35, color: _paper.withValues(alpha: 0.45)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareCard(BuildContext context, int score) {
    HapticFeedback.lightImpact();
    final boundary = GlobalKey();
    final tier = rankFor(score);
    final phrase = _phrase ?? tier.phrases.first;
    final name = widget.name.trim().isEmpty ? 'Player' : widget.name.trim();
    final messenger = ScaffoldMessenger.of(context);
    final photo = widget.photoUrl;
    final photoReady = photo == null || photo.isEmpty
        ? Future<void>.value()
        : precacheImage(NetworkImage(photo), context).catchError((_) {});
    var busy = false;

    Future<void> share(BuildContext buttonContext, void Function(bool) setBusy) async {
      setBusy(true);
      try {
        await photoReady;
        await WidgetsBinding.instance.endOfFrame;
        final render = boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (render == null) throw StateError('Share card not on screen');
        final image = await render.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) throw StateError('Could not encode image');
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/athletehub_rank_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(bytes.buffer.asUint8List());

        // Popover origin for iPad; image-only so Instagram/Facebook keep the photo.
        final box = buttonContext.findRenderObject() as RenderBox?;
        final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            fileNameOverrides: ['AthleteHub-rank.png'],
            sharePositionOrigin: origin,
          ),
        );
      } catch (_) {
        messenger.showSnackBar(const SnackBar(content: Text("Couldn't create the image. Try again.")));
      } finally {
        setBusy(false);
      }
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F131B),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: StatefulBuilder(
            builder: (context, setSheet) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.62),
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: RepaintBoundary(
                      key: boundary,
                      child: _ShareCard(
                        name: name,
                        score: score,
                        tier: tier,
                        phrase: phrase,
                        stats: widget.seasonTotals,
                        games: widget.gamesLogged,
                        photoUrl: widget.photoUrl,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Builder(
                    builder: (buttonContext) => FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _paper,
                        foregroundColor: _ink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: busy ? null : () => share(buttonContext, (v) => setSheet(() => busy = v)),
                      icon: busy
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.ios_share_rounded, size: 18),
                      label: Text('Share or save image', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Save to Photos, or send to Messages, Instagram, TikTok, Snapchat, Facebook and more.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11.5, height: 1.35, color: _paper.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final Color color;
  final Color ink;
  final double radius;

  const _Avatar({
    required this.name,
    required this.photoUrl,
    required this.color,
    required this.ink,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isEmpty
        ? '?'
        : name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase();
    final photo = photoUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    return Container(
      padding: EdgeInsets.all(radius * 0.08),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [color, color.withValues(alpha: 0.25), color]),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: radius * 0.55)],
      ),
      child: Container(
        padding: EdgeInsets.all(radius * 0.05),
        decoration: BoxDecoration(shape: BoxShape.circle, color: ink),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF1E2430),
          backgroundImage: hasPhoto ? NetworkImage(photo) : null,
          child: hasPhoto
              ? null
              : Text(
                  initials,
                  style: GoogleFonts.inter(fontSize: radius * 0.6, fontWeight: FontWeight.w800, color: Colors.white),
                ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color fg;

  const _RoundIcon({required this.icon, required this.tooltip, required this.onTap, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fg.withValues(alpha: 0.08),
            border: Border.all(color: fg.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, size: 15, color: fg),
        ),
      ),
    );
  }
}

// Share card

class _ShareCard extends StatelessWidget {
  final String name;
  final int score;
  final RankTier tier;
  final String phrase;
  final PlayerStats stats;
  final int games;
  final String? photoUrl;

  const _ShareCard({
    required this.name,
    required this.score,
    required this.tier,
    required this.phrase,
    required this.stats,
    required this.games,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: CustomPaint(
        painter: _PosterPainter(deep: tier.deep, bright: tier.bright, glow: 1),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _AthleteHubMark(size: 20),
                  const SizedBox(width: 7),
                  Text(
                    'ATHLETEHUB',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                      color: _paper,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'SEASON ${DateTime.now().year}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: tier.bright,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: _paper,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text('$games games', style: dashMono(size: 11, color: _paper.withValues(alpha: 0.55))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Avatar(name: name, photoUrl: photoUrl, color: tier.bright, ink: _ink, radius: 28),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: _DialPainter(value: score / 100, deep: tier.deep, bright: tier.bright, compact: true),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: _paper,
                                letterSpacing: -1.5,
                                height: 1,
                              ),
                            ),
                            Text('/ 100', style: dashMono(size: 10, color: _paper.withValues(alpha: 0.55))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RANK*',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            color: tier.bright,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            tier.name.toUpperCase(),
                            style: GoogleFonts.permanentMarker(fontSize: 26, color: _paper, height: 1),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"$phrase"',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                            color: _paper.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _StatBars(
                stats: stats,
                deep: tier.deep,
                bright: tier.bright,
                progress: 1,
                compact: true,
                fg: _paper,
                isDark: true,
              ),
              const SizedBox(height: 12),
              Text(
                '*AthleteHub performance rank for fun. Not recruiting or scouting information.',
                style: GoogleFonts.inter(fontSize: 9, letterSpacing: 0.3, color: _paper.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Season slash stats with bars vs max (HR vs at-bats).
class _StatBars extends StatelessWidget {
  final PlayerStats stats;
  final Color deep;
  final Color bright;
  final double progress;
  final bool compact;
  final Color fg;
  final bool isDark;

  const _StatBars({
    required this.stats,
    required this.deep,
    required this.bright,
    required this.progress,
    required this.fg,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final ab = s.atBats;
    final rows = [
      ('AVG', _rate(s.battingAverage), '1.000', s.battingAverage),
      ('OBP', _rate(s.onBasePercentage), '1.000', s.onBasePercentage),
      ('SLG', _rate(s.sluggingPercentage), '4.000', s.sluggingPercentage / 4),
      ('OPS', _rate(s.onBasePlusSlugging), '5.000', s.onBasePlusSlugging / 5),
      ('HR', '${s.homeRuns}', '$ab AB', ab == 0 ? 0.0 : s.homeRuns / ab),
    ];
    final gap = compact ? 7.0 : 10.0;
    final valueSize = compact ? 13.5 : 15.0;
    final muted = fg.withValues(alpha: 0.5);

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  rows[i].$1,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: muted),
                ),
              ),
              SizedBox(
                width: compact ? 50 : 56,
                child: Text(
                  rows[i].$2,
                  textAlign: TextAlign.right,
                  style: dashMono(size: valueSize, weight: FontWeight.w700, color: fg),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: compact ? 6 : 7,
                  child: CustomPaint(
                    painter: _StatBarPainter(
                      fraction: rows[i].$4.clamp(0.0, 1.0) * progress,
                      deep: deep,
                      bright: bright,
                      track: fg.withValues(alpha: isDark ? 0.08 : 0.10),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: compact ? 52 : 58,
                child: Text(
                  '/ ${rows[i].$3}',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  style: dashMono(size: compact ? 9.5 : 10.5, color: muted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatBarPainter extends CustomPainter {
  final double fraction;
  final Color deep;
  final Color bright;
  final Color track;

  _StatBarPainter({required this.fraction, required this.deep, required this.bright, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, r), Paint()..color = track);
    if (fraction <= 0) return;
    final w = math.max(size.height, size.width * fraction);
    final fill = Rect.fromLTWH(0, 0, w, size.height);
    final shader = LinearGradient(colors: [deep, bright]).createShader(fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fill, r),
      Paint()
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(fill, r), Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_StatBarPainter old) =>
      old.fraction != fraction || old.deep != deep || old.bright != bright || old.track != track;
}

class _AthleteHubMark extends StatelessWidget {
  final double size;
  const _AthleteHubMark({required this.size});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final blue = Paint()
      ..color = const Color(0xFF4A8CF7)
      ..strokeWidth = s * 0.14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.12, s * 0.9)
        ..lineTo(s * 0.45, s * 0.12)
        ..lineTo(s * 0.62, s * 0.5),
      blue,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.18, s * 0.78)
        ..lineTo(s * 0.42, s * 0.6)
        ..lineTo(s * 0.55, s * 0.68)
        ..lineTo(s * 0.88, s * 0.2),
      blue,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.68, s * 0.18)
        ..lineTo(s * 0.9, s * 0.16)
        ..lineTo(s * 0.88, s * 0.38),
      blue,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => false;
}

// Painters

/// Dark poster background for the rank card.
class _PosterPainter extends CustomPainter {
  final Color deep;
  final Color bright;
  final double glow;
  final bool isDark;

  _PosterPainter({required this.deep, required this.bright, required this.glow, this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = isDark
        ? const [Color(0xFF0E1320), _ink, Color(0xFF07090E)]
        : const [Color(0xFFFFFFFF), Color(0xFFF7F7F8), Color(0xFFFFFFFF)];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bg,
        ).createShader(rect),
    );

    final glowMul = isDark ? 1.0 : 0.55;
    canvas.drawCircle(
      Offset(size.width * 0.95, -size.height * 0.05),
      size.width * 0.75,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                bright.withValues(alpha: 0.30 * glow * glowMul),
                bright.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: Offset(size.width * 0.95, -size.height * 0.05), radius: size.width * 0.75),
            ),
    );
    canvas.drawCircle(
      Offset(-size.width * 0.1, size.height * 0.55),
      size.width * 0.6,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                deep.withValues(alpha: 0.28 * glow * glowMul),
                deep.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: Offset(-size.width * 0.1, size.height * 0.55), radius: size.width * 0.6),
            ),
    );

    canvas.save();
    canvas.clipRect(rect);
    final mark = isDark ? _paper : const Color(0xFF111111);
    final stripe = Paint()
      ..color = mark.withValues(alpha: isDark ? 0.035 : 0.04)
      ..strokeWidth = 14;
    for (var i = 0; i < 7; i++) {
      final x = size.width * 0.45 + i * 34.0;
      canvas.drawLine(Offset(x, -20), Offset(x + 160, size.height * 0.55), stripe..strokeWidth = i.isEven ? 14 : 5);
    }

    final ballCenter = Offset(size.width * 0.98, size.height * 0.28);
    final r = size.width * 0.34;
    canvas.drawCircle(
      ballCenter,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = mark.withValues(alpha: isDark ? 0.07 : 0.08),
    );
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = mark.withValues(alpha: isDark ? 0.08 : 0.09);
    for (final side in [-1.0, 1.0]) {
      final arc = Rect.fromCircle(center: ballCenter + Offset(side * r * 0.95, 0), radius: r * 0.62);
      final start = side < 0 ? -math.pi / 2.6 : math.pi - math.pi / 2.6;
      canvas.drawArc(arc, start, math.pi / 1.3, false, seam);
      for (var k = 1; k < 9; k++) {
        final a = start + math.pi / 1.3 * k / 9;
        final p = arc.center + Offset(math.cos(a), math.sin(a)) * arc.width / 2;
        final n = Offset(math.cos(a), math.sin(a));
        final t = Offset(-n.dy, n.dx);
        canvas.drawLine(p - n * 4 + t * 3, p + n * 4 + t * 3, seam);
      }
    }
    canvas.restore();

    final grain = Paint()..color = mark.withValues(alpha: isDark ? 0.025 : 0.03);
    final rng = math.Random(11);
    for (var i = 0; i < 260; i++) {
      canvas.drawCircle(Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height), 0.6, grain);
    }
  }

  @override
  bool shouldRepaint(_PosterPainter old) =>
      old.deep != deep || old.bright != bright || old.glow != glow || old.isDark != isDark;
}

/// Score dial ring.
class _DialPainter extends CustomPainter {
  final double value;
  final Color deep;
  final Color bright;
  final bool compact;
  final bool isDark;

  _DialPainter({
    required this.value,
    required this.deep,
    required this.bright,
    this.compact = false,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = compact ? 8.0 : 11.0;
    final radius = size.width / 2 - stroke / 2 - (compact ? 2 : 9);
    final v = value.clamp(0.0, 1.0);

    if (!compact) {
      const ticks = 60;
      for (var i = 0; i < ticks; i++) {
        final a = -math.pi / 2 + i / ticks * 2 * math.pi;
        final dir = Offset(math.cos(a), math.sin(a));
        final major = i % 5 == 0;
        final lit = i / ticks <= v && v > 0;
        canvas.drawLine(
          center + dir * (radius + stroke / 2 + 3),
          center + dir * (radius + stroke / 2 + (major ? 8 : 5)),
          Paint()
            ..strokeWidth = major ? 1.6 : 1
            ..strokeCap = StrokeCap.round
            ..color = lit ? bright.withValues(alpha: major ? 0.9 : 0.6) : (isDark ? _paper : const Color(0xFF111111)).withValues(alpha: isDark ? 0.12 : 0.14),
        );
      }
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = (isDark ? _paper : const Color(0xFF111111)).withValues(alpha: isDark ? 0.08 : 0.10),
    );
    if (v <= 0) return;

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi * v;
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: math.max(sweep, 0.01),
      colors: [deep, bright],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(arcRect);

    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 6
        ..strokeCap = StrokeCap.round
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
        ..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );

    final tipAngle = -math.pi / 2 + sweep;
    final tip = center + Offset(math.cos(tipAngle), math.sin(tipAngle)) * radius;
    canvas.drawCircle(
      tip,
      stroke * 0.9,
      Paint()
        ..color = bright.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(tip, stroke * 0.32, Paint()..color = isDark ? _paper : Colors.white);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.value != value ||
      old.deep != deep ||
      old.bright != bright ||
      old.compact != compact ||
      old.isDark != isDark;
}

/// Brush underline under the rank title.
class _BrushStrokePainter extends CustomPainter {
  final Color deep;
  final Color bright;

  _BrushStrokePainter({required this.deep, required this.bright});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final w = size.width;
    final h = size.height;
    const steps = 24;
    final top = <Offset>[];
    final bottom = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = w * t;
      final lift = -h * 0.35 * t;
      final thickness = h * (0.25 + 0.75 * math.sin(math.pi * math.pow(t, 0.7)));
      top.add(Offset(x, h / 2 + lift - thickness / 2 + (rng.nextDouble() - 0.5) * 1.6));
      bottom.add(Offset(x, h / 2 + lift + thickness / 2 + (rng.nextDouble() - 0.5) * 1.6));
    }
    final path = Path()..moveTo(top.first.dx, top.first.dy);
    for (final p in top.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in bottom.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    final shader = LinearGradient(colors: [deep, bright]).createShader(Offset.zero & size);
    canvas.drawPath(path, Paint()..shader = shader);

    final bristle = Paint()
      ..strokeWidth = 0.8
      ..color = bright.withValues(alpha: 0.7);
    for (var i = 0; i < 5; i++) {
      final y = h * (0.35 + i * 0.12);
      final start = w * (0.55 + rng.nextDouble() * 0.2);
      canvas.drawLine(Offset(start, y - h * 0.35 * start / w), Offset(w * 1.03, y - h * 0.38), bristle);
    }
  }

  @override
  bool shouldRepaint(_BrushStrokePainter old) => old.deep != deep || old.bright != bright;
}

/// Single bar: progress through the current tier toward the next rank.
class _NextRankTrackPainter extends CustomPainter {
  final double value;
  final Color deep;
  final Color bright;
  final bool isDark;

  _NextRankTrackPainter({
    required this.value,
    required this.deep,
    required this.bright,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const h = 6.0;
    final y = (size.height - h) / 2;
    final v = value.clamp(0.0, 1.0);
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, y, size.width, h),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      track,
      Paint()..color = (isDark ? _paper : const Color(0xFF111111)).withValues(alpha: isDark ? 0.08 : 0.10),
    );
    if (v > 0) {
      final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, y, size.width * v, h),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        fill,
        Paint()
          ..shader = LinearGradient(colors: [deep, bright]).createShader(Rect.fromLTWH(0, y, size.width, h)),
      );
      final x = size.width * v;
      canvas.drawCircle(
        Offset(x, size.height / 2),
        6,
        Paint()
          ..color = bright.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(Offset(x, size.height / 2), 3.6, Paint()..color = isDark ? _paper : Colors.white);
    }
  }

  @override
  bool shouldRepaint(_NextRankTrackPainter old) =>
      old.value != value || old.deep != deep || old.bright != bright || old.isDark != isDark;
}

/// Segmented 0–100 tier track (all ranks).
class _TierTrackPainter extends CustomPainter {
  final double value;
  final bool isDark;

  _TierTrackPainter({required this.value, this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    const h = 6.0;
    const gap = 3.0;
    final y = (size.height - h) / 2;
    final v = value.clamp(0.0, 1.0);
    for (final t in rankTiers) {
      final start = t.min / 100;
      final end = t == rankTiers.last ? 1.0 : (t.max + 1) / 100;
      final left = size.width * start + (t == rankTiers.first ? 0 : gap / 2);
      final right = size.width * end - (t == rankTiers.last ? 0 : gap / 2);
      final seg = Rect.fromLTRB(left, y, right, y + h);
      final r = RRect.fromRectAndRadius(seg, const Radius.circular(3));
      canvas.drawRRect(
        r,
        Paint()..color = (isDark ? _paper : const Color(0xFF111111)).withValues(alpha: isDark ? 0.08 : 0.10),
      );
      if (v > start) {
        final fillRight = math.min(right, size.width * v);
        if (fillRight > left) {
          canvas.save();
          canvas.clipRRect(r);
          canvas.drawRect(
            Rect.fromLTRB(left, y, fillRight, y + h),
            Paint()..shader = LinearGradient(colors: [t.deep, t.bright]).createShader(seg),
          );
          canvas.restore();
        }
      }
    }
    if (v > 0) {
      final x = size.width * v;
      canvas.drawCircle(
        Offset(x, size.height / 2),
        6,
        Paint()
          ..color = rankFor((v * 100).round()).bright.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(Offset(x, size.height / 2), 3.6, Paint()..color = isDark ? _paper : Colors.white);
    }
  }

  @override
  bool shouldRepaint(_TierTrackPainter old) => old.value != value || old.isDark != isDark;
}
