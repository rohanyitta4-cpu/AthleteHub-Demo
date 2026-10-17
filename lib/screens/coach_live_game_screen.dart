import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game_setup_screen.dart';
import '../utils/friendly_error.dart';

enum _InPlayStep { fielder, playType, outcome, batterDest, runners, confirm }

class _InPlaySelection {
  _InPlaySelection({
    required this.fielder,
    required this.playType,
    required this.outcome,
    required this.batterDest,
    required this.runnerDests,
    required this.rbiCount,
    required this.description,
  });

  final int fielder;
  final String playType;
  final String outcome;
  final String batterDest; // out, 1B, 2B, 3B, home
  final Map<String, String> runnerDests; // 1st/2nd/3rd -> hold/2nd/3rd/home/out
  final int rbiCount;
  final String description;
}

class CoachLiveGameScreen extends StatefulWidget {
  const CoachLiveGameScreen({super.key});

  @override
  State<CoachLiveGameScreen> createState() => _CoachLiveGameScreenState();
}

class _CoachLiveGameScreenState extends State<CoachLiveGameScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _teamId;
  String? _selectedGameId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoachTeam();
  }

  Future<void> _loadCoachTeam() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No coach logged in.';
          _isLoading = false;
        });
        return;
      }

      final teamsQuery = await _firestore
          .collection('teams')
          .where('coachIds', arrayContains: user.uid)
          .limit(1)
          .get();

      if (teamsQuery.docs.isEmpty) {
        setState(() {
          _error = 'No team found for this coach account.';
          _isLoading = false;
        });
        return;
      }

      final teamId = teamsQuery.docs.first.id;
      final gamesQuery = await _firestore
          .collection('games')
          .where('teamHome', isEqualTo: teamId)
          .orderBy('date', descending: true)
          .limit(20)
          .get();

      String? selected;
      for (final doc in gamesQuery.docs) {
        final state = (doc.data()['state'] as String?) ?? 'scheduled';
        if (state == 'inProgress') {
          selected = doc.id;
          break;
        }
      }

      selected ??= gamesQuery.docs.isNotEmpty ? gamesQuery.docs.first.id : null;

      setState(() {
        _teamId = teamId;
        _selectedGameId = selected;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = friendlyError(e, "Couldn't load your team");
        _isLoading = false;
      });
    }
  }

  Future<void> _withGameUpdate(
    DocumentSnapshot<Map<String, dynamic>> gameDoc,
    Map<String, dynamic> Function(Map<String, dynamic> gameData) updater,
  ) async {
    final gameData = gameDoc.data() ?? <String, dynamic>{};
    final patch = updater(gameData);
    patch['updatedAt'] = FieldValue.serverTimestamp();
    await gameDoc.reference.set(patch, SetOptions(merge: true));
  }

  Map<String, dynamic> _trackerFrom(Map<String, dynamic> gameData) {
    final metadata = (gameData['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final tracker = (metadata['liveTracker'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return {
      'balls': (tracker['balls'] as num?)?.toInt() ?? 0,
      'strikes': (tracker['strikes'] as num?)?.toInt() ?? 0,
      'outs': (tracker['outs'] as num?)?.toInt() ?? ((gameData['outs'] as num?)?.toInt() ?? 0),
      'currentBatterIndex': (tracker['currentBatterIndex'] as num?)?.toInt() ?? 0,
      'currentAtBatPitches':
          List<String>.from((tracker['currentAtBatPitches'] as List<dynamic>?) ?? const []),
    };
  }

  Map<String, bool> _runnersFrom(Map<String, dynamic> gameData) {
    final raw = (gameData['runners'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return {
      '1st': (raw['1st'] as bool?) ?? false,
      '2nd': (raw['2nd'] as bool?) ?? false,
      '3rd': (raw['3rd'] as bool?) ?? false,
    };
  }

  Map<String, int> _scoreFrom(Map<String, dynamic> gameData) {
    final raw = (gameData['score'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return {
      'home': (raw['home'] as num?)?.toInt() ?? 0,
      'away': (raw['away'] as num?)?.toInt() ?? 0,
    };
  }

  String _halfFrom(Map<String, dynamic> gameData) {
    final half = (gameData['half'] as String?) ?? 'top';
    return half == 'bottom' ? 'bottom' : 'top';
  }

  int _inningFrom(Map<String, dynamic> gameData) {
    return (gameData['inning'] as num?)?.toInt() ?? 1;
  }

  Future<void> _startGame(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    await gameDoc.reference.set({
      'state': 'inProgress',
      'metadata': {
        'liveTracker': {
          'balls': 0,
          'strikes': 0,
          'outs': 0,
          'currentBatterIndex': 0,
          'currentAtBatPitches': <String>[],
        }
      }
    }, SetOptions(merge: true));
  }

  void _pushPitch(List<String> pitches, String code) {
    pitches.add(code);
    if (pitches.length > 12) {
      pitches.removeAt(0);
    }
  }

  void _advanceForcedRunners({
    required Map<String, bool> runners,
    required Map<String, int> score,
    required bool isTop,
  }) {
    if (runners['1st'] == true) {
      if (runners['2nd'] == true) {
        if (runners['3rd'] == true) {
          if (isTop) {
            score['away'] = (score['away'] ?? 0) + 1;
          } else {
            score['home'] = (score['home'] ?? 0) + 1;
          }
        }
        runners['3rd'] = true;
      }
      runners['2nd'] = true;
    }
    runners['1st'] = true;
  }

  Future<void> _recordBall(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final tracker = _trackerFrom(gameData);
      final runners = _runnersFrom(gameData);
      final score = _scoreFrom(gameData);
      final isTop = _halfFrom(gameData) == 'top';

      final pitches = List<String>.from(tracker['currentAtBatPitches'] as List<String>);
      _pushPitch(pitches, 'B');

      int balls = (tracker['balls'] as int) + 1;
      int batterIndex = tracker['currentBatterIndex'] as int;
      if (balls >= 4) {
        _advanceForcedRunners(runners: runners, score: score, isTop: isTop);
        balls = 0;
        batterIndex += 1;
        pitches.clear();
      }

      return {
        'runners': runners,
        'score': score,
        'metadata': {
          'liveTracker': {
            ...tracker,
            'balls': balls,
            'strikes': 0,
            'currentBatterIndex': batterIndex,
            'currentAtBatPitches': pitches,
          }
        }
      };
    });
  }

  Future<void> _recordIntentionalWalk(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final tracker = _trackerFrom(gameData);
      final runners = _runnersFrom(gameData);
      final score = _scoreFrom(gameData);
      final isTop = _halfFrom(gameData) == 'top';

      _advanceForcedRunners(runners: runners, score: score, isTop: isTop);
      final pitches = List<String>.from(tracker['currentAtBatPitches'] as List<String>);
      _pushPitch(pitches, 'IBB');

      return {
        'runners': runners,
        'score': score,
        'events': FieldValue.arrayUnion([
          '${DateTime.now().toIso8601String()}|Intentional walk'
        ]),
        'metadata': {
          'liveTracker': {
            ...tracker,
            'balls': 0,
            'strikes': 0,
            'currentBatterIndex': (tracker['currentBatterIndex'] as int) + 1,
            'currentAtBatPitches': <String>[],
          }
        }
      };
    });
  }

  Future<void> _recordFoul(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final tracker = _trackerFrom(gameData);
      final pitches = List<String>.from(tracker['currentAtBatPitches'] as List<String>);
      _pushPitch(pitches, 'F');

      final strikes = tracker['strikes'] as int;
      return {
        'metadata': {
          'liveTracker': {
            ...tracker,
            'strikes': strikes < 2 ? strikes + 1 : 2,
            'currentAtBatPitches': pitches,
          }
        }
      };
    });
  }

  Map<String, dynamic> _endHalfInningPatch(Map<String, dynamic> gameData, Map<String, dynamic> tracker) {
    final inning = _inningFrom(gameData);
    final half = _halfFrom(gameData);
    final isTop = half == 'top';

    return {
      'inning': isTop ? inning : inning + 1,
      'half': isTop ? 'bottom' : 'top',
      'outs': 0,
      'runners': {'1st': false, '2nd': false, '3rd': false},
      'metadata': {
        'liveTracker': {
          ...tracker,
          'outs': 0,
          'balls': 0,
          'strikes': 0,
          'currentAtBatPitches': <String>[],
        }
      }
    };
  }

  Future<void> _recordStrike(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final tracker = _trackerFrom(gameData);
      final pitches = List<String>.from(tracker['currentAtBatPitches'] as List<String>);
      _pushPitch(pitches, 'K');

      int strikes = (tracker['strikes'] as int) + 1;
      int outs = tracker['outs'] as int;
      int batterIndex = tracker['currentBatterIndex'] as int;
      if (strikes >= 3) {
        outs += 1;
        batterIndex += 1;
        strikes = 0;
        pitches.clear();
      }

      if (outs >= 3) {
        return _endHalfInningPatch(gameData, tracker);
      }

      return {
        'outs': outs,
        'metadata': {
          'liveTracker': {
            ...tracker,
            'strikes': strikes,
            'balls': 0,
            'outs': outs,
            'currentBatterIndex': batterIndex,
            'currentAtBatPitches': pitches,
          }
        }
      };
    });
  }

  Future<void> _recordHbp(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final tracker = _trackerFrom(gameData);
      final runners = _runnersFrom(gameData);
      final score = _scoreFrom(gameData);
      final isTop = _halfFrom(gameData) == 'top';
      final pitches = List<String>.from(tracker['currentAtBatPitches'] as List<String>);
      _pushPitch(pitches, 'HBP');

      _advanceForcedRunners(runners: runners, score: score, isTop: isTop);

      return {
        'runners': runners,
        'score': score,
        'metadata': {
          'liveTracker': {
            ...tracker,
            'balls': 0,
            'strikes': 0,
            'currentBatterIndex': (tracker['currentBatterIndex'] as int) + 1,
            'currentAtBatPitches': <String>[],
          }
        }
      };
    });
  }

  Future<void> _recordWildPitch(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final runners = _runnersFrom(gameData);
      final score = _scoreFrom(gameData);
      final isTop = _halfFrom(gameData) == 'top';
      final tracker = _trackerFrom(gameData);

      if (runners['3rd'] == true) {
        if (isTop) {
          score['away'] = (score['away'] ?? 0) + 1;
        } else {
          score['home'] = (score['home'] ?? 0) + 1;
        }
      }

      final newThird = runners['2nd'] == true;
      final newSecond = runners['1st'] == true;
      runners['3rd'] = newThird;
      runners['2nd'] = newSecond;
      runners['1st'] = false;

      return {
        'runners': runners,
        'score': score,
        'events': FieldValue.arrayUnion([
          '${DateTime.now().toIso8601String()}|Wild pitch'
        ]),
        'metadata': {'liveTracker': tracker}
      };
    });
  }

  Future<void> _recordPassedBall(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final runners = _runnersFrom(gameData);
      final score = _scoreFrom(gameData);
      final isTop = _halfFrom(gameData) == 'top';
      final tracker = _trackerFrom(gameData);

      if (runners['3rd'] == true) {
        if (isTop) {
          score['away'] = (score['away'] ?? 0) + 1;
        } else {
          score['home'] = (score['home'] ?? 0) + 1;
        }
      }
      final newThird = runners['2nd'] == true;
      final newSecond = runners['1st'] == true;
      runners['3rd'] = newThird;
      runners['2nd'] = newSecond;
      runners['1st'] = false;

      return {
        'runners': runners,
        'score': score,
        'events': FieldValue.arrayUnion([
          '${DateTime.now().toIso8601String()}|Passed ball'
        ]),
        'metadata': {'liveTracker': tracker}
      };
    });
  }

  Future<void> _recordBalk(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final runners = _runnersFrom(gameData);
      final score = _scoreFrom(gameData);
      final isTop = _halfFrom(gameData) == 'top';
      final tracker = _trackerFrom(gameData);

      if (runners['3rd'] == true) {
        if (isTop) {
          score['away'] = (score['away'] ?? 0) + 1;
        } else {
          score['home'] = (score['home'] ?? 0) + 1;
        }
      }
      final newThird = runners['2nd'] == true;
      final newSecond = runners['1st'] == true;
      runners['3rd'] = newThird;
      runners['2nd'] = newSecond;
      runners['1st'] = false;

      return {
        'runners': runners,
        'score': score,
        'events': FieldValue.arrayUnion([
          '${DateTime.now().toIso8601String()}|Balk - runners advance'
        ]),
        'metadata': {'liveTracker': tracker}
      };
    });
  }

  Future<void> _recordPickoff({
    required DocumentSnapshot<Map<String, dynamic>> gameDoc,
    required String base,
    required bool safe,
  }) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final runners = _runnersFrom(gameData);
      final tracker = _trackerFrom(gameData);
      int outs = tracker['outs'] as int;

      if (!safe) {
        if (base == '1st') runners['1st'] = false;
        if (base == '2nd') runners['2nd'] = false;
        if (base == '3rd') runners['3rd'] = false;
        outs += 1;
      }

      final patch = {
        'runners': runners,
        'outs': outs,
        'events': FieldValue.arrayUnion([
          '${DateTime.now().toIso8601String()}|Pickoff at $base - ${safe ? 'safe' : 'out'}'
        ]),
        'metadata': {
          'liveTracker': {
            ...tracker,
            'outs': outs,
          }
        }
      };

      if (outs >= 3) {
        return _endHalfInningPatch(gameData, tracker);
      }
      return patch;
    });
  }

  Future<void> _recordStolenBase({
    required DocumentSnapshot<Map<String, dynamic>> gameDoc,
    required String fromBase,
    required bool safe,
  }) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final runners = _runnersFrom(gameData);
      final tracker = _trackerFrom(gameData);
      int outs = tracker['outs'] as int;

      String toBase = fromBase == '1st'
          ? '2nd'
          : fromBase == '2nd'
              ? '3rd'
              : 'home';

      if (safe) {
        if (fromBase == '1st') runners['1st'] = false;
        if (fromBase == '2nd') runners['2nd'] = false;
        if (fromBase == '3rd') runners['3rd'] = false;

        if (toBase == '2nd') runners['2nd'] = true;
        if (toBase == '3rd') runners['3rd'] = true;
      } else {
        if (fromBase == '1st') runners['1st'] = false;
        if (fromBase == '2nd') runners['2nd'] = false;
        if (fromBase == '3rd') runners['3rd'] = false;
        outs += 1;
      }

      return {
        'runners': runners,
        'outs': outs,
        'events': FieldValue.arrayUnion([
          '${DateTime.now().toIso8601String()}|Stolen base from $fromBase - ${safe ? 'safe to $toBase' : 'caught stealing'}'
        ]),
        'metadata': {
          'liveTracker': {
            ...tracker,
            'outs': outs,
          }
        }
      };
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadRosterDocs() async {
    if (_teamId == null) return const [];
    final snap = await _firestore
        .collection('teams')
        .doc(_teamId)
        .collection('roster_entries')
        .get();
    return snap.docs;
  }

  Future<void> _openSubstitutionSheet(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    final rosterDocs = await _loadRosterDocs();
    if (!mounted) return;

    if (rosterDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No roster entries found for this team.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        int tab = 0;
        String? pinchHitterId;
        String? pinchRunnerId;
        String? runnerBase;
        String? defensePlayerId;
        String defensePos = 'P';
        const defensePositions = ['P', 'C', '1B', '2B', '3B', 'SS', 'LF', 'CF', 'RF'];

        String displayName(Map<String, dynamic> d, String fallback) {
          final name = (d['name'] ?? '').toString().trim();
          if (name.isNotEmpty) return name;
          final first = (d['firstName'] ?? '').toString().trim();
          final last = (d['lastName'] ?? '').toString().trim();
          final full = '$first $last'.trim();
          if (full.isNotEmpty) return full;
          return fallback;
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget rosterDropdown({
              required String? currentValue,
              required ValueChanged<String?> onChanged,
              required String hint,
            }) {
              return DropdownButtonFormField<String>(
                initialValue: currentValue,
                decoration: InputDecoration(
                  labelText: hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: rosterDocs.map((doc) {
                  final d = doc.data();
                  final name = displayName(d, doc.id);
                  final jersey = (d['jerseyNumber'] ?? '').toString();
                  final label = jersey.isEmpty ? name : '#$jersey $name';
                  final value = (d['playerId'] ?? doc.id).toString();
                  return DropdownMenuItem(value: value, child: Text(label));
                }).toList(),
                onChanged: onChanged,
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Substitution',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Pinch Hitter')),
                        ButtonSegment(value: 1, label: Text('Pinch Runner')),
                        ButtonSegment(value: 2, label: Text('Defense')),
                      ],
                      selected: {tab},
                      onSelectionChanged: (s) => setSheetState(() => tab = s.first),
                    ),
                    const SizedBox(height: 12),
                    if (tab == 0) ...[
                      rosterDropdown(
                        currentValue: pinchHitterId,
                        onChanged: (v) => setSheetState(() => pinchHitterId = v),
                        hint: 'Select pinch hitter',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: pinchHitterId == null
                              ? null
                              : () async {
                                  await _withGameUpdate(gameDoc, (gameData) {
                                    final tracker = _trackerFrom(gameData);
                                    return {
                                      'metadata': {
                                        'liveTracker': {
                                          ...tracker,
                                          'currentBatterId': pinchHitterId,
                                        }
                                      },
                                      'events': FieldValue.arrayUnion([
                                        '${DateTime.now().toIso8601String()}|Pinch hitter: $pinchHitterId'
                                      ]),
                                    };
                                  });
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: const Text('Confirm pinch hitter'),
                        ),
                      ),
                    ],
                    if (tab == 1) ...[
                      DropdownButtonFormField<String>(
                        initialValue: runnerBase,
                        decoration: const InputDecoration(
                          labelText: 'Replace runner on base',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: '1st', child: Text('1st base')),
                          DropdownMenuItem(value: '2nd', child: Text('2nd base')),
                          DropdownMenuItem(value: '3rd', child: Text('3rd base')),
                        ],
                        onChanged: (v) => setSheetState(() => runnerBase = v),
                      ),
                      const SizedBox(height: 10),
                      rosterDropdown(
                        currentValue: pinchRunnerId,
                        onChanged: (v) => setSheetState(() => pinchRunnerId = v),
                        hint: 'Select pinch runner',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (runnerBase == null || pinchRunnerId == null)
                              ? null
                              : () async {
                                  await _withGameUpdate(gameDoc, (gameData) {
                                    final runners = _runnersFrom(gameData);
                                    final tracker = _trackerFrom(gameData);
                                    if (runnerBase == '1st') runners['1st'] = true;
                                    if (runnerBase == '2nd') runners['2nd'] = true;
                                    if (runnerBase == '3rd') runners['3rd'] = true;
                                    return {
                                      'runners': runners,
                                      'metadata': {
                                        'liveTracker': {
                                          ...tracker,
                                          'runnerIds': {
                                            ...(tracker['runnerIds'] as Map<String, dynamic>? ?? {}),
                                            runnerBase!: pinchRunnerId,
                                          }
                                        }
                                      },
                                      'events': FieldValue.arrayUnion([
                                        '${DateTime.now().toIso8601String()}|Pinch runner on $runnerBase: $pinchRunnerId'
                                      ]),
                                    };
                                  });
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: const Text('Confirm pinch runner'),
                        ),
                      ),
                    ],
                    if (tab == 2) ...[
                      DropdownButtonFormField<String>(
                        initialValue: defensePos,
                        decoration: const InputDecoration(
                          labelText: 'Position',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: defensePositions
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) => setSheetState(() => defensePos = v ?? 'P'),
                      ),
                      const SizedBox(height: 10),
                      rosterDropdown(
                        currentValue: defensePlayerId,
                        onChanged: (v) => setSheetState(() => defensePlayerId = v),
                        hint: 'Select defensive player',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: defensePlayerId == null
                              ? null
                              : () async {
                                  await _withGameUpdate(gameDoc, (gameData) {
                                    final tracker = _trackerFrom(gameData);
                                    final defense = Map<String, dynamic>.from(
                                      (tracker['defense'] as Map<String, dynamic>?) ?? {},
                                    );
                                    defense[defensePos] = defensePlayerId;
                                    return {
                                      'metadata': {
                                        'liveTracker': {
                                          ...tracker,
                                          'defense': defense,
                                        }
                                      },
                                      'events': FieldValue.arrayUnion([
                                        '${DateTime.now().toIso8601String()}|Defensive substitution: $defensePos -> $defensePlayerId'
                                      ]),
                                    };
                                  });
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: const Text('Confirm defense sub'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openStolenBaseSheet(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    final gameData = gameDoc.data() ?? <String, dynamic>{};
    final runners = _runnersFrom(gameData);

    final available = <String>[
      if (runners['1st'] == true) '1st',
      if (runners['2nd'] == true) '2nd',
      if (runners['3rd'] == true) '3rd',
    ];
    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No runners on base for stolen base.')),
      );
      return;
    }

    String? selectedBase = available.first;
    bool safe = true;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Record stolen base', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: available
                        .map((b) => ChoiceChip(
                              label: Text('$b base'),
                              selected: selectedBase == b,
                              onSelected: (_) => setState(() => selectedBase = b),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Safe - advances')),
                      ButtonSegment(value: false, label: Text('Caught stealing - out')),
                    ],
                    selected: {safe},
                    onSelectionChanged: (s) => setState(() => safe = s.first),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (selectedBase != null) {
                          await _recordStolenBase(gameDoc: gameDoc, fromBase: selectedBase!, safe: safe);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _openPickoffSheet(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    final gameData = gameDoc.data() ?? <String, dynamic>{};
    final runners = _runnersFrom(gameData);

    final available = <String>[
      if (runners['1st'] == true) '1st',
      if (runners['2nd'] == true) '2nd',
      if (runners['3rd'] == true) '3rd',
    ];
    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No runners on base for pickoff.')),
      );
      return;
    }

    String selectedBase = available.first;
    bool safe = true;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pickoff', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: available
                        .map((b) => ChoiceChip(
                              label: Text('$b base'),
                              selected: selectedBase == b,
                              onSelected: (_) => setState(() => selectedBase = b),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Safe')),
                      ButtonSegment(value: false, label: Text('Out')),
                    ],
                    selected: {safe},
                    onSelectionChanged: (s) => setState(() => safe = s.first),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _recordPickoff(gameDoc: gameDoc, base: selectedBase, safe: safe);
                      },
                      child: const Text('Save'),
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  List<String> _validPlayTypesForFielder(int fielder) {
    if ({1, 3, 4, 5, 6}.contains(fielder)) {
      return ['ground_ball', 'line_drive', 'pop_up'];
    }
    if (fielder == 2) {
      return ['pop_up', 'line_drive', 'foul_tip'];
    }
    return ['fly_ball', 'line_drive'];
  }

  List<String> _outcomeOptions({
    required String playType,
    required Map<String, bool> runners,
    required int outs,
  }) {
    final hasRunners = (runners['1st'] ?? false) || (runners['2nd'] ?? false) || (runners['3rd'] ?? false);
    switch (playType) {
      case 'ground_ball':
        return [
          'out_at_1st',
          'infield_single',
          'single',
          if (hasRunners) 'fielders_choice',
          if (hasRunners) 'double_play',
          'error',
        ];
      case 'fly_ball':
        return [
          'caught_out',
          'dropped_error',
          if (runners['3rd'] == true) 'sac_fly',
          if (hasRunners) 'double_play',
          'inside_park_hr',
        ];
      case 'pop_up':
        return [
          'caught_out',
          'dropped_error',
          if ((runners['1st'] == true) &&
              (runners['2nd'] == true) &&
              outs < 2) 'infield_fly_rule',
        ];
      case 'line_drive':
        return [
          'caught_out',
          'single',
          'double',
          'triple',
          if (hasRunners) 'double_play',
          'error',
        ];
      case 'foul_tip':
        return ['caught_out', 'dropped_error'];
      default:
        return ['caught_out'];
    }
  }

  List<String> _batterDestOptions(String outcome) {
    switch (outcome) {
      case 'out_at_1st':
      case 'caught_out':
      case 'sac_fly':
      case 'double_play':
      case 'infield_fly_rule':
        return ['out'];
      case 'infield_single':
      case 'single':
      case 'fielders_choice':
        return ['1B'];
      case 'double':
        return ['2B'];
      case 'triple':
        return ['3B'];
      case 'inside_park_hr':
        return ['home'];
      case 'error':
      case 'dropped_error':
        return ['1B', '2B'];
      default:
        return ['out'];
    }
  }

  List<String> _runnerOptions({
    required String base,
    required String outcome,
    required String batterDest,
    required Map<String, bool> runners,
  }) {
    final on1 = runners['1st'] ?? false;
    final on2 = runners['2nd'] ?? false;
    if (base == '1st') {
      if (outcome == 'double_play') return ['out'];
      if (outcome == 'fielders_choice') return ['out', '2nd'];
      if (outcome == 'double') return ['3rd', 'home'];
      if (outcome == 'triple' || outcome == 'inside_park_hr') return ['home'];
      if (outcome == 'caught_out' || outcome == 'sac_fly') return ['hold', '2nd', 'out'];
      if (outcome == 'out_at_1st') return ['2nd', 'hold'];
      if (batterDest == '1B') return ['2nd', '3rd', 'hold'];
      return ['2nd', 'hold'];
    }
    if (base == '2nd') {
      if (outcome == 'double' || outcome == 'triple' || outcome == 'inside_park_hr') return ['home'];
      if (outcome == 'caught_out' || outcome == 'sac_fly') return ['hold', '3rd', 'out'];
      if (outcome == 'fielders_choice') return ['hold', '3rd', 'out'];
      if (outcome == 'out_at_1st') {
        if (on1) return ['3rd', 'hold'];
        return ['3rd', 'hold'];
      }
      return ['home', '3rd', 'hold'];
    }
    if (outcome == 'double' || outcome == 'triple' || outcome == 'inside_park_hr') return ['home'];
    if (outcome == 'caught_out' || outcome == 'sac_fly') return ['home', 'hold', 'out'];
    if (outcome == 'out_at_1st' && on1 && on2) return ['home', 'hold'];
    return ['home', 'hold'];
  }

  String _labelForPlayType(String v) {
    switch (v) {
      case 'ground_ball':
        return 'Ground ball';
      case 'line_drive':
        return 'Line drive';
      case 'pop_up':
        return 'Pop up';
      case 'fly_ball':
        return 'Fly ball';
      case 'foul_tip':
        return 'Foul tip';
      default:
        return v;
    }
  }

  String _labelForOutcome(String v) {
    switch (v) {
      case 'out_at_1st':
        return 'Out at 1st';
      case 'infield_single':
        return 'Infield single';
      case 'single':
        return 'Single';
      case 'fielders_choice':
        return "Fielder's choice";
      case 'double_play':
        return 'Double play';
      case 'error':
        return 'Fielder error';
      case 'caught_out':
        return 'Caught - out';
      case 'dropped_error':
        return 'Dropped - error';
      case 'sac_fly':
        return 'Sacrifice fly';
      case 'inside_park_hr':
        return 'Inside-the-park HR';
      case 'double':
        return 'Double';
      case 'triple':
        return 'Triple';
      case 'infield_fly_rule':
        return 'Infield fly rule';
      default:
        return v;
    }
  }

  String _destLabel(String v) {
    switch (v) {
      case 'hold':
        return 'Holds';
      case 'out':
        return 'Out';
      case 'home':
        return 'Scores';
      default:
        return v;
    }
  }

  String _playDescription({
    required int fielder,
    required String playType,
    required String outcome,
    required String batterDest,
    required int rbi,
  }) {
    final type = _labelForPlayType(playType);
    final out = _labelForOutcome(outcome);
    final dest = batterDest == 'out' ? 'Batter out' : 'Batter to $batterDest';
    final rbiText = rbi > 0 ? ' • RBI $rbi' : '';
    return '$type — $out (F$fielder, $dest)$rbiText';
  }

  Future<_InPlaySelection?> _showInPlaySheet({
    required Map<String, bool> runners,
    required int outs,
  }) async {
    return showModalBottomSheet<_InPlaySelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        _InPlayStep step = _InPlayStep.fielder;
        int? fielder;
        String? playType;
        String? outcome;
        String? batterDest;
        final runnerDests = <String, String>{};

        final activeRunnerBases = <String>[
          if (runners['1st'] == true) '1st',
          if (runners['2nd'] == true) '2nd',
          if (runners['3rd'] == true) '3rd',
        ];

        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool canContinue() {
              switch (step) {
                case _InPlayStep.fielder:
                  return fielder != null;
                case _InPlayStep.playType:
                  return playType != null;
                case _InPlayStep.outcome:
                  return outcome != null;
                case _InPlayStep.batterDest:
                  return batterDest != null;
                case _InPlayStep.runners:
                  return activeRunnerBases.every((b) => runnerDests.containsKey(b));
                case _InPlayStep.confirm:
                  return true;
              }
            }

            void advance() {
              if (!canContinue()) return;
              setSheetState(() {
                if (step == _InPlayStep.fielder) {
                  step = _InPlayStep.playType;
                } else if (step == _InPlayStep.playType) {
                  step = _InPlayStep.outcome;
                } else if (step == _InPlayStep.outcome) {
                  final opts = _batterDestOptions(outcome!);
                  if (opts.length == 1) {
                    batterDest = opts.first;
                    step = activeRunnerBases.isEmpty ? _InPlayStep.confirm : _InPlayStep.runners;
                  } else {
                    step = _InPlayStep.batterDest;
                  }
                } else if (step == _InPlayStep.batterDest) {
                  step = activeRunnerBases.isEmpty ? _InPlayStep.confirm : _InPlayStep.runners;
                } else if (step == _InPlayStep.runners) {
                  step = _InPlayStep.confirm;
                }
              });
            }

            void back() {
              setSheetState(() {
                if (step == _InPlayStep.playType) step = _InPlayStep.fielder;
                if (step == _InPlayStep.outcome) step = _InPlayStep.playType;
                if (step == _InPlayStep.batterDest) step = _InPlayStep.outcome;
                if (step == _InPlayStep.runners) {
                  final opts = _batterDestOptions(outcome!);
                  step = opts.length == 1 ? _InPlayStep.outcome : _InPlayStep.batterDest;
                }
                if (step == _InPlayStep.confirm) {
                  step = activeRunnerBases.isEmpty ? _InPlayStep.outcome : _InPlayStep.runners;
                }
              });
            }

            Widget sectionTitle(String t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    t,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                );

            Widget stepBody() {
              if (step == _InPlayStep.fielder) {
                final positions = <int, String>{
                  1: 'P',
                  2: 'C',
                  3: '1B',
                  4: '2B',
                  5: '3B',
                  6: 'SS',
                  7: 'LF',
                  8: 'CF',
                  9: 'RF',
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Step 1: Select fielder'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: positions.entries.map((e) {
                        final selected = fielder == e.key;
                        return ChoiceChip(
                          label: Text('#${e.key} ${e.value}'),
                          selected: selected,
                          onSelected: (_) => setSheetState(() => fielder = e.key),
                        );
                      }).toList(),
                    ),
                  ],
                );
              }
              if (step == _InPlayStep.playType) {
                final opts = _validPlayTypesForFielder(fielder!);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Step 2: Play type'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: opts.map((o) {
                        return ChoiceChip(
                          label: Text(_labelForPlayType(o)),
                          selected: playType == o,
                          onSelected: (_) => setSheetState(() => playType = o),
                        );
                      }).toList(),
                    ),
                  ],
                );
              }
              if (step == _InPlayStep.outcome) {
                final opts = _outcomeOptions(playType: playType!, runners: runners, outs: outs);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Step 3: Outcome'),
                    ...opts.map((o) => RadioListTile<String>(
                          value: o,
                          groupValue: outcome,
                          title: Text(_labelForOutcome(o)),
                          onChanged: (v) => setSheetState(() => outcome = v),
                        )),
                  ],
                );
              }
              if (step == _InPlayStep.batterDest) {
                final opts = _batterDestOptions(outcome!);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Step 4: Batter destination'),
                    Wrap(
                      spacing: 8,
                      children: opts.map((o) {
                        return ChoiceChip(
                          label: Text(o == 'out' ? 'Out' : o),
                          selected: batterDest == o,
                          onSelected: (_) => setSheetState(() => batterDest = o),
                        );
                      }).toList(),
                    ),
                  ],
                );
              }
              if (step == _InPlayStep.runners) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Step 5: Runner advancement'),
                    ...activeRunnerBases.map((base) {
                      final opts = _runnerOptions(
                        base: base,
                        outcome: outcome!,
                        batterDest: batterDest!,
                        runners: runners,
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Runner on $base', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: opts.map((o) {
                                  final selected = runnerDests[base] == o;
                                  return ChoiceChip(
                                    label: Text(_destLabel(o)),
                                    selected: selected,
                                    onSelected: (_) => setSheetState(() => runnerDests[base] = o),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }

              final runsFromRunners = runnerDests.values.where((v) => v == 'home').length;
              final runsFromBatter = batterDest == 'home' ? 1 : 0;
              final rbi = runsFromRunners + runsFromBatter;
              final desc = _playDescription(
                fielder: fielder!,
                playType: playType!,
                outcome: outcome!,
                batterDest: batterDest!,
                rbi: rbi,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle('Step 6: Confirm'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fielder: #$fielder'),
                          Text('Play type: ${_labelForPlayType(playType!)}'),
                          Text('Outcome: ${_labelForOutcome(outcome!)}'),
                          Text('Batter: ${batterDest == 'out' ? 'Out' : batterDest}'),
                          if (runnerDests.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...runnerDests.entries.map((e) => Text('${e.key}: ${_destLabel(e.value)}')),
                          ],
                          const SizedBox(height: 6),
                          Text('RBI: $rbi'),
                          const SizedBox(height: 4),
                          Text(desc, style: GoogleFonts.inter(color: const Color(0xFF374151))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _InPlaySelection(
                          fielder: fielder!,
                          playType: playType!,
                          outcome: outcome!,
                          batterDest: batterDest!,
                          runnerDests: Map<String, String>.from(runnerDests),
                          rbiCount: rbi,
                          description: desc,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4332),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Save play'),
                  ),
                ],
              );
            }

            final stepText = switch (step) {
              _InPlayStep.fielder => 'Fielder',
              _InPlayStep.playType => 'Play type',
              _InPlayStep.outcome => 'Outcome',
              _InPlayStep.batterDest => 'Batter dest',
              _InPlayStep.runners => 'Runners',
              _InPlayStep.confirm => 'Confirm',
            };

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Text('In Play Wizard • $stepText', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: stepBody(),
                    ),
                  ),
                  if (step != _InPlayStep.confirm) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: step == _InPlayStep.fielder ? () => Navigator.pop(context) : back,
                            child: Text(step == _InPlayStep.fielder ? 'Cancel' : 'Back'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canContinue() ? advance : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4332),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _recordInPlay(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    final baseGameData = gameDoc.data() ?? <String, dynamic>{};
    final currentRunners = _runnersFrom(baseGameData);
    final tracker = _trackerFrom(baseGameData);
    final result = await _showInPlaySheet(
      runners: currentRunners,
      outs: tracker['outs'] as int,
    );
    if (result == null) return;

    await _withGameUpdate(gameDoc, (gameData) {
      final tracker = _trackerFrom(gameData);
      final runners = _runnersFrom(gameData);
      final score = _scoreFrom(gameData);
      final isTop = _halfFrom(gameData) == 'top';

      void scoreRun() {
        if (isTop) {
          score['away'] = (score['away'] ?? 0) + 1;
        } else {
          score['home'] = (score['home'] ?? 0) + 1;
        }
      }

      int outs = tracker['outs'] as int;
      int batterIndex = tracker['currentBatterIndex'] as int;

      void setRunnerBase(String base, bool value) {
        runners[base] = value;
      }

      // Clear existing runners and re-apply from explicit runner destinations.
      final originalRunners = Map<String, bool>.from(runners);
      setRunnerBase('1st', false);
      setRunnerBase('2nd', false);
      setRunnerBase('3rd', false);

      for (final entry in result.runnerDests.entries) {
        final dest = entry.value;
        if (dest == 'home') {
          scoreRun();
        } else if (dest == 'out') {
          outs += 1;
        } else if (dest == '2nd') {
          setRunnerBase('2nd', true);
        } else if (dest == '3rd') {
          setRunnerBase('3rd', true);
        } else if (dest == 'hold') {
          setRunnerBase(entry.key, true);
        }
      }

      if (result.batterDest == 'out') {
        outs += 1;
      } else if (result.batterDest == '1B') {
        setRunnerBase('1st', true);
      } else if (result.batterDest == '2B') {
        setRunnerBase('2nd', true);
      } else if (result.batterDest == '3B') {
        setRunnerBase('3rd', true);
      } else if (result.batterDest == 'home') {
        scoreRun();
      }

      if (result.outcome == 'double_play') {
        // Ensure two outs minimum on a DP.
        outs += 1;
      }
      if (result.outcome == 'fielders_choice' && originalRunners.values.any((v) => v)) {
        // FC usually records at least one out on a runner.
        if (!result.runnerDests.values.contains('out')) {
          outs += 1;
        }
      }

      batterIndex += 1;

      if (outs >= 3) {
        return _endHalfInningPatch(gameData, tracker);
      }

      return {
        'outs': outs,
        'runners': runners,
        'score': score,
        'events': FieldValue.arrayUnion([
          '${DateTime.now().toIso8601String()}|${result.description}'
        ]),
        'metadata': {
          'liveTracker': {
            ...tracker,
            'balls': 0,
            'strikes': 0,
            'outs': outs,
            'currentBatterIndex': batterIndex,
            'currentAtBatPitches': <String>[],
          }
        }
      };
    });
  }

  Future<void> _undoPitch(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final tracker = _trackerFrom(gameData);
      final pitches = List<String>.from(tracker['currentAtBatPitches'] as List<String>);
      if (pitches.isEmpty) return {};

      final last = pitches.removeLast();
      int balls = tracker['balls'] as int;
      int strikes = tracker['strikes'] as int;

      if (last == 'B' && balls > 0) balls -= 1;
      if (last == 'K' && strikes > 0) strikes -= 1;
      if (last == 'F' && strikes > 0 && strikes < 2) strikes -= 1;

      return {
        'metadata': {
          'liveTracker': {
            ...tracker,
            'balls': balls,
            'strikes': strikes,
            'currentAtBatPitches': pitches,
          }
        }
      };
    });
  }

  Future<void> _nextBatter(DocumentSnapshot<Map<String, dynamic>> gameDoc) async {
    await _withGameUpdate(gameDoc, (gameData) {
      final tracker = _trackerFrom(gameData);
      return {
        'metadata': {
          'liveTracker': {
            ...tracker,
            'balls': 0,
            'strikes': 0,
            'currentBatterIndex': (tracker['currentBatterIndex'] as int) + 1,
            'currentAtBatPitches': <String>[],
          }
        }
      };
    });
  }

  Widget _countDots({
    required String label,
    required int count,
    required int max,
    required Color activeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            letterSpacing: 0.6,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(max, (i) {
            final filled = i < count;
            return Container(
              margin: const EdgeInsets.only(right: 6),
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? activeColor : Colors.white,
                border: Border.all(
                  color: filled ? activeColor : const Color(0xFFBBBBBB),
                  width: 1.5,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _baseDiamond(Map<String, bool> runners) {
    Widget base(bool occupied) {
      return Transform.rotate(
        angle: 0.785398,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: occupied ? const Color(0xFFF59E0B) : Colors.transparent,
            border: Border.all(color: const Color(0xFFBBBBBB), width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        children: [
          Positioned(top: 2, left: 29, child: base(runners['2nd'] ?? false)),
          Positioned(top: 29, right: 2, child: base(runners['1st'] ?? false)),
          Positioned(top: 29, left: 2, child: base(runners['3rd'] ?? false)),
          Positioned(
            top: 31,
            left: 31,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF5A9A5A),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pitchChip(String code) {
    Color bg;
    Color fg;
    String label;
    switch (code) {
      case 'B':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        label = 'B';
        break;
      case 'K':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFF991B1B);
        label = 'K';
        break;
      case 'F':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFF92400E);
        label = 'F';
        break;
      case 'IP':
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF166534);
        label = 'IP';
        break;
      default:
        bg = const Color(0xFFF5F3FF);
        fg = const Color(0xFF5B21B6);
        label = 'HBP';
    }
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _pitchButton({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF374151)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: GoogleFonts.inter(fontSize: 15, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_teamId == null) {
      return const Center(child: Text('No team selected.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('games')
          .where('teamHome', isEqualTo: _teamId)
          .orderBy('date', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, listSnap) {
        final docs = listSnap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No games found for this team yet.',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GameSetupScreen()),
                      );
                    },
                    child: const Text('Create Game'),
                  ),
                ],
              ),
            ),
          );
        }

        _selectedGameId ??= docs.first.id;
        final selected = docs.firstWhere(
          (d) => d.id == _selectedGameId,
          orElse: () => docs.first,
        );

        final gameData = selected.data();
        final score = _scoreFrom(gameData);
        final runners = _runnersFrom(gameData);
        final tracker = _trackerFrom(gameData);
        final state = (gameData['state'] as String?) ?? 'scheduled';
        final inning = _inningFrom(gameData);
        final half = _halfFrom(gameData);
        final isLive = state == 'inProgress';
        final pitches = List<String>.from(tracker['currentAtBatPitches'] as List<String>);
        final batterIndex = (tracker['currentBatterIndex'] as int) + 1;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B4332),
            foregroundColor: Colors.white,
            title: Text('Live Game', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            actions: [
              IconButton(
                tooltip: 'Create game',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GameSetupScreen()),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFF1B4332),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isLive ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLive ? 'LIVE' : 'NOT LIVE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isLive ? const Color(0xFFDC2626) : const Color(0xFFD1D5DB),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${score['away'] ?? 0} - ${score['home'] ?? 0}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C472C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${half == 'top' ? '▲' : '▼'} $inning',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF9FC09F),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F8F4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _baseDiamond(runners),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _countDots(
                              label: 'BALLS',
                              count: tracker['balls'] as int,
                              max: 3,
                              activeColor: const Color(0xFF1D4ED8),
                            ),
                            _countDots(
                              label: 'STRIKES',
                              count: tracker['strikes'] as int,
                              max: 2,
                              activeColor: const Color(0xFFDC2626),
                            ),
                            _countDots(
                              label: 'OUTS',
                              count: tracker['outs'] as int,
                              max: 2,
                              activeColor: const Color(0xFF1B4332),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 52,
                  color: const Color(0xFFF3F4F6),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFF1B4332),
                        child: Text(
                          'B',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Current Batter #$batterIndex',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      Text(
                        'AB',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 40,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'At-bat',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6B7280)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: pitches.length,
                          itemBuilder: (_, i) => _pitchChip(pitches[i]),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _pitchButton(
                              title: 'Ball',
                              subtitle: 'Outside zone',
                              color: const Color(0xFF1D4ED8),
                              onTap: isLive ? () => _recordBall(selected) : () {},
                              onLongPress: isLive ? () => _recordIntentionalWalk(selected) : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _pitchButton(
                              title: 'Strike',
                              subtitle: 'Called / swinging',
                              color: const Color(0xFFDC2626),
                              onTap: isLive ? () => _recordStrike(selected) : () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _pitchButton(
                              title: 'Foul',
                              subtitle: 'Foul ball',
                              color: const Color(0xFFF59E0B),
                              onTap: isLive ? () => _recordFoul(selected) : () {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _pitchButton(
                              title: 'In Play',
                              subtitle: 'Record outcome',
                              color: const Color(0xFF16A34A),
                              onTap: isLive ? () => _recordInPlay(selected) : () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isLive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _smallAction(
                            icon: Icons.directions_run,
                            label: 'Stolen Base',
                            onTap: () => _openStolenBaseSheet(selected),
                          ),
                          _smallAction(
                            icon: Icons.air,
                            label: 'Wild Pitch',
                            onTap: () => _recordWildPitch(selected),
                          ),
                          _smallAction(
                            icon: Icons.pan_tool_alt,
                            label: 'Passed Ball',
                            onTap: () => _recordPassedBall(selected),
                          ),
                          _smallAction(
                            icon: Icons.warning_amber_rounded,
                            label: 'Balk',
                            onTap: () => _recordBalk(selected),
                          ),
                          _smallAction(
                            icon: Icons.keyboard_double_arrow_left,
                            label: 'Pickoff',
                            onTap: () => _openPickoffSheet(selected),
                          ),
                          _smallAction(
                            icon: Icons.swap_horiz,
                            label: 'Sub / Notes',
                            onTap: () => _openSubstitutionSheet(selected),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLive ? () => _undoPitch(selected) : null,
                          child: const Text('Undo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLive ? () => _recordHbp(selected) : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5B21B6),
                          ),
                          child: const Text('HBP'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isLive ? () => _nextBatter(selected) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4332),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Next Batter'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedGameId,
                          decoration: const InputDecoration(
                            labelText: 'Game',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: docs.map((doc) {
                            final data = doc.data();
                            final opp = (data['teamAway'] as String?) ?? 'Opponent';
                            final dt = (data['date'] as Timestamp?)?.toDate();
                            final subtitle = dt == null
                                ? opp
                                : '$opp • ${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                subtitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedGameId = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: isLive ? null : () => _startGame(selected),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
