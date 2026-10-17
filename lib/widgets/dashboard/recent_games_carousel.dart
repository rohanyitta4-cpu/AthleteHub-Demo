import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../models/hitting_profile.dart';
import '../../player_stats.dart';
import '../../utils/game_highlight.dart';
import 'dash_style.dart';

class CarouselGame {
  final DateTime? date;
  final PlayerStats stats;

  /// 1-based position in the season.
  final int number;
  final String? opponent;

  const CarouselGame({required this.date, required this.stats, required this.number, this.opponent});
}

/// Short tags for what stood out in a game, most notable first.
List<String> gameTags(PlayerStats s) {
  final plateAppearances = s.atBats + s.walks + s.hitByPitch + s.sacrificeFlies + s.sacrificeHits;
  final timesOnBase = s.hits + s.walks + s.hitByPitch;
  final extraBase = s.doubles + s.triples;
  return [
    if (s.homeRuns > 0) s.homeRuns == 1 ? 'Home run' : '${s.homeRuns} HR',
    if (s.hits >= 3) '${s.hits}-hit game' else if (s.hits == 2) 'Multi-hit',
    if (extraBase > 0) extraBase == 1 ? 'Extra-base hit' : '$extraBase XBH',
    if (s.runsBattedIn >= 2) '${s.runsBattedIn} RBI',
    if (timesOnBase >= 3) 'On base ${timesOnBase}x',
    if (s.stolenBases > 0) s.stolenBases == 1 ? 'Stolen base' : '${s.stolenBases} SB',
    if (s.strikeouts == 0 && plateAppearances >= 3) 'No strikeouts',
  ];
}

Color _toneColor(HighlightTone tone, bool isDark) => switch (tone) {
  HighlightTone.positive => dashPositive,
  HighlightTone.neutral => dashBorder(isDark),
  HighlightTone.negative => dashWarning,
};

String _rate(double v) {
  final s = v.toStringAsFixed(3);
  return s.startsWith('0.') ? s.substring(1) : s;
}

int _totalBases(PlayerStats s) {
  final singles = s.hits - s.doubles - s.triples - s.homeRuns;
  return singles + 2 * s.doubles + 3 * s.triples + 4 * s.homeRuns;
}

String _extraBaseHits(PlayerStats s) {
  String part(int n, String label) => n == 0 ? '' : (n == 1 ? label : '$n$label');
  final parts = [part(s.doubles, '2B'), part(s.triples, '3B'), part(s.homeRuns, 'HR')].where((p) => p.isNotEmpty);
  return parts.isEmpty ? '—' : parts.join(' ');
}

/// 3D rotating carousel of recent games shown as mini box scores. Advances on
/// its own every few seconds; tapping a card opens the full box score.
class RecentGamesCarousel extends StatefulWidget {
  final List<CarouselGame> games;
  final HittingProfile? profile;

  /// Tints card borders, tags and the page dots; null keeps the neutral look.
  final Color? accent;

  const RecentGamesCarousel({super.key, required this.games, required this.profile, this.accent});

  @override
  State<RecentGamesCarousel> createState() => _RecentGamesCarouselState();
}

class _RecentGamesCarouselState extends State<RecentGamesCarousel> {
  static const _autoAdvanceEvery = Duration(seconds: 5);

