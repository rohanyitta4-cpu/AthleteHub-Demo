import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../player_stats.dart';
import '../utils/season_stats_pipeline.dart';

/// One logged game, parsed the same way the app's screens parse it.
class ExportGame {
  final String id;
  final DateTime? date;
  final Map<String, dynamic> raw;
  final PlayerStats stats;

  ExportGame({required this.id, required this.date, required this.raw})
    : stats = playerStatsFromFirestoreGame(raw);

  Map<String, dynamic> get _meta {
    final m = raw['metadata'];
    return m is Map ? Map<String, dynamic>.from(m) : const {};
  }

  String get opponent =>
      (raw['opponent'] ?? _meta['opponent'] ?? '').toString();
  String get location =>
      (raw['location'] ?? _meta['location'] ?? '').toString();
  String get notes => (raw['notes'] ?? _meta['notes'] ?? '').toString();

  Map<String, dynamic> get rawStats {
    final s = raw['stats'];
    return s is Map ? Map<String, dynamic>.from(s) : const {};
  }
}

/// One season with its games oldest first (game 1 is the first game played).
class ExportSeason {
  final String id;
  final String name;
  final bool isActive;
  final DateTime? startDate;
  final Map<String, dynamic> raw;
  final List<ExportGame> games;

  ExportSeason({
    required this.id,
    required this.name,
    required this.isActive,
    required this.startDate,
    required this.raw,
    required this.games,
  });

  PlayerStats get totals => PlayerStats.sum(games.map((g) => g.stats));
}

DateTime? _asDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Every season and game for [uid]. No `orderBy` on the queries: Firestore
/// drops documents missing the ordered field, and exports must include all.
Future<List<ExportSeason>> loadExportSeasons(
  FirebaseFirestore db,
  String uid,
) async {
  final seasonsSnap = await db
      .collection('users')
      .doc(uid)
      .collection('seasons')
      .get();
  final seasons = <ExportSeason>[];
  for (final s in seasonsSnap.docs) {
    final gamesSnap = await s.reference.collection('games').get();
    final games = [
      for (final g in gamesSnap.docs)
        ExportGame(id: g.id, date: _asDate(g.data()['date']), raw: g.data()),
    ]..sort(_byDate);
    final data = s.data();
    seasons.add(
      ExportSeason(
        id: s.id,
        name: (data['name'] ?? '').toString().trim().isEmpty
            ? 'Season'
            : data['name'].toString(),
        isActive: data['isActive'] == true,
        startDate: _asDate(data['startDate']),
        raw: data,
        games: games,
      ),
    );
  }
  return sortSeasons(seasons);
}

int _byDate(ExportGame a, ExportGame b) {
  if (a.date == null && b.date == null) return a.id.compareTo(b.id);
  if (a.date == null) return 1;
  if (b.date == null) return -1;
  return a.date!.compareTo(b.date!);
}

/// Active season first, then newest first by start date (or first game).
List<ExportSeason> sortSeasons(List<ExportSeason> seasons) {
  DateTime? key(ExportSeason s) =>
      s.startDate ?? (s.games.isEmpty ? null : s.games.first.date);
  return [...seasons]..sort((a, b) {
    if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
    final ka = key(a);
    final kb = key(b);
    if (ka == null && kb == null) return 0;
    if (ka == null) return 1;
    if (kb == null) return -1;
    return kb.compareTo(ka);
  });
}

// ---------------------------------------------------------------------------
// Shared numbers
// ---------------------------------------------------------------------------

int _totalBases(PlayerStats s) =>
    s.hits + s.doubles + 2 * s.triples + 3 * s.homeRuns;
int _singles(PlayerStats s) => s.hits - s.doubles - s.triples - s.homeRuns;
bool _hasObpDenominator(PlayerStats s) =>
    s.atBats + s.walks + s.hitByPitch + s.sacrificeFlies > 0;

