/// Maps display stat names to internal camelCase keys used in PlayerStats and data structures
final Map<String, String> statKeyMap = {
  // Calculated batting stats
  'Batting Average': 'battingAverage',
  'On-Base Percentage': 'onBasePercentage',
  'Slugging Percentage': 'sluggingPercentage',
  'On-Base Plus Slugging': 'onBasePlusSlugging',
  'Isolated Power': 'isolatedPower',
  'Runs Created': 'runsCreated',
  'Hard-Hit Rate': 'hardHitRate',
  'Quality At-Bat Rate': 'qualityAtBatRate',
  
  // Pitching stats
  'Earned Run Average': 'earnedRunAverage',
  'ERA': 'earnedRunAverage',
  'Strikeout Rate': 'strikeoutRate',
  'Walks + Hits per Inning Pitched': 'walksHitsPerInningPitched',
  'WAR': 'war',
  
  // Raw batting stats
  'At Bats': 'atBats',
  'Runs': 'runs',
  'Hits': 'hits',
  'Doubles': 'doubles',
  'Triples': 'triples',
  'Home Runs': 'homeRuns',
  'Walks': 'walks',
  'Intentional Walks': 'intentionalWalks',
  'Hit By Pitch': 'hitByPitch',
  'Sacrifice Hits': 'sacrificeHits',
  'Sacrifice Bunts': 'sacrificeHits',
  'Sacrifice Flies': 'sacrificeFlies',
  'Stolen Bases': 'stolenBases',
  'Runs Batted In': 'runsBattedIn',
  'Two Strike Counts': 'twoStrikeCounts',
  'Two Strike Success Rate': 'twoStrikeSuccessRate',
  'Hard-Hit Balls': 'hardHitBalls',
  'Quality At-Bats': 'qualityAtBats',
  'Strikeouts': 'strikeouts',
  'Pitches Thrown': 'pitchesThrown',
  
  // Pitching raw stats
  'Innings Pitched': 'inningsPitched',
  'Earned Runs': 'earnedRuns',
};

/// Maps display stat names to normalized names for axis scaling
final Map<String, String> statNameForAxis = {
  'Batting Average': 'Batting Average',
  'On-Base Percentage': 'On-Base Percentage',
  'Slugging Percentage': 'Slugging Percentage',
  'On-Base Plus Slugging': 'On-Base Plus Slugging',
  'Isolated Power': 'Isolated Power',
  'Runs Created': 'Runs Created',
  'Earned Run Average': 'Earned Run Average',
  'ERA': 'Earned Run Average',
  'Strikeout Rate': 'Strikeout Rate',
  'Walks + Hits per Inning Pitched': 'Walks + Hits per Inning Pitched',
  'Two Strike Success Rate': 'Two Strike Success Rate',
  'Hard-Hit Rate': 'Hard-Hit Rate',
  'Quality At-Bat Rate': 'Quality At-Bat Rate',
  // All other stats use smart scaling
};

/// Stats players log only when they track them. Games without a value are
/// left out of charts and rates instead of counting as 0.
const Set<String> optionalStatKeys = {
  'hardHitBalls',
  'hardHitRate',
  'qualityAtBats',
  'qualityAtBatRate',
};

const Set<String> _threeDecimalKeys = {
  'battingAverage',
  'onBasePercentage',
  'sluggingPercentage',
  'onBasePlusSlugging',
  'isolatedPower',
  'runsCreated',
  'earnedRunAverage',
  'strikeoutRate',
  'walksHitsPerInningPitched',
  'twoStrikeSuccessRate',
};

const Set<String> _percentKeys = {'hardHitRate', 'qualityAtBatRate'};

/// Rate stats whose season value is computed from season totals rather than
/// taken from the last game.
bool isRateStat(String displayName) {
  final key = getStatKey(displayName) ?? displayName;
  return _threeDecimalKeys.contains(key) || _percentKeys.contains(key);
}

/// Display formatting shared by stat cards, charts, and game logs.
String formatStatValue(String displayName, double value) {
  final key = getStatKey(displayName) ?? displayName;
  if (_percentKeys.contains(key)) return '${(value * 100).round()}%';
  if (_threeDecimalKeys.contains(key)) return value.toStringAsFixed(3);
  if (key == 'inningsPitched' || key == 'war') return value.toStringAsFixed(1);
  return value.toStringAsFixed(0);
}

/// Gets the internal camelCase key for a display stat name
String? getStatKey(String displayName) {
  // Primary path: display labels used throughout UI ("At Bats", "Hits", etc.).
  final mapped = statKeyMap[displayName];
  if (mapped != null) return mapped;

  // Fallback: caller already passed the internal camelCase key.
  // This makes chart/data helpers robust across both formats.
  if (statKeyMap.values.contains(displayName)) return displayName;

  return null;
}

/// Gets the normalized stat name for axis scaling
String getStatNameForAxis(String displayName) {
  return statNameForAxis[displayName] ?? displayName;
}