  final _controller = PageController(viewportFraction: 0.82);
  Timer? _autoTimer;
  bool _autoAdvancing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartAutoAdvance();
  }

  @override
  void didUpdateWidget(RecentGamesCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.games.length != widget.games.length) _restartAutoAdvance();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartAutoAdvance() {
    _autoTimer?.cancel();
    if (widget.games.length < 2 || MediaQuery.of(context).disableAnimations) return;
    _autoTimer = Timer.periodic(_autoAdvanceEvery, (_) => _advance());
  }

  Future<void> _advance() async {
    if (!mounted || !_controller.hasClients || !TickerMode.of(context)) return;
    final current = (_controller.page ?? 0).round();
    final next = (current + 1) % widget.games.length;
    _autoAdvancing = true;
    await _controller.animateToPage(
      next,
      duration: Duration(milliseconds: next == 0 ? 900 : 650),
      curve: Curves.easeInOutCubic,
    );
    _autoAdvancing = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Column(
      children: [
        SizedBox(
          height: 216,
          child: Listener(
            onPointerDown: (_) => _autoTimer?.cancel(),
            onPointerUp: (_) => _restartAutoAdvance(),
            onPointerCancel: (_) => _restartAutoAdvance(),
            child: PageView.builder(
              controller: _controller,
              clipBehavior: Clip.none,
              itemCount: widget.games.length,
              onPageChanged: (_) {
                if (!_autoAdvancing) HapticFeedback.selectionClick();
              },
              itemBuilder: (context, index) {
                final game = widget.games[index];
                final card = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                  child: GestureDetector(
                    onTap: () async {
                      _autoTimer?.cancel();
                      await _showGameDetail(context, game, widget.profile);
                      if (mounted) _restartAutoAdvance();
                    },
                    child: _GameCard(game: game, profile: widget.profile, isDark: isDark, accent: widget.accent),
                  ),
                );
                if (reduceMotion) return card;
                return AnimatedBuilder(
                  animation: _controller,
                  child: card,
                  builder: (context, child) {
                    double page = 0;
                    if (_controller.hasClients && _controller.position.haveDimensions) {
                      page = _controller.page ?? 0;
                    }
                    final delta = (index - page).clamp(-1.0, 1.0);
                    final scale = 1 - delta.abs() * 0.08;
                    return Opacity(
                      opacity: 1 - delta.abs() * 0.4,
                      child: Transform(
                        alignment: delta > 0 ? Alignment.centerLeft : Alignment.centerRight,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateY(delta * -0.4)
                          ..scaleByDouble(scale, scale, 1, 1),
                        child: child,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (widget.games.length > 1) ...[
          const SizedBox(height: 8),
          SmoothPageIndicator(
            controller: _controller,
            count: widget.games.length,
            effect: ExpandingDotsEffect(
              dotHeight: 4,
              dotWidth: 4,
              expansionFactor: 4,
              spacing: 4,
              activeDotColor: widget.accent ?? dashText(isDark),
              dotColor: dashBorder(isDark),
            ),
          ),
        ],
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final CarouselGame game;
  final HittingProfile? profile;
  final bool isDark;
  final Color? accent;

  const _GameCard({required this.game, required this.profile, required this.isDark, this.accent});

  @override
  Widget build(BuildContext context) {
    final s = game.stats;
    final highlight = gameHighlight(s, profile);
    final date = game.date;
    final text = dashText(isDark);
    final muted = dashMuted(isDark);
    final tint = accent;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: tint == null
          ? dashCard(isDark, radius: 12)
          : dashCard(isDark, radius: 12).copyWith(
              border: Border.all(color: tint.withValues(alpha: 0.10)),
              gradient: RadialGradient(
                center: const Alignment(1.1, -1.2),
                radius: 0.95,
                colors: [tint.withValues(alpha: 0.035), dashSurface(isDark)],
              ),
            ),
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 3, color: _toneColor(highlight.tone, isDark))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      date == null ? 'NO DATE' : DateFormat('EEE MMM d').format(date).toUpperCase(),
                      style: dashLabel(isDark),
                    ),
                    if (game.opponent != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'vs ${game.opponent}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: text),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text('G${game.number}', style: dashMono(size: 11, color: muted)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${s.hits}-${s.atBats}',
                      style: dashMono(size: 28, weight: FontWeight.w800, color: text, height: 1),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('H-AB', style: dashLabel(isDark, size: 9.5)),
                    ),
                    const Spacer(),
                    Padding(padding: const EdgeInsets.only(bottom: 2), child: _inlinePair('XBH', _extraBaseHits(s))),
                    const SizedBox(width: 12),
                    Padding(padding: const EdgeInsets.only(bottom: 2), child: _inlinePair('TB', '${_totalBases(s)}')),
                  ],
                ),
                const SizedBox(height: 12),
                _LineScore(stats: s, isDark: isDark),
                const SizedBox(height: 10),
                _TagRow(tags: gameTags(s), isDark: isDark, accent: tint),
                const Spacer(),
                Row(
                  children: [
                    Text('NOTE', style: dashLabel(isDark, size: 9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        highlight.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: highlight.tone == HighlightTone.neutral ? muted : _toneColor(highlight.tone, isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlinePair(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(label, style: dashLabel(isDark, size: 9)),
        const SizedBox(width: 4),
        Text(
          value,
          style: dashMono(size: 12.5, weight: FontWeight.w700, color: dashText(isDark)),
        ),
      ],
    );
  }
}

/// One line of tags; extra tags are dropped rather than wrapped.
class _TagRow extends StatelessWidget {
  final List<String> tags;
  final bool isDark;
  final Color? accent;

  const _TagRow({required this.tags, required this.isDark, this.accent});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final text = dashText(isDark);
    final fill = accent?.withValues(alpha: 0.06) ?? text.withValues(alpha: 0.07);
    return SizedBox(
      height: 22,
      child: ClipRect(
        child: Wrap(
          spacing: 6,
          clipBehavior: Clip.hardEdge,
          children: [
            for (final tag in tags.take(3))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(11)),
                child: Text(
                  tag,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: text),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Scorebook-style line: labels on top, monospace values beneath.
class _LineScore extends StatelessWidget {
  final PlayerStats stats;
  final bool isDark;

  const _LineScore({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final columns = [
      ('AB', s.atBats),
      ('R', s.runs),
      ('H', s.hits),
      ('RBI', s.runsBattedIn),
      ('BB', s.walks),
      ('K', s.strikeouts),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: dashBorder(isDark))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0) Container(width: 1, height: 28, color: dashBorder(isDark)),
            Expanded(
              child: Column(
                children: [
                  Text(columns[i].$1, style: dashLabel(isDark, size: 9)),
                  const SizedBox(height: 3),
                  Text(
                    '${columns[i].$2}',
                    style: dashMono(
                      size: 15,
                      weight: FontWeight.w700,
                      color: columns[i].$2 == 0 ? dashMuted(isDark) : dashText(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showGameDetail(BuildContext context, CarouselGame game, HittingProfile? profile) {
  HapticFeedback.lightImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final s = game.stats;
  final highlight = gameHighlight(s, profile);
  final text = dashText(isDark);
  final muted = dashMuted(isDark);

  final battingRows = <List<(String, String)>>[
    [
      ('AB', '${s.atBats}'),
      ('R', '${s.runs}'),
      ('H', '${s.hits}'),
      ('RBI', '${s.runsBattedIn}'),
      ('BB', '${s.walks}'),
      ('K', '${s.strikeouts}'),
    ],
    [
      ('2B', '${s.doubles}'),
      ('3B', '${s.triples}'),
      ('HR', '${s.homeRuns}'),
      ('HBP', '${s.hitByPitch}'),
      ('SB', '${s.stolenBases}'),
      ('SAC', '${s.sacrificeHits + s.sacrificeFlies}'),
    ],
    [
      ('AVG', _rate(s.battingAverage)),
      ('OBP', _rate(s.onBasePercentage)),
      ('SLG', _rate(s.sluggingPercentage)),
      ('TB', '${_totalBases(s)}'),
    ],
  ];

  Widget table(List<(String, String)> cells) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: dashBorder(isDark))),
    ),
    child: Row(
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) Container(width: 1, height: 30, color: dashBorder(isDark)),
          Expanded(
            child: Column(
              children: [
                Text(cells[i].$1, style: dashLabel(isDark, size: 9.5)),
                const SizedBox(height: 4),
                Text(
                  cells[i].$2,
                  style: dashMono(size: 16, weight: FontWeight.w700, color: text),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: dashSurface(isDark),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    [
                      game.date == null ? 'Game ${game.number}' : DateFormat('EEEE, MMM d').format(game.date!),
                      if (game.opponent != null) 'vs ${game.opponent}',
                    ].join(' · '),
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: text),
                  ),
                ),
                Text('G${game.number}', style: dashMono(size: 12, color: muted)),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: dashBorder(isDark)),
            for (final row in battingRows) table(row),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(width: 64, child: Text('NOTE', style: dashLabel(isDark, size: 9.5))),
                Expanded(
                  child: Text(
                    highlight.text,
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: text),
                  ),
                ),
              ],
            ),
            if (profile != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(width: 64, child: Text('LENS', style: dashLabel(isDark, size: 9.5))),
                  Expanded(
                    child: Text(
                      profile.label,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: muted),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
