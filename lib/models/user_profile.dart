class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? profilePictureUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> preferences;
  final List<String> favoriteStats;
  final String? teamId;
  final String role; // 'athlete' or 'coach'
  
  // Player Identity Fields
  final String? jerseyNumber;
  final String? teamName;
  final List<String> positions; // primary and secondary positions
  final String? batHand; // 'left' or 'right'
  final String? throwHand; // 'left' or 'right'
  final String? favoriteMLBTeam;
  final String? favoriteMLBPlayer;
  final String? customBannerUrl;
  final String? customBackgroundColor;
  final String? motivationalQuote;
  final List<String> achievementBadges;
  final String? selectedAvatar; // for baseball-themed avatars

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.profilePictureUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.preferences = const {},
    this.favoriteStats = const [],
    this.teamId,
    this.role = 'athlete',
    this.jerseyNumber,
    this.teamName,
    this.positions = const [],
    this.batHand,
    this.throwHand,
    this.favoriteMLBTeam,
    this.favoriteMLBPlayer,
    this.customBannerUrl,
    this.customBackgroundColor,
    this.motivationalQuote,
    this.achievementBadges = const [],
    this.selectedAvatar,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      bio: map['bio'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      favoriteStats: List<String>.from(map['favoriteStats'] ?? []),
      teamId: map['teamId'],
      role: map['role'] ?? 'athlete',
      jerseyNumber: map['jerseyNumber'],
      teamName: map['teamName'],
      positions: List<String>.from(map['positions'] ?? []),
      batHand: map['batHand'],
      throwHand: map['throwHand'],
      favoriteMLBTeam: map['favoriteMLBTeam'],
      favoriteMLBPlayer: map['favoriteMLBPlayer'],
      customBannerUrl: map['customBannerUrl'],
      customBackgroundColor: map['customBackgroundColor'],
      motivationalQuote: map['motivationalQuote'],
      achievementBadges: List<String>.from(map['achievementBadges'] ?? []),
      selectedAvatar: map['selectedAvatar'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'profilePictureUrl': profilePictureUrl,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences,
      'favoriteStats': favoriteStats,
      'teamId': teamId,
      'role': role,
      'jerseyNumber': jerseyNumber,
      'teamName': teamName,
      'positions': positions,
      'batHand': batHand,
      'throwHand': throwHand,
      'favoriteMLBTeam': favoriteMLBTeam,
      'favoriteMLBPlayer': favoriteMLBPlayer,
      'customBannerUrl': customBannerUrl,
      'customBackgroundColor': customBackgroundColor,
      'motivationalQuote': motivationalQuote,
      'achievementBadges': achievementBadges,
      'selectedAvatar': selectedAvatar,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? profilePictureUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    List<String>? favoriteStats,
    String? teamId,
    String? role,
    String? jerseyNumber,
    String? teamName,
    List<String>? positions,
    String? batHand,
    String? throwHand,
    String? favoriteMLBTeam,
    String? favoriteMLBPlayer,
    String? customBannerUrl,
    String? customBackgroundColor,
    String? motivationalQuote,
    List<String>? achievementBadges,
    String? selectedAvatar,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      favoriteStats: favoriteStats ?? this.favoriteStats,
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      teamName: teamName ?? this.teamName,
      positions: positions ?? this.positions,
      batHand: batHand ?? this.batHand,
      throwHand: throwHand ?? this.throwHand,
      favoriteMLBTeam: favoriteMLBTeam ?? this.favoriteMLBTeam,
      favoriteMLBPlayer: favoriteMLBPlayer ?? this.favoriteMLBPlayer,
      customBannerUrl: customBannerUrl ?? this.customBannerUrl,
      customBackgroundColor: customBackgroundColor ?? this.customBackgroundColor,
      motivationalQuote: motivationalQuote ?? this.motivationalQuote,
      achievementBadges: achievementBadges ?? this.achievementBadges,
      selectedAvatar: selectedAvatar ?? this.selectedAvatar,
    );
  }
}