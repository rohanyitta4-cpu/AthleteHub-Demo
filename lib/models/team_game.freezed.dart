// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_game.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerGameStats {

 int get atBats; int get runs; int get hits; int get doubles; int get triples; int get homeRuns; int get walks; int get hitByPitch; int get strikeouts; double get inningsPitched; int get earnedRuns; int get totalPitches;
/// Create a copy of PlayerGameStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerGameStatsCopyWith<PlayerGameStats> get copyWith => _$PlayerGameStatsCopyWithImpl<PlayerGameStats>(this as PlayerGameStats, _$identity);

  /// Serializes this PlayerGameStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerGameStats&&(identical(other.atBats, atBats) || other.atBats == atBats)&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.hits, hits) || other.hits == hits)&&(identical(other.doubles, doubles) || other.doubles == doubles)&&(identical(other.triples, triples) || other.triples == triples)&&(identical(other.homeRuns, homeRuns) || other.homeRuns == homeRuns)&&(identical(other.walks, walks) || other.walks == walks)&&(identical(other.hitByPitch, hitByPitch) || other.hitByPitch == hitByPitch)&&(identical(other.strikeouts, strikeouts) || other.strikeouts == strikeouts)&&(identical(other.inningsPitched, inningsPitched) || other.inningsPitched == inningsPitched)&&(identical(other.earnedRuns, earnedRuns) || other.earnedRuns == earnedRuns)&&(identical(other.totalPitches, totalPitches) || other.totalPitches == totalPitches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,atBats,runs,hits,doubles,triples,homeRuns,walks,hitByPitch,strikeouts,inningsPitched,earnedRuns,totalPitches);

@override
String toString() {
  return 'PlayerGameStats(atBats: $atBats, runs: $runs, hits: $hits, doubles: $doubles, triples: $triples, homeRuns: $homeRuns, walks: $walks, hitByPitch: $hitByPitch, strikeouts: $strikeouts, inningsPitched: $inningsPitched, earnedRuns: $earnedRuns, totalPitches: $totalPitches)';
}


}

