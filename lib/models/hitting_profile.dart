/// Hitting profile used by Scout to weight the scouting-report categories.
///
/// The profile changes how much each category counts toward the grade, never
/// the category scores themselves.
enum HittingProfile {
  power(
    id: 'power',
    label: 'Power Hitter',
    tagline: 'Power-focused',
    description: 'Rewards driving the ball and producing extra-base hits.',
    primaryStats: 'SLG, ISO and extra-base hits per at-bat, with contact and strikeouts as support.',
    weights: {
      'contact': 15,
      'power': 35,
      'discipline': 15,
      'momentum': 10,
      'twoStrike': 10,
      'consistency': 15,
    },
  ),
  contact(
    id: 'contact',
    label: 'Contact Hitter',
    tagline: 'Contact-focused',
    description: 'Rewards putting the ball in play and getting on base consistently.',
    primaryStats: 'AVG, strikeout rate, two-strike hitting and consistency.',
    weights: {
      'contact': 35,
      'power': 10,
      'discipline': 15,
      'momentum': 10,
      'twoStrike': 15,
      'consistency': 15,
    },
  ),
  onBase(
    id: 'onBase',
    label: 'On-Base Hitter',
    tagline: 'Plate-discipline-focused',
    description: 'Rewards controlling the strike zone, reaching base and making pitchers work.',
    primaryStats: 'OBP, walk rate, strikeout rate and two-strike hitting.',
    weights: {
      'contact': 15,
      'power': 5,
      'discipline': 35,
      'momentum': 10,
      'twoStrike': 20,
      'consistency': 15,
    },
  );

  const HittingProfile({
    required this.id,
    required this.label,
    required this.tagline,
    required this.description,
    required this.primaryStats,
    required this.weights,
  });

  final String id;
  final String label;
  final String tagline;
  final String description;
  final String primaryStats;

  /// Must match PROFILES in functions/src/scoring.ts, which owns the real grading.
  final Map<String, int> weights;

  static HittingProfile? fromId(String? id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }

  static const categoryLabels = {
    'contact': 'Contact',
    'power': 'Power',
    'discipline': 'Plate discipline',
    'twoStrike': 'Two-strike hitting',
    'consistency': 'Consistency',
    'momentum': 'Momentum',
  };
}