String _rate(double v) => v.isFinite ? v.toStringAsFixed(3) : '';
String _ip(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// AVG, OBP, SLG, OPS, ISO from totals; blank when there is no denominator.
List<String> _rates(PlayerStats s) => [
  s.atBats > 0 ? _rate(s.battingAverage) : '',
  _hasObpDenominator(s) ? _rate(s.onBasePercentage) : '',
  s.atBats > 0 ? _rate(s.sluggingPercentage) : '',
  _hasObpDenominator(s) && s.atBats > 0 ? _rate(s.onBasePlusSlugging) : '',
  s.atBats > 0 ? _rate(s.isolatedPower) : '',
];

String _era(PlayerStats s) =>
    s.inningsPitched > 0 ? s.era.toStringAsFixed(2) : '';

// ---------------------------------------------------------------------------
// CSV
// ---------------------------------------------------------------------------

/// Every alias [PlayerStats.fromJson] reads, plus stored snapshots of derived
/// numbers. Anything else in a game's stats map becomes its own CSV column.
const _parsedStatKeys = {
  'atBats', 'at_bats', 'atBatCount', 'At Bats',
  'runs', 'runCount', 'Runs',
  'hits', 'hitCount', 'Hits',
  'doubles', 'doubles_count', 'doubleCount', 'Doubles',
  'triples', 'triples_count', 'tripleCount', 'Triples',
  'homeRuns', 'home_runs', 'homeRunCount', 'home_runs_count', 'Home Runs',
  'walks', 'walk', 'walkCount', 'Walks',
  'hitByPitch', 'hit_by_pitch', 'hitByPitchCount', 'Hit By Pitch',
  'strikeouts', 'strikeout_count', 'strikeoutCount', 'Strikeouts',
  'sacrificeHits',
  'sacrifice_hits',
  'sacrifice_bunts',
  'Sacrifice Hits',
  'Sacrifice Bunts',
  'sacrificeFlies', 'sacrifice_flies', 'Sacrifice Flies',
  'intentionalWalks', 'intentional_walks', 'Intentional Walks',
  'stolenBases', 'stolen_bases', 'stolenBaseCount', 'Stolen Bases',
  'runsBattedIn', 'rbi', 'rbiCount', 'RBI',
  'twoStrikeCounts', 'strike_count', 'strikeCount', 'Two-Strike Count',
  'successWithTwoStrikes',
  'success_with_2_strikes',
  'successWith2StrikesCount',
  'Two-Strike Success',
  'inningsPitched', 'innings_pitched', 'Innings Pitched',
  'earnedRuns', 'earned_runs', 'earnedRunCount', 'Earned Runs',
  'totalPitches', 'pitches_thrown', 'pitchesThrownCount', 'Pitches Thrown',
  'hardHitBalls', 'hard_hit_balls', 'Hard-Hit Balls',
  'hardHitGames', 'hardHitBallsInPlay',
  'qualityAtBats', 'quality_at_bats', 'Quality At-Bats',
  'qabGames', 'qabPlateAppearances',
  // Derived values some saves stored; the export recomputes them from totals.
  'era', 'whip', 'avg', 'obp', 'slg', 'ops', 'war',
  'battingAverage', 'batting_average', 'onBasePercentage', 'sluggingPercentage',
  'onBasePlusSlugging', 'isolatedPower',
};

const _csvHeader = [
  'Season',
  'Active season',
  'Game #',
  'Date',
  'Opponent',
  'Location',
  'PA',
  'AB',
  'R',
  'H',
  '1B',
  '2B',
  '3B',
  'HR',
  'RBI',
  'BB',
  'IBB',
  'HBP',
  'K',
  'SAC',
  'SF',
  'SB',
  'TB',
  'Two-strike PA',
  'Two-strike success',
  'Hard-hit balls',
  'Quality at-bats',
  'IP',
  'ER',
  'Pitches',
  'AVG',
  'OBP',
  'SLG',
  'OPS',
  'ISO',
  'ERA',
];

String _csvCell(String s) {
  if (s.contains(',') ||
      s.contains('"') ||
      s.contains('\n') ||
      s.contains('\r')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

List<String> _statCells(PlayerStats s) => [
  '${s.plateAppearances}',
  '${s.atBats}',
  '${s.runs}',
  '${s.hits}',
  '${_singles(s)}',
  '${s.doubles}',
  '${s.triples}',
  '${s.homeRuns}',
  '${s.runsBattedIn}',
  '${s.walks}',
  '${s.intentionalWalks}',
  '${s.hitByPitch}',
  '${s.strikeouts}',
  '${s.sacrificeHits}',
  '${s.sacrificeFlies}',
  '${s.stolenBases}',
  '${_totalBases(s)}',
  '${s.twoStrikeCounts}',
  '${s.successWithTwoStrikes}',
  s.tracksHardHit ? '${s.hardHitBalls}' : '',
  s.tracksQualityAtBats ? '${s.qualityAtBats}' : '',
  _ip(s.inningsPitched),
  '${s.earnedRuns}',
  '${s.totalPitches}',
  ..._rates(s),
  _era(s),
];

/// One row per game across every season, a TOTAL row after each season and a
/// CAREER row when there is more than one season. Rates come from totals.
/// Extra stats the app doesn't chart (caught stealing, fielding, ...) are
/// appended as their own columns, plus notes and the game's ID.
String buildCsv(List<ExportSeason> seasons) {
  final extraKeys = <String>{};
  for (final s in seasons) {
    for (final g in s.games) {
      for (final e in g.rawStats.entries) {
        final v = e.value;
        if (_parsedStatKeys.contains(e.key) || e.key.endsWith('List')) continue;
        if (v is num || v is bool || v is String) extraKeys.add(e.key);
      }
    }
  }
  final extras = extraKeys.toList()..sort();
  final numericExtras = {
    for (final k in extras)
      k: seasons.every(
        (s) =>
            s.games.every((g) => g.rawStats[k] == null || g.rawStats[k] is num),
      ),
  };

  String extraTotal(String k, List<ExportGame> games) {
    if (!numericExtras[k]!) return '';
    final values = games.map((g) => g.rawStats[k]).whereType<num>();
    if (values.isEmpty) return '';
    final total = values.fold<num>(0, (a, b) => a + b);
    return total is int || total == total.roundToDouble()
        ? '${total.round()}'
        : '$total';
  }

  final rows = <List<String>>[
    [..._csvHeader, ...extras, 'Notes', 'Game ID'],
  ];
  final dateFmt = DateFormat('yyyy-MM-dd');
  for (final s in seasons) {
    for (var i = 0; i < s.games.length; i++) {
      final g = s.games[i];
      rows.add([
        s.name,
        s.isActive ? 'yes' : 'no',
        '${i + 1}',
        g.date == null ? '' : dateFmt.format(g.date!),
        g.opponent,
        g.location,
        ..._statCells(g.stats),
        for (final k in extras) g.rawStats[k]?.toString() ?? '',
        g.notes,
        g.id,
      ]);
    }
    rows.add([
      s.name,
      s.isActive ? 'yes' : 'no',
      'TOTAL (${s.games.length} ${s.games.length == 1 ? 'game' : 'games'})',
      '',
      '',
      '',
      ..._statCells(s.totals),
      for (final k in extras) extraTotal(k, s.games),
      '',
      '',
    ]);
  }
  if (seasons.length > 1) {
    final all = [for (final s in seasons) ...s.games];
    rows.add([
      'All seasons',
      '',
      'CAREER (${all.length} games)',
      '',
      '',
      '',
      ..._statCells(PlayerStats.sum(all.map((g) => g.stats))),
      for (final k in extras) extraTotal(k, all),
      '',
      '',
    ]);
  }
  return '${rows.map((r) => r.map(_csvCell).join(',')).join('\r\n')}\r\n';
}

// ---------------------------------------------------------------------------
// JSON
// ---------------------------------------------------------------------------

/// Converts Firestore values anywhere in a structure into plain JSON values.
dynamic jsonSafe(dynamic v) {
  if (v == null || v is String || v is bool || v is int) return v;
  if (v is double) return v.isFinite ? v : null;
  if (v is Timestamp) return v.toDate().toUtc().toIso8601String();
  if (v is DateTime) return v.toUtc().toIso8601String();
  if (v is GeoPoint) return {'latitude': v.latitude, 'longitude': v.longitude};
  if (v is DocumentReference) return v.path;
  if (v is Blob) return base64Encode(v.bytes);
  if (v is Map) {
    return {for (final e in v.entries) e.key.toString(): jsonSafe(e.value)};
  }
  if (v is Iterable) return [for (final e in v) jsonSafe(e)];
  return v.toString();
}

Map<String, dynamic> _summary(PlayerStats s, int games) {
  final rates = _rates(s);
  double? num(String v) => v.isEmpty ? null : double.parse(v);
  return {
    'games': games,
    'plateAppearances': s.plateAppearances,
    'atBats': s.atBats,
    'runs': s.runs,
    'hits': s.hits,
    'singles': _singles(s),
    'doubles': s.doubles,
    'triples': s.triples,
    'homeRuns': s.homeRuns,
    'runsBattedIn': s.runsBattedIn,
    'walks': s.walks,
    'intentionalWalks': s.intentionalWalks,
    'hitByPitch': s.hitByPitch,
    'strikeouts': s.strikeouts,
    'sacrificeHits': s.sacrificeHits,
    'sacrificeFlies': s.sacrificeFlies,
    'stolenBases': s.stolenBases,
    'totalBases': _totalBases(s),
    'twoStrikePlateAppearances': s.twoStrikeCounts,
    'twoStrikeSuccesses': s.successWithTwoStrikes,
    if (s.tracksHardHit) 'hardHitBalls': s.hardHitBalls,
    if (s.tracksQualityAtBats) 'qualityAtBats': s.qualityAtBats,
    'inningsPitched': s.inningsPitched,
    'earnedRuns': s.earnedRuns,
    'pitches': s.totalPitches,
    'battingAverage': num(rates[0]),
    'onBasePercentage': num(rates[1]),
    'sluggingPercentage': num(rates[2]),
    'onBasePlusSlugging': num(rates[3]),
    'isolatedPower': num(rates[4]),
    'earnedRunAverage': s.inningsPitched > 0 ? double.parse(_era(s)) : null,
  };
}

/// Full backup: the profile and every season and game exactly as stored, plus
/// computed per-game and season numbers that match the app.
Map<String, dynamic> buildJsonPayload({
  required String uid,
  required String? email,
  required Map<String, dynamic>? user,
  required List<ExportSeason> seasons,
  DateTime? now,
}) {
  final all = [for (final s in seasons) ...s.games];
  return {
    'exportVersion': 2,
    'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
    'userId': uid,
    'userEmail': email,
    'user': jsonSafe(user ?? const {}),
    'career': _summary(PlayerStats.sum(all.map((g) => g.stats)), all.length),
    'seasons': [
      for (final s in seasons)
        {
          'id': s.id,
          'name': s.name,
          'isActive': s.isActive,
          'totals': _summary(s.totals, s.games.length),
          'data': jsonSafe(s.raw),
          'games': [
            for (var i = 0; i < s.games.length; i++)
              {
                'id': s.games[i].id,
                'gameNumber': i + 1,
                'date': jsonSafe(s.games[i].date),
                'computed': _summary(s.games[i].stats, 1)..remove('games'),
                'data': jsonSafe(s.games[i].raw),
              },
          ],
        },
    ],
  };
}

String buildJson(Map<String, dynamic> payload) =>
    const JsonEncoder.withIndent('  ').convert(payload);

// ---------------------------------------------------------------------------
// PDF
// ---------------------------------------------------------------------------

String _pdfRate(String v) =>
    v.isEmpty ? '-' : (v.startsWith('0.') ? v.substring(1) : v);

/// The built-in PDF fonts only cover Latin-1; anything else (emoji, CJK)
/// would print as an empty box.
String _pdfText(String s) => String.fromCharCodes(
  s.runes.where((r) => r <= 0xFF),
).replaceAll(RegExp(r'\s+'), ' ').trim();

/// Report with the player header, career and per-season totals, and the full
/// game log for every season.
Future<Uint8List> buildPdf({
  required String displayName,
  required String email,
  required List<ExportSeason> seasons,
  Uint8List? photoBytes,
  DateTime? now,
}) async {
  final generated = DateFormat(
    'MMM d, yyyy h:mm a',
  ).format(now ?? DateTime.now());
  final name = _pdfText(displayName).isEmpty
      ? 'Athlete'
      : _pdfText(displayName);
  final mail = _pdfText(email);
  final dateFmt = DateFormat('MMM d, yyyy');
  final shortDate = DateFormat('M/d/yy');
  final all = [for (final s in seasons) ...s.games];
  final career = PlayerStats.sum(all.map((g) => g.stats));
  final pdf = pw.Document(
    title: 'AthleteHub report - $name',
    author: 'AthleteHub',
  );

  const small = pw.TextStyle(fontSize: 8);
  const muted = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);
  final h2 = pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold);
  final h3 = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);

  pw.Widget statBoxes(PlayerStats s) {
    final r = _rates(s);
    final items = [
      ('AVG', _pdfRate(r[0])),
      ('OBP', _pdfRate(r[1])),
      ('SLG', _pdfRate(r[2])),
      ('OPS', _pdfRate(r[3])),
      ('HR', '${s.homeRuns}'),
      ('RBI', '${s.runsBattedIn}'),
      ('H', '${s.hits}'),
      ('SB', '${s.stolenBases}'),
    ];
    return pw.Row(
      children: [
        for (final (label, value) in items)
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(right: 4),
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
              child: pw.Column(
                children: [
                  pw.Text(label, style: muted),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    value,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget table(
    List<String> headers,
    List<List<String>> data, {
    int leftColumns = 1,
  }) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: data,
    headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
    cellStyle: small,
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2.5),
    cellAlignments: {
      for (var i = 0; i < headers.length; i++)
        i: i < leftColumns ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
    },
    headerAlignments: {
      for (var i = 0; i < headers.length; i++)
        i: i < leftColumns ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
    },
  );

  List<String> countingRow(PlayerStats s) => [
    '${s.plateAppearances}',
    '${s.atBats}',
    '${s.runs}',
    '${s.hits}',
    '${s.doubles}',
    '${s.triples}',
    '${s.homeRuns}',
    '${s.runsBattedIn}',
    '${s.walks}',
    '${s.hitByPitch}',
    '${s.strikeouts}',
    '${s.stolenBases}',
    '${s.sacrificeHits}',
    '${s.sacrificeFlies}',
    '${_totalBases(s)}',
  ];
  const countingHeaders = [
    'PA',
    'AB',
    'R',
    'H',
    '2B',
    '3B',
    'HR',
    'RBI',
    'BB',
    'HBP',
    'K',
    'SB',
    'SAC',
    'SF',
    'TB',
  ];

  /// Flat list so MultiPage can break the game log across pages.
  List<pw.Widget> seasonSection(ExportSeason s) {
    final t = s.totals;
    final r = _rates(t);
    final pitching = s.games.any((g) => g.stats.inningsPitched > 0);
    final range = s.games.isEmpty || s.games.first.date == null
        ? ''
        : '${dateFmt.format(s.games.first.date!)} - ${dateFmt.format((s.games.last.date ?? s.games.first.date)!)}';
    final extras = <String>[
      if (t.twoStrikeCounts > 0)
        'Two-strike: ${t.successWithTwoStrikes} of ${t.twoStrikeCounts} '
            '(${(t.successWithTwoStrikes / t.twoStrikeCounts * 100).round()}%)',
      if (t.tracksHardHit)
        'Hard-hit balls: ${t.hardHitBalls} (${(t.hardHitRate * 100).round()}% of balls in play)',
      if (t.tracksQualityAtBats)
        'Quality at-bats: ${t.qualityAtBats} (${(t.qualityAtBatRate * 100).round()}% of PA)',
      if (t.intentionalWalks > 0) 'Intentional walks: ${t.intentionalWalks}',
    ];

    return [
      pw.Text(
        '${_pdfText(s.name)}${s.isActive ? '  (current season)' : ''}',
        style: h2,
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        '${s.games.length} ${s.games.length == 1 ? 'game' : 'games'}${range.isEmpty ? '' : '  |  $range'}',
        style: muted,
      ),
      pw.SizedBox(height: 8),
      if (s.games.isEmpty)
        pw.Text('No games logged.', style: muted)
      else ...[
        statBoxes(t),
        pw.SizedBox(height: 8),
        pw.Text('Season totals', style: h3),
        pw.SizedBox(height: 4),
        table(
          ['G', ...countingHeaders],
          [
            ['${s.games.length}', ...countingRow(t)],
          ],
          leftColumns: 0,
        ),
        pw.SizedBox(height: 4),
        table(
          ['AVG', 'OBP', 'SLG', 'OPS', 'ISO'],
          [
            [for (final v in r) _pdfRate(v)],
          ],
          leftColumns: 0,
        ),
        if (pitching) ...[
          pw.SizedBox(height: 4),
          table(
            ['IP', 'ER', 'ERA', 'Pitches'],
            [
              [
                _ip(t.inningsPitched),
                '${t.earnedRuns}',
                _era(t),
                '${t.totalPitches}',
              ],
            ],
            leftColumns: 0,
          ),
        ],
        if (extras.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          for (final e in extras) pw.Text(e, style: small),
        ],
        pw.SizedBox(height: 10),
        pw.Text('Game log', style: h3),
        pw.SizedBox(height: 4),
        table(
          [
            '#',
            'Date',
            'AB',
            'R',
            'H',
            '2B',
            '3B',
            'HR',
            'RBI',
            'BB',
            'HBP',
            'K',
            'SB',
            if (pitching) ...['IP', 'ER'],
            'AVG',
            'Season AVG',
          ],
          [
            for (var i = 0; i < s.games.length; i++)
              () {
                final g = s.games[i].stats;
                final toDate = PlayerStats.sum(
                  s.games.take(i + 1).map((x) => x.stats),
                );
                final d = s.games[i].date;
                return [
                  '${i + 1}',
                  d == null ? '-' : shortDate.format(d),
                  '${g.atBats}',
                  '${g.runs}',
                  '${g.hits}',
                  '${g.doubles}',
                  '${g.triples}',
                  '${g.homeRuns}',
                  '${g.runsBattedIn}',
                  '${g.walks}',
                  '${g.hitByPitch}',
                  '${g.strikeouts}',
                  '${g.stolenBases}',
                  if (pitching) ...[_ip(g.inningsPitched), '${g.earnedRuns}'],
                  g.atBats > 0 ? _pdfRate(_rate(g.battingAverage)) : '-',
                  toDate.atBats > 0
                      ? _pdfRate(_rate(toDate.battingAverage))
                      : '-',
                ];
              }(),
          ],
          leftColumns: 2,
        ),
      ],
      pw.SizedBox(height: 22),
    ];
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('AthleteHub  |  $name', style: muted),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: muted,
          ),
        ],
      ),
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'AthleteHub',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Performance report',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (mail.isNotEmpty)
                  pw.Text(mail, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text('Generated $generated', style: muted),
              ],
            ),
            if (photoBytes != null)
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                ),
                child: pw.Image(
                  pw.MemoryImage(photoBytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 20),
        if (all.isEmpty)
          pw.Text('No games logged yet.', style: muted)
        else ...[
          if (seasons.length > 1) ...[
            pw.Text(
              'Career  |  ${all.length} games across ${seasons.length} seasons',
              style: h2,
            ),
            pw.SizedBox(height: 8),
            statBoxes(career),
            pw.SizedBox(height: 4),
            table(
              ['G', ...countingHeaders],
              [
                ['${all.length}', ...countingRow(career)],
              ],
              leftColumns: 0,
            ),
            pw.SizedBox(height: 22),
          ],
          for (final s in seasons) ...seasonSection(s),
          pw.Text(
            'Averages are computed from totals (for example, hits divided by at-bats), '
            'the same way the app computes them. A dash means the stat did not apply, '
            'such as batting average in a game with no at-bats.',
            style: muted,
          ),
        ],
      ],
    ),
  );
  return pdf.save();
}
