import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_first_app_vsc/services/export_builders.dart';

ExportGame game(String id, DateTime date, Map<String, dynamic> stats, {Map<String, dynamic>? extra}) =>
    ExportGame(
      id: id,
      date: date,
      raw: {'date': Timestamp.fromDate(date), 'stats': stats, ...?extra},
    );

void main() {
  final day = DateTime(2025, 3, 1);
  final current = ExportSeason(
    id: 's2',
    name: 'Spring 2025',
    isActive: true,
    startDate: day,
    raw: {'name': 'Spring 2025', 'startDate': Timestamp.fromDate(day)},
    games: [
      for (var i = 0; i < 68; i++)
        game('g$i', day.add(Duration(days: i)), {
          // Zuno-style snake_case keys, like real saves.
          'at_bats': i % 9 == 0 ? 0 : 3,
          'hits': i % 9 == 0 ? 0 : (i % 3),
          'home_runs': i == 10 ? 1 : 0,
          'rbi': i % 4,
          'walks': i % 9 == 0 ? 1 : 0,
          'caught_stealing': i == 5 ? 1 : 0,
          'era': 0.0,
        }),
    ],
  );
  final old = ExportSeason(
    id: 's1',
    name: 'Fall 2024',
    isActive: false,
    startDate: DateTime(2024, 9, 1),
    raw: {
      'name': 'Fall 2024',
      'history': [Timestamp.fromDate(DateTime(2024, 9, 1)), const GeoPoint(40, -74)],
    },
    games: [
      game('h1', DateTime(2024, 9, 2), {'atBats': 4, 'hits': 2, 'doubles': 1},
          extra: {'opponent': 'Tigers, JV', 'notes': 'Said "nice"'}),
    ],
  );
  final seasons = sortSeasons([old, current]);

  test('active season sorts first and games are oldest first', () {
    expect(seasons.map((s) => s.name), ['Spring 2025', 'Fall 2024']);
  });

  test('CSV has every game, season totals, career row and extra fields', () {
    final csv = buildCsv(seasons);
    final lines = csv.trim().split('\r\n');
    // header + 68 games + total + 1 game + total + career
    expect(lines.length, 1 + 68 + 1 + 1 + 1 + 1);
    final header = lines.first.split(',');
    expect(header, containsAll(['AVG', 'OBP', 'caught_stealing', 'Notes', 'Game ID']));
    expect(header, isNot(contains('era')));

    int col(String name) => header.indexOf(name);
    final firstGame = lines[1].split(',');
    expect(firstGame[col('AB')], '0');
    expect(firstGame[col('AVG')], '', reason: 'no at-bats means no AVG, not .000');
    expect(firstGame[col('OBP')], '1.000');

    final total = lines[69].split(',');
    expect(total[col('Game #')], 'TOTAL (68 games)');
    final ab = int.parse(total[col('AB')]);
    final h = int.parse(total[col('H')]);
    expect(total[col('AVG')], (h / ab).toStringAsFixed(3));
    expect(total[col('caught_stealing')], '1');
    expect(lines.last, startsWith('All seasons,,CAREER (69 games)'));
    expect(csv, contains('"Tigers, JV"'));
    expect(csv, contains('"Said ""nice"""'));
    File('/tmp/athletehub_test_export.csv').writeAsStringSync(csv);
  });

  test('JSON encodes nested Firestore values and includes computed totals', () {
    final payload = buildJsonPayload(
      uid: 'u1',
      email: 'a@b.c',
      user: {
        'createdAt': Timestamp.fromDate(day),
        'prefs': {'lastSeen': Timestamp.fromDate(day)},
      },
      seasons: seasons,
    );
    final text = buildJson(payload);
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    expect(decoded['career']['games'], 69);
    final s0 = decoded['seasons'][0];
    expect((s0['games'] as List).length, 68);
    expect(s0['games'][0]['computed']['battingAverage'], isNull);
    expect(s0['games'][0]['data']['stats']['caught_stealing'], 0);
    expect(decoded['seasons'][1]['data']['history'][1], {'latitude': 40.0, 'longitude': -74.0});
    expect(decoded['user']['prefs']['lastSeen'], isA<String>());
    File('/tmp/athletehub_test_backup.json').writeAsStringSync(text);
  });

  test('PDF builds a multi-page report with every game', () async {
    final bytes = await buildPdf(displayName: 'Test Player', email: 'a@b.c', seasons: seasons);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    File('/tmp/athletehub_test_report.pdf').writeAsBytesSync(bytes);
  });

  test('PDF survives accented names and emoji', () async {
    final bytes = await buildPdf(displayName: 'José Ñúñez 🔥', email: '', seasons: seasons);
    expect(bytes, isNotEmpty);
    File('/tmp/athletehub_test_report_unicode.pdf').writeAsBytesSync(bytes);
  });
}
