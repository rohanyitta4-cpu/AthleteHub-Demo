import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlayerProfile {
  final String id;
  final String userId;
  String? profilePictureUrl;
  String? avatarId;
  String? displayName;
  int? jerseyNumber;
  String? teamName;
  String? primaryPosition;
  String? secondaryPosition;
  List<String> primaryPositions;
  List<String> secondaryPositions;
  String? batHand;
  String? battingHand;
  String? throwHand;
  String? throwingHand;
  String? favoriteMLBTeam;
  String? favoriteMLBPlayer;
  String? profileBannerUrl;
  Color? profileBannerColor;
  String? motivationalQuote;
  String? bio;
  List<AchievementBadge> achievementBadges;
  DateTime createdAt;
  DateTime updatedAt;

  PlayerProfile({
    required this.id,
    required this.userId,
    this.profilePictureUrl,
    this.avatarId,
    this.displayName,
    this.jerseyNumber,
    this.teamName,
    this.primaryPosition,
    this.secondaryPosition,
    this.primaryPositions = const [],
    this.secondaryPositions = const [],
    this.batHand,
    this.battingHand,
    this.throwHand,
    this.throwingHand,
    this.favoriteMLBTeam,
    this.favoriteMLBPlayer,
    this.profileBannerUrl,
    this.profileBannerColor,
    this.motivationalQuote,
    this.bio,
    this.achievementBadges = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlayerProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PlayerProfile(
      id: doc.id,
      userId: data['userId'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
      avatarId: data['avatarId'],
      displayName: data['displayName'],
      jerseyNumber: data['jerseyNumber'],
      teamName: data['teamName'],
      primaryPosition: data['primaryPosition'],
      secondaryPosition: data['secondaryPosition'],
      primaryPositions: (data['primaryPositions'] as List<dynamic>?)?.cast<String>() ?? [],
      secondaryPositions: (data['secondaryPositions'] as List<dynamic>?)?.cast<String>() ?? [],
      batHand: data['batHand'],
      battingHand: data['battingHand'],
      throwHand: data['throwHand'],
      throwingHand: data['throwingHand'],
      favoriteMLBTeam: data['favoriteMLBTeam'],
      favoriteMLBPlayer: data['favoriteMLBPlayer'],
      profileBannerUrl: data['profileBannerUrl'],
      profileBannerColor: data['profileBannerColor'] != null
          ? Color(data['profileBannerColor'])
          : null,
      motivationalQuote: data['motivationalQuote'],
      bio: data['bio'],
      achievementBadges: (data['achievementBadges'] as List<dynamic>?)
              ?.map((badgeData) => AchievementBadge.fromMap(badgeData))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      profilePictureUrl: json['profilePictureUrl'],
      avatarId: json['avatarId'],
      displayName: json['displayName'],
      jerseyNumber: json['jerseyNumber'],
      teamName: json['teamName'],
      primaryPosition: json['primaryPosition'],
      secondaryPosition: json['secondaryPosition'],
      primaryPositions: (json['primaryPositions'] as List<dynamic>?)?.cast<String>() ?? [],
      secondaryPositions: (json['secondaryPositions'] as List<dynamic>?)?.cast<String>() ?? [],
      batHand: json['batHand'],
      battingHand: json['battingHand'],
      throwHand: json['throwHand'],
      throwingHand: json['throwingHand'],
      favoriteMLBTeam: json['favoriteMLBTeam'],
      favoriteMLBPlayer: json['favoriteMLBPlayer'],
      profileBannerUrl: json['profileBannerUrl'],
      profileBannerColor: json['profileBannerColor'] != null
          ? Color(json['profileBannerColor'])
          : null,
      motivationalQuote: json['motivationalQuote'],
      bio: json['bio'],
      achievementBadges: (json['achievementBadges'] as List<dynamic>?)
              ?.map((badgeData) => AchievementBadge.fromMap(badgeData))
              .toList() ??
          [],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'profilePictureUrl': profilePictureUrl,
      'displayName': displayName,
      'jerseyNumber': jerseyNumber,
      'teamName': teamName,
      'primaryPosition': primaryPosition,
      'secondaryPosition': secondaryPosition,
      'batHand': batHand,
      'throwHand': throwHand,
      'favoriteMLBTeam': favoriteMLBTeam,
      'favoriteMLBPlayer': favoriteMLBPlayer,
      'profileBannerUrl': profileBannerUrl,
      'profileBannerColor': profileBannerColor?.value,
      'motivationalQuote': motivationalQuote,
      'bio': bio,
      'achievementBadges':
          achievementBadges.map((badge) => badge.toMap()).toList(),
    };
  }

  PlayerProfile copyWith({
    String? profilePictureUrl,
    String? displayName,
    int? jerseyNumber,
    String? teamName,
    String? primaryPosition,
    String? secondaryPosition,
    String? batHand,
    String? throwHand,
    String? favoriteMLBTeam,
    String? favoriteMLBPlayer,
    String? profileBannerUrl,
    Color? profileBannerColor,
    String? motivationalQuote,
    String? bio,
    List<AchievementBadge>? achievementBadges,
  }) {
    return PlayerProfile(
      id: id,
      userId: userId,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      displayName: displayName ?? this.displayName,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      teamName: teamName ?? this.teamName,
      primaryPosition: primaryPosition ?? this.primaryPosition,
      secondaryPosition: secondaryPosition ?? this.secondaryPosition,
      batHand: batHand ?? this.batHand,
      throwHand: throwHand ?? this.throwHand,
      favoriteMLBTeam: favoriteMLBTeam ?? this.favoriteMLBTeam,
      favoriteMLBPlayer: favoriteMLBPlayer ?? this.favoriteMLBPlayer,
      profileBannerUrl: profileBannerUrl ?? this.profileBannerUrl,
      profileBannerColor: profileBannerColor ?? this.profileBannerColor,
      motivationalQuote: motivationalQuote ?? this.motivationalQuote,
      bio: bio ?? this.bio,
      achievementBadges: achievementBadges ?? this.achievementBadges,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime earnedDate;

  AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedDate,
  });

  factory AchievementBadge.fromMap(Map<String, dynamic> data) {
    return AchievementBadge(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      earnedDate: (data['earnedDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'earnedDate': Timestamp.fromDate(earnedDate),
    };
  }
}

class BaseballPositions {
  static const List<String> positions = [
    'Pitcher',
    'Catcher',
    'First Baseman',
    'Second Baseman',
    'Third Baseman',
    'Shortstop',
    'Left Fielder',
    'Center Fielder',
    'Right Fielder',
    'Designated Hitter',
  ];
}