/// @nodoc
abstract mixin class $PlayerGameStatsCopyWith<$Res>  {
  factory $PlayerGameStatsCopyWith(PlayerGameStats value, $Res Function(PlayerGameStats) _then) = _$PlayerGameStatsCopyWithImpl;
@useResult
$Res call({
 int atBats, int runs, int hits, int doubles, int triples, int homeRuns, int walks, int hitByPitch, int strikeouts, double inningsPitched, int earnedRuns, int totalPitches
});




}
/// @nodoc
class _$PlayerGameStatsCopyWithImpl<$Res>
    implements $PlayerGameStatsCopyWith<$Res> {
  _$PlayerGameStatsCopyWithImpl(this._self, this._then);

  final PlayerGameStats _self;
  final $Res Function(PlayerGameStats) _then;

/// Create a copy of PlayerGameStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? atBats = null,Object? runs = null,Object? hits = null,Object? doubles = null,Object? triples = null,Object? homeRuns = null,Object? walks = null,Object? hitByPitch = null,Object? strikeouts = null,Object? inningsPitched = null,Object? earnedRuns = null,Object? totalPitches = null,}) {
  return _then(_self.copyWith(
atBats: null == atBats ? _self.atBats : atBats // ignore: cast_nullable_to_non_nullable
as int,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,hits: null == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int,doubles: null == doubles ? _self.doubles : doubles // ignore: cast_nullable_to_non_nullable
as int,triples: null == triples ? _self.triples : triples // ignore: cast_nullable_to_non_nullable
as int,homeRuns: null == homeRuns ? _self.homeRuns : homeRuns // ignore: cast_nullable_to_non_nullable
as int,walks: null == walks ? _self.walks : walks // ignore: cast_nullable_to_non_nullable
as int,hitByPitch: null == hitByPitch ? _self.hitByPitch : hitByPitch // ignore: cast_nullable_to_non_nullable
as int,strikeouts: null == strikeouts ? _self.strikeouts : strikeouts // ignore: cast_nullable_to_non_nullable
as int,inningsPitched: null == inningsPitched ? _self.inningsPitched : inningsPitched // ignore: cast_nullable_to_non_nullable
as double,earnedRuns: null == earnedRuns ? _self.earnedRuns : earnedRuns // ignore: cast_nullable_to_non_nullable
as int,totalPitches: null == totalPitches ? _self.totalPitches : totalPitches // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerGameStats].
extension PlayerGameStatsPatterns on PlayerGameStats {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerGameStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerGameStats() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerGameStats value)  $default,){
final _that = this;
switch (_that) {
case _PlayerGameStats():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerGameStats value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerGameStats() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int atBats,  int runs,  int hits,  int doubles,  int triples,  int homeRuns,  int walks,  int hitByPitch,  int strikeouts,  double inningsPitched,  int earnedRuns,  int totalPitches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerGameStats() when $default != null:
return $default(_that.atBats,_that.runs,_that.hits,_that.doubles,_that.triples,_that.homeRuns,_that.walks,_that.hitByPitch,_that.strikeouts,_that.inningsPitched,_that.earnedRuns,_that.totalPitches);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int atBats,  int runs,  int hits,  int doubles,  int triples,  int homeRuns,  int walks,  int hitByPitch,  int strikeouts,  double inningsPitched,  int earnedRuns,  int totalPitches)  $default,) {final _that = this;
switch (_that) {
case _PlayerGameStats():
return $default(_that.atBats,_that.runs,_that.hits,_that.doubles,_that.triples,_that.homeRuns,_that.walks,_that.hitByPitch,_that.strikeouts,_that.inningsPitched,_that.earnedRuns,_that.totalPitches);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int atBats,  int runs,  int hits,  int doubles,  int triples,  int homeRuns,  int walks,  int hitByPitch,  int strikeouts,  double inningsPitched,  int earnedRuns,  int totalPitches)?  $default,) {final _that = this;
switch (_that) {
case _PlayerGameStats() when $default != null:
return $default(_that.atBats,_that.runs,_that.hits,_that.doubles,_that.triples,_that.homeRuns,_that.walks,_that.hitByPitch,_that.strikeouts,_that.inningsPitched,_that.earnedRuns,_that.totalPitches);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerGameStats implements PlayerGameStats {
  const _PlayerGameStats({this.atBats = 0, this.runs = 0, this.hits = 0, this.doubles = 0, this.triples = 0, this.homeRuns = 0, this.walks = 0, this.hitByPitch = 0, this.strikeouts = 0, this.inningsPitched = 0.0, this.earnedRuns = 0, this.totalPitches = 0});
  factory _PlayerGameStats.fromJson(Map<String, dynamic> json) => _$PlayerGameStatsFromJson(json);

@override@JsonKey() final  int atBats;
@override@JsonKey() final  int runs;
@override@JsonKey() final  int hits;
@override@JsonKey() final  int doubles;
@override@JsonKey() final  int triples;
@override@JsonKey() final  int homeRuns;
@override@JsonKey() final  int walks;
@override@JsonKey() final  int hitByPitch;
@override@JsonKey() final  int strikeouts;
@override@JsonKey() final  double inningsPitched;
@override@JsonKey() final  int earnedRuns;
@override@JsonKey() final  int totalPitches;

/// Create a copy of PlayerGameStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerGameStatsCopyWith<_PlayerGameStats> get copyWith => __$PlayerGameStatsCopyWithImpl<_PlayerGameStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerGameStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerGameStats&&(identical(other.atBats, atBats) || other.atBats == atBats)&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.hits, hits) || other.hits == hits)&&(identical(other.doubles, doubles) || other.doubles == doubles)&&(identical(other.triples, triples) || other.triples == triples)&&(identical(other.homeRuns, homeRuns) || other.homeRuns == homeRuns)&&(identical(other.walks, walks) || other.walks == walks)&&(identical(other.hitByPitch, hitByPitch) || other.hitByPitch == hitByPitch)&&(identical(other.strikeouts, strikeouts) || other.strikeouts == strikeouts)&&(identical(other.inningsPitched, inningsPitched) || other.inningsPitched == inningsPitched)&&(identical(other.earnedRuns, earnedRuns) || other.earnedRuns == earnedRuns)&&(identical(other.totalPitches, totalPitches) || other.totalPitches == totalPitches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,atBats,runs,hits,doubles,triples,homeRuns,walks,hitByPitch,strikeouts,inningsPitched,earnedRuns,totalPitches);

@override
String toString() {
  return 'PlayerGameStats(atBats: $atBats, runs: $runs, hits: $hits, doubles: $doubles, triples: $triples, homeRuns: $homeRuns, walks: $walks, hitByPitch: $hitByPitch, strikeouts: $strikeouts, inningsPitched: $inningsPitched, earnedRuns: $earnedRuns, totalPitches: $totalPitches)';
}


}

/// @nodoc
abstract mixin class _$PlayerGameStatsCopyWith<$Res> implements $PlayerGameStatsCopyWith<$Res> {
  factory _$PlayerGameStatsCopyWith(_PlayerGameStats value, $Res Function(_PlayerGameStats) _then) = __$PlayerGameStatsCopyWithImpl;
@override @useResult
$Res call({
 int atBats, int runs, int hits, int doubles, int triples, int homeRuns, int walks, int hitByPitch, int strikeouts, double inningsPitched, int earnedRuns, int totalPitches
});




}
/// @nodoc
class __$PlayerGameStatsCopyWithImpl<$Res>
    implements _$PlayerGameStatsCopyWith<$Res> {
  __$PlayerGameStatsCopyWithImpl(this._self, this._then);

  final _PlayerGameStats _self;
  final $Res Function(_PlayerGameStats) _then;

/// Create a copy of PlayerGameStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? atBats = null,Object? runs = null,Object? hits = null,Object? doubles = null,Object? triples = null,Object? homeRuns = null,Object? walks = null,Object? hitByPitch = null,Object? strikeouts = null,Object? inningsPitched = null,Object? earnedRuns = null,Object? totalPitches = null,}) {
  return _then(_PlayerGameStats(
atBats: null == atBats ? _self.atBats : atBats // ignore: cast_nullable_to_non_nullable
as int,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,hits: null == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int,doubles: null == doubles ? _self.doubles : doubles // ignore: cast_nullable_to_non_nullable
as int,triples: null == triples ? _self.triples : triples // ignore: cast_nullable_to_non_nullable
as int,homeRuns: null == homeRuns ? _self.homeRuns : homeRuns // ignore: cast_nullable_to_non_nullable
as int,walks: null == walks ? _self.walks : walks // ignore: cast_nullable_to_non_nullable
as int,hitByPitch: null == hitByPitch ? _self.hitByPitch : hitByPitch // ignore: cast_nullable_to_non_nullable
as int,strikeouts: null == strikeouts ? _self.strikeouts : strikeouts // ignore: cast_nullable_to_non_nullable
as int,inningsPitched: null == inningsPitched ? _self.inningsPitched : inningsPitched // ignore: cast_nullable_to_non_nullable
as double,earnedRuns: null == earnedRuns ? _self.earnedRuns : earnedRuns // ignore: cast_nullable_to_non_nullable
as int,totalPitches: null == totalPitches ? _self.totalPitches : totalPitches // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TeamGame {

 String get gameId; String get seasonId; String get teamId; DateTime get gameDate; String get opponent; String get location; String get type; String get status;// playerStats: map of playerId -> PlayerGameStats
 Map<String, PlayerGameStats> get playerStats; Map<String, dynamic>? get metadata; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of TeamGame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamGameCopyWith<TeamGame> get copyWith => _$TeamGameCopyWithImpl<TeamGame>(this as TeamGame, _$identity);

  /// Serializes this TeamGame to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamGame&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.gameDate, gameDate) || other.gameDate == gameDate)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.location, location) || other.location == location)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.playerStats, playerStats)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,seasonId,teamId,gameDate,opponent,location,type,status,const DeepCollectionEquality().hash(playerStats),const DeepCollectionEquality().hash(metadata),createdAt,updatedAt);

@override
String toString() {
  return 'TeamGame(gameId: $gameId, seasonId: $seasonId, teamId: $teamId, gameDate: $gameDate, opponent: $opponent, location: $location, type: $type, status: $status, playerStats: $playerStats, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TeamGameCopyWith<$Res>  {
  factory $TeamGameCopyWith(TeamGame value, $Res Function(TeamGame) _then) = _$TeamGameCopyWithImpl;
@useResult
$Res call({
 String gameId, String seasonId, String teamId, DateTime gameDate, String opponent, String location, String type, String status, Map<String, PlayerGameStats> playerStats, Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$TeamGameCopyWithImpl<$Res>
    implements $TeamGameCopyWith<$Res> {
  _$TeamGameCopyWithImpl(this._self, this._then);

  final TeamGame _self;
  final $Res Function(TeamGame) _then;

/// Create a copy of TeamGame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? seasonId = null,Object? teamId = null,Object? gameDate = null,Object? opponent = null,Object? location = null,Object? type = null,Object? status = null,Object? playerStats = null,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,gameDate: null == gameDate ? _self.gameDate : gameDate // ignore: cast_nullable_to_non_nullable
as DateTime,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,playerStats: null == playerStats ? _self.playerStats : playerStats // ignore: cast_nullable_to_non_nullable
as Map<String, PlayerGameStats>,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamGame].
extension TeamGamePatterns on TeamGame {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamGame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamGame() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamGame value)  $default,){
final _that = this;
switch (_that) {
case _TeamGame():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamGame value)?  $default,){
final _that = this;
switch (_that) {
case _TeamGame() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gameId,  String seasonId,  String teamId,  DateTime gameDate,  String opponent,  String location,  String type,  String status,  Map<String, PlayerGameStats> playerStats,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamGame() when $default != null:
return $default(_that.gameId,_that.seasonId,_that.teamId,_that.gameDate,_that.opponent,_that.location,_that.type,_that.status,_that.playerStats,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gameId,  String seasonId,  String teamId,  DateTime gameDate,  String opponent,  String location,  String type,  String status,  Map<String, PlayerGameStats> playerStats,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TeamGame():
return $default(_that.gameId,_that.seasonId,_that.teamId,_that.gameDate,_that.opponent,_that.location,_that.type,_that.status,_that.playerStats,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gameId,  String seasonId,  String teamId,  DateTime gameDate,  String opponent,  String location,  String type,  String status,  Map<String, PlayerGameStats> playerStats,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TeamGame() when $default != null:
return $default(_that.gameId,_that.seasonId,_that.teamId,_that.gameDate,_that.opponent,_that.location,_that.type,_that.status,_that.playerStats,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamGame implements TeamGame {
  const _TeamGame({required this.gameId, required this.seasonId, required this.teamId, required this.gameDate, required this.opponent, required this.location, this.type = 'regular', this.status = 'completed', final  Map<String, PlayerGameStats> playerStats = const <String, PlayerGameStats>{}, final  Map<String, dynamic>? metadata, this.createdAt, this.updatedAt}): _playerStats = playerStats,_metadata = metadata;
  factory _TeamGame.fromJson(Map<String, dynamic> json) => _$TeamGameFromJson(json);

@override final  String gameId;
@override final  String seasonId;
@override final  String teamId;
@override final  DateTime gameDate;
@override final  String opponent;
@override final  String location;
@override@JsonKey() final  String type;
@override@JsonKey() final  String status;
// playerStats: map of playerId -> PlayerGameStats
 final  Map<String, PlayerGameStats> _playerStats;
// playerStats: map of playerId -> PlayerGameStats
@override@JsonKey() Map<String, PlayerGameStats> get playerStats {
  if (_playerStats is EqualUnmodifiableMapView) return _playerStats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_playerStats);
}

 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of TeamGame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamGameCopyWith<_TeamGame> get copyWith => __$TeamGameCopyWithImpl<_TeamGame>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamGameToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamGame&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.gameDate, gameDate) || other.gameDate == gameDate)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.location, location) || other.location == location)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._playerStats, _playerStats)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,seasonId,teamId,gameDate,opponent,location,type,status,const DeepCollectionEquality().hash(_playerStats),const DeepCollectionEquality().hash(_metadata),createdAt,updatedAt);

@override
String toString() {
  return 'TeamGame(gameId: $gameId, seasonId: $seasonId, teamId: $teamId, gameDate: $gameDate, opponent: $opponent, location: $location, type: $type, status: $status, playerStats: $playerStats, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TeamGameCopyWith<$Res> implements $TeamGameCopyWith<$Res> {
  factory _$TeamGameCopyWith(_TeamGame value, $Res Function(_TeamGame) _then) = __$TeamGameCopyWithImpl;
@override @useResult
$Res call({
 String gameId, String seasonId, String teamId, DateTime gameDate, String opponent, String location, String type, String status, Map<String, PlayerGameStats> playerStats, Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$TeamGameCopyWithImpl<$Res>
    implements _$TeamGameCopyWith<$Res> {
  __$TeamGameCopyWithImpl(this._self, this._then);

  final _TeamGame _self;
  final $Res Function(_TeamGame) _then;

/// Create a copy of TeamGame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? seasonId = null,Object? teamId = null,Object? gameDate = null,Object? opponent = null,Object? location = null,Object? type = null,Object? status = null,Object? playerStats = null,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_TeamGame(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,gameDate: null == gameDate ? _self.gameDate : gameDate // ignore: cast_nullable_to_non_nullable
as DateTime,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,playerStats: null == playerStats ? _self._playerStats : playerStats // ignore: cast_nullable_to_non_nullable
as Map<String, PlayerGameStats>,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
