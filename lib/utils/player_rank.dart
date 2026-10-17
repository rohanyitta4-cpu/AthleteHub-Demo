import 'dart:math' as math;

import 'package:flutter/material.dart';

/// AthleteHub performance tiers from the Scout score (not recruiting/scouting).
class RankTier {
  final String name;

  final int min;

  final int max;

  final Color deep;
  final Color bright;
  final List<String> phrases;

  const RankTier({
    required this.name,
    required this.min,
    required this.max,
    required this.deep,
    required this.bright,
    required this.phrases,
  });

  bool contains(int score) => score >= min && score <= max;
}

const rankTiers = <RankTier>[
  RankTier(
    name: 'Kicking Rocks',
    min: 0,
    max: 19,
    deep: Color(0xFF475569),
    bright: Color(0xFF94A3B8),
    phrases: [
      'Hit the cages.',
      'Everybody starts somewhere.',
      'Time to put in work.',
      'The grind starts now.',
      'Back to the basics.',
      'Your comeback starts here.',
    ],
  ),
  RankTier(
    name: 'Benchwarmer',
    min: 20,
    max: 39,
    deep: Color(0xFF9A3412),
    bright: Color(0xFFF59E0B),
    phrases: [
      'Starting to get somewhere.',
      'Make every rep count.',
      'Earn your spot.',
      "The lineup isn't out of reach.",
      'Keep showing up.',
      'Time to turn some heads.',
    ],
  ),
  RankTier(
    name: 'Average Joe',
    min: 40,
    max: 59,
    deep: Color(0xFF0F766E),
    bright: Color(0xFF2DD4BF),
    phrases: [
      'Developing consistent production.',
      'Not bad. Not great. Yet.',
      'Time to separate yourself.',
      'Consistency is everything.',
      "There's another gear in you.",
      'Make average your starting point.',
    ],
  ),
  RankTier(
    name: 'On the Radar',
    min: 60,
    max: 79,
    deep: Color(0xFF1D4ED8),
    bright: Color(0xFF60A5FA),
    phrases: [
      'Strong performance profile.',
      'People are starting to notice.',
      "You're making some noise.",
      'Keep climbing the ranks.',
      "Don't let up now.",
      'Make them remember your name.',
    ],
  ),
  RankTier(
    name: 'Elite Threat',
    min: 80,
    max: 94,
    deep: Color(0xFF2563EB),
    bright: Color(0xFFA486E7),
    phrases: [
      'High-level production.',
      'A problem for opposing pitchers.',
      'Built different. Prove it daily.',
      "You're not an easy out.",
      'The numbers speak for themselves.',
      'Dangerous every time up.',
    ],
  ),
  RankTier(
    name: 'Generational Athlete',
    min: 95,
    max: 100,
    deep: Color(0xFFB45309),
    bright: Color(0xFFFDE68A),
    phrases: [
      'Exceptional performance.',
      'A different level of talent.',
      'The diamond is yours.',
      'Setting the standard.',
      'This is what elite looks like.',
      'One of a kind. Keep proving it.',
    ],
  ),
];

RankTier rankFor(int score) {
  final s = score.clamp(0, 100);
  return rankTiers.firstWhere((t) => t.contains(s));
}

RankTier? nextRank(RankTier tier) {
  final i = rankTiers.indexOf(tier);
  return i < rankTiers.length - 1 ? rankTiers[i + 1] : null;
}

/// 0–1 fill through the current tier toward the next rank (or through the top tier).
double progressTowardNextRank(num score, RankTier tier) {
  final next = nextRank(tier);
  final end = next?.min ?? tier.max;
  final span = end - tier.min;
  if (span <= 0) return 1;
  return ((score - tier.min) / span).clamp(0.0, 1.0);
}

/// Phrase for [tier] that differs from [previous] when possible.
String pickPhrase(RankTier tier, {String? previous, math.Random? random}) {
  final rng = random ?? math.Random();
  final options = tier.phrases.where((p) => p != previous).toList();
  return options[rng.nextInt(options.length)];
}
