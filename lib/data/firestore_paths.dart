class FP {
  // Users
  static String users() => 'users';
  static String user(String uid) => 'users/$uid';

  // Teams
  static String teams() => 'teams';
  static String team(String teamId) => '${teams()}/$teamId';
  static String teamRoster(String teamId) => '${team(teamId)}/roster';
  static String teamRosterPlayer(String teamId, String playerId) => '${teamRoster(teamId)}/$playerId';
  
  // Team seasons
  static String teamSeasons(String teamId) => '${team(teamId)}/seasons';
  static String teamSeason(String teamId, String seasonId) => '${teamSeasons(teamId)}/$seasonId';
  
  // Team games
  static String teamGames(String teamId, String seasonId) => '${teamSeason(teamId, seasonId)}/games';
  static String teamGame(String teamId, String seasonId, String gameId) => '${teamGames(teamId, seasonId)}/$gameId';
  
  // Team season stats
  static String teamSeasonStats(String teamId, String seasonId) => '${teamSeason(teamId, seasonId)}/stats';
  static String teamSeasonPlayerStats(String teamId, String seasonId, String playerId) => '${teamSeasonStats(teamId, seasonId)}/players/$playerId';
  static String teamSeasonTotals(String teamId, String seasonId) => '${teamSeasonStats(teamId, seasonId)}/totals';
  
  // Analytics
  static String analytics(String teamId, String seasonId) => 'analytics/$teamId/$seasonId';

  // User preferences (still under users)
  static String preferences(String uid) => '${user(uid)}/preferences';
  static String dashboardPrefs(String uid) => '${preferences(uid)}/dashboard';
  static String userTeams(String uid) => '${user(uid)}/teams';
}