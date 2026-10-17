import 'package:shared_preferences/shared_preferences.dart';

class DashPrefs {
  static const _kTop3 = 'dash.top3';

  static const defaultTop3 = ['atBats', 'hits'];
  static const defaultTypes = {
    'dash.chartType.battingAverages': 'line',
    'dash.chartType.onBasePercentage': 'line',
    'dash.chartType.sluggingPercentages': 'line',
    'dash.chartType.onBasePlusSlugging': 'area',
    'dash.chartType.isolatedPower': 'line',
    'dash.chartType.runsCreated': 'bar',
    'dash.chartType.earnedRunAverage': 'line',
    'dash.chartType.strikeoutRate': 'line',
    'dash.chartType.walksHitsPerInning': 'line',
    'dash.chartType.atBats': 'bar',
    'dash.chartType.hits': 'line',
    'dash.chartType.runs': 'bar',
    'dash.chartType.doubles': 'line',
    'dash.chartType.triples': 'bar',
    'dash.chartType.homeRuns': 'line',
    'dash.chartType.walks': 'bar',
    'dash.chartType.hitByPitch': 'line',
    'dash.chartType.strikeouts': 'bar',
    'dash.chartType.sacrificeHits': 'line',
    'dash.chartType.stolenBases': 'bar',
    'dash.chartType.runsBattedIn': 'line',
    'dash.chartType.twoStrikeCounts': 'bar',
    'dash.chartType.successWithTwoStrikes': 'line',
    'dash.chartType.inningsPitched': 'bar',
    'dash.chartType.earnedRuns': 'line',
    'dash.chartType.totalPitches': 'bar',
    'dash.chartType.warList': 'line',
    'dash.chartType.eraList': 'line',
    'dash.chartType.strikeoutsList': 'bar',
    'dash.chartType.pitchesList': 'line',
    'dash.chartType.battingAveragesMonthly': 'area',
    'dash.chartType.eraListMonthly': 'line',
    'dash.chartType.atBatsList': 'bar',
    'dash.chartType.runsList': 'line',
    'dash.chartType.hitsList': 'bar',
    'dash.chartType.doublesList': 'line',
    'dash.chartType.triplesList': 'bar',
    'dash.chartType.homeRunsList': 'line',
    'dash.chartType.walksList': 'bar',
    'dash.chartType.hitByPitchList': 'line',
    'dash.chartType.sacrificeHitsList': 'bar',
    'dash.chartType.stolenBasesList': 'line',
    'dash.chartType.runsBattedInList': 'bar',
    'dash.chartType.twoStrikeCountsList': 'line',
    'dash.chartType.successWithTwoStrikesList': 'bar',
    'dash.chartType.inningsPitchedList': 'line',
    'dash.chartType.earnedRunsList': 'bar',
  };

  Future<List<String>> loadTop3() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_kTop3) ?? defaultTop3;
  }

  Future<void> saveTop3(List<String> keys) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kTop3, keys.take(3).toList());
  }

  Future<String> loadType(String key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(key) ?? defaultTypes[key] ?? 'line';
  }

  Future<void> saveType(String key, String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, v);
  }

  Future<Map<String, String>> loadAllChartTypes() async {
    return {
      'dash.chartType.atBats': await loadType('dash.chartType.atBats'),
      'dash.chartType.hits': await loadType('dash.chartType.hits'),
      'dash.chartType.battingAverages': await loadType('dash.chartType.battingAverages'),
    };
  }

  Future<void> saveAllChartTypes(Map<String, String> types) async {
    for (final entry in types.entries) {
      await saveType(entry.key, entry.value);
    }
  }
  
  // Convenience methods for loading and saving all preferences at once
  static Future<DashPrefsData> load() async {
    final instance = DashPrefs();
    final top3 = await instance.loadTop3();
    final chartTypes = await instance.loadAllChartTypes();
    return DashPrefsData(top3: top3, chartTypes: chartTypes);
  }
  
  static Future<void> save(List<String> top3, Map<String, String> chartTypes) async {
    final instance = DashPrefs();
    await instance.saveTop3(top3);
    await instance.saveAllChartTypes(chartTypes);
  }
}

class DashPrefsData {
  final List<String> top3;
  final Map<String, String> chartTypes;
  
  DashPrefsData({
    required this.top3,
    required this.chartTypes,
  });
} 