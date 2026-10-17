// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Game {

 String get gameId; String get teamId; String get seasonId; String get playerId;// The player this game belongs to
 String get userId;// User who created this entry
 DateTime get gameDate; String get opponent; String get location; GameType get type; GameStatus get status;// embedded per-game stats
 int get atBats; int get runs; int get hits; int get doubles; int get triples; int get homeRuns; int get walks; int get hitByPitch; int get strikeouts; int get sacrificeHits; int get stolenBases; int get runsBattedIn; int get twoStrikeCounts; int get successWithTwoStrikes; int get earnedRuns; int get totalPitches; double get inningsPitched; Map<String, dynamic>? get metadata; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameCopyWith<Game> get copyWith => _$GameCopyWithImpl<Game>(this as Game, _$identity);

  /// Serializes this Game to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Game&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.gameDate, gameDate) || other.gameDate == gameDate)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.location, location) || other.location == location)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.atBats, atBats) || other.atBats == atBats)&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.hits, hits) || other.hits == hits)&&(identical(other.doubles, doubles) || other.doubles == doubles)&&(identical(other.triples, triples) || other.triples == triples)&&(identical(other.homeRuns, homeRuns) || other.homeRuns == homeRuns)&&(identical(other.walks, walks) || other.walks == walks)&&(identical(other.hitByPitch, hitByPitch) || other.hitByPitch == hitByPitch)&&(identical(other.strikeouts, strikeouts) || other.strikeouts == strikeouts)&&(identical(other.sacrificeHits, sacrificeHits) || other.sacrificeHits == sacrificeHits)&&(identical(other.stolenBases, stolenBases) || other.stolenBases == stolenBases)&&(identical(other.runsBattedIn, runsBattedIn) || other.runsBattedIn == runsBattedIn)&&(identical(other.twoStrikeCounts, twoStrikeCounts) || other.twoStrikeCounts == twoStrikeCounts)&&(identical(other.successWithTwoStrikes, successWithTwoStrikes) || other.successWithTwoStrikes == successWithTwoStrikes)&&(identical(other.earnedRuns, earnedRuns) || other.earnedRuns == earnedRuns)&&(identical(other.totalPitches, totalPitches) || other.totalPitches == totalPitches)&&(identical(other.inningsPitched, inningsPitched) || other.inningsPitched == inningsPitched)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,gameId,teamId,seasonId,playerId,userId,gameDate,opponent,location,type,status,atBats,runs,hits,doubles,triples,homeRuns,walks,hitByPitch,strikeouts,sacrificeHits,stolenBases,runsBattedIn,twoStrikeCounts,successWithTwoStrikes,earnedRuns,totalPitches,inningsPitched,const DeepCollectionEquality().hash(metadata),createdAt,updatedAt]);

@override
String toString() {
  return 'Game(gameId: $gameId, teamId: $teamId, seasonId: $seasonId, playerId: $playerId, userId: $userId, gameDate: $gameDate, opponent: $opponent, location: $location, type: $type, status: $status, atBats: $atBats, runs: $runs, hits: $hits, doubles: $doubles, triples: $triples, homeRuns: $homeRuns, walks: $walks, hitByPitch: $hitByPitch, strikeouts: $strikeouts, sacrificeHits: $sacrificeHits, stolenBases: $stolenBases, runsBattedIn: $runsBattedIn, twoStrikeCounts: $twoStrikeCounts, successWithTwoStrikes: $successWithTwoStrikes, earnedRuns: $earnedRuns, totalPitches: $totalPitches, inningsPitched: $inningsPitched, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GameCopyWith<$Res>  {
  factory $GameCopyWith(Game value, $Res Function(Game) _then) = _$GameCopyWithImpl;
@useResult
$Res call({
 String gameId, String teamId, String seasonId, String playerId, String userId, DateTime gameDate, String opponent, String location, GameType type, GameStatus status, int atBats, int runs, int hits, int doubles, int triples, int homeRuns, int walks, int hitByPitch, int strikeouts, int sacrificeHits, int stolenBases, int runsBattedIn, int twoStrikeCounts, int successWithTwoStrikes, int earnedRuns, int totalPitches, double inningsPitched, Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$GameCopyWithImpl<$Res>
    implements $GameCopyWith<$Res> {
  _$GameCopyWithImpl(this._self, this._then);

  final Game _self;
  final $Res Function(Game) _then;

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? teamId = null,Object? seasonId = null,Object? playerId = null,Object? userId = null,Object? gameDate = null,Object? opponent = null,Object? location = null,Object? type = null,Object? status = null,Object? atBats = null,Object? runs = null,Object? hits = null,Object? doubles = null,Object? triples = null,Object? homeRuns = null,Object? walks = null,Object? hitByPitch = null,Object? strikeouts = null,Object? sacrificeHits = null,Object? stolenBases = null,Object? runsBattedIn = null,Object? twoStrikeCounts = null,Object? successWithTwoStrikes = null,Object? earnedRuns = null,Object? totalPitches = null,Object? inningsPitched = null,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,gameDate: null == gameDate ? _self.gameDate : gameDate // ignore: cast_nullable_to_non_nullable
as DateTime,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GameType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GameStatus,atBats: null == atBats ? _self.atBats : atBats // ignore: cast_nullable_to_non_nullable
as int,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,hits: null == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int,doubles: null == doubles ? _self.doubles : doubles // ignore: cast_nullable_to_non_nullable
as int,triples: null == triples ? _self.triples : triples // ignore: cast_nullable_to_non_nullable
as int,homeRuns: null == homeRuns ? _self.homeRuns : homeRuns // ignore: cast_nullable_to_non_nullable
as int,walks: null == walks ? _self.walks : walks // ignore: cast_nullable_to_non_nullable
as int,hitByPitch: null == hitByPitch ? _self.hitByPitch : hitByPitch // ignore: cast_nullable_to_non_nullable
as int,strikeouts: null == strikeouts ? _self.strikeouts : strikeouts // ignore: cast_nullable_to_non_nullable
as int,sacrificeHits: null == sacrificeHits ? _self.sacrificeHits : sacrificeHits // ignore: cast_nullable_to_non_nullable
as int,stolenBases: null == stolenBases ? _self.stolenBases : stolenBases // ignore: cast_nullable_to_non_nullable
as int,runsBattedIn: null == runsBattedIn ? _self.runsBattedIn : runsBattedIn // ignore: cast_nullable_to_non_nullable
as int,twoStrikeCounts: null == twoStrikeCounts ? _self.twoStrikeCounts : twoStrikeCounts // ignore: cast_nullable_to_non_nullable
as int,successWithTwoStrikes: null == successWithTwoStrikes ? _self.successWithTwoStrikes : successWithTwoStrikes // ignore: cast_nullable_to_non_nullable
as int,earnedRuns: null == earnedRuns ? _self.earnedRuns : earnedRuns // ignore: cast_nullable_to_non_nullable
as int,totalPitches: null == totalPitches ? _self.totalPitches : totalPitches // ignore: cast_nullable_to_non_nullable
as int,inningsPitched: null == inningsPitched ? _self.inningsPitched : inningsPitched // ignore: cast_nullable_to_non_nullable
as double,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Game].
extension GamePatterns on Game {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Game value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Game() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Game value)  $default,){
final _that = this;
switch (_that) {
case _Game():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Game value)?  $default,){
final _that = this;
switch (_that) {
case _Game() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gameId,  String teamId,  String seasonId,  String playerId,  String userId,  DateTime gameDate,  String opponent,  String location,  GameType type,  GameStatus status,  int atBats,  int runs,  int hits,  int doubles,  int triples,  int homeRuns,  int walks,  int hitByPitch,  int strikeouts,  int sacrificeHits,  int stolenBases,  int runsBattedIn,  int twoStrikeCounts,  int successWithTwoStrikes,  int earnedRuns,  int totalPitches,  double inningsPitched,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Game() when $default != null:
return $default(_that.gameId,_that.teamId,_that.seasonId,_that.playerId,_that.userId,_that.gameDate,_that.opponent,_that.location,_that.type,_that.status,_that.atBats,_that.runs,_that.hits,_that.doubles,_that.triples,_that.homeRuns,_that.walks,_that.hitByPitch,_that.strikeouts,_that.sacrificeHits,_that.stolenBases,_that.runsBattedIn,_that.twoStrikeCounts,_that.successWithTwoStrikes,_that.earnedRuns,_that.totalPitches,_that.inningsPitched,_that.metadata,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gameId,  String teamId,  String seasonId,  String playerId,  String userId,  DateTime gameDate,  String opponent,  String location,  GameType type,  GameStatus status,  int atBats,  int runs,  int hits,  int doubles,  int triples,  int homeRuns,  int walks,  int hitByPitch,  int strikeouts,  int sacrificeHits,  int stolenBases,  int runsBattedIn,  int twoStrikeCounts,  int successWithTwoStrikes,  int earnedRuns,  int totalPitches,  double inningsPitched,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Game():
return $default(_that.gameId,_that.teamId,_that.seasonId,_that.playerId,_that.userId,_that.gameDate,_that.opponent,_that.location,_that.type,_that.status,_that.atBats,_that.runs,_that.hits,_that.doubles,_that.triples,_that.homeRuns,_that.walks,_that.hitByPitch,_that.strikeouts,_that.sacrificeHits,_that.stolenBases,_that.runsBattedIn,_that.twoStrikeCounts,_that.successWithTwoStrikes,_that.earnedRuns,_that.totalPitches,_that.inningsPitched,_that.metadata,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gameId,  String teamId,  String seasonId,  String playerId,  String userId,  DateTime gameDate,  String opponent,  String location,  GameType type,  GameStatus status,  int atBats,  int runs,  int hits,  int doubles,  int triples,  int homeRuns,  int walks,  int hitByPitch,  int strikeouts,  int sacrificeHits,  int stolenBases,  int runsBattedIn,  int twoStrikeCounts,  int successWithTwoStrikes,  int earnedRuns,  int totalPitches,  double inningsPitched,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Game() when $default != null:
return $default(_that.gameId,_that.teamId,_that.seasonId,_that.playerId,_that.userId,_that.gameDate,_that.opponent,_that.location,_that.type,_that.status,_that.atBats,_that.runs,_that.hits,_that.doubles,_that.triples,_that.homeRuns,_that.walks,_that.hitByPitch,_that.strikeouts,_that.sacrificeHits,_that.stolenBases,_that.runsBattedIn,_that.twoStrikeCounts,_that.successWithTwoStrikes,_that.earnedRuns,_that.totalPitches,_that.inningsPitched,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Game implements Game {
  const _Game({required this.gameId, required this.teamId, required this.seasonId, required this.playerId, required this.userId, required this.gameDate, required this.opponent, required this.location, this.type = GameType.regular, this.status = GameStatus.completed, this.atBats = 0, this.runs = 0, this.hits = 0, this.doubles = 0, this.triples = 0, this.homeRuns = 0, this.walks = 0, this.hitByPitch = 0, this.strikeouts = 0, this.sacrificeHits = 0, this.stolenBases = 0, this.runsBattedIn = 0, this.twoStrikeCounts = 0, this.successWithTwoStrikes = 0, this.earnedRuns = 0, this.totalPitches = 0, this.inningsPitched = 0.0, final  Map<String, dynamic>? metadata, this.createdAt, this.updatedAt}): _metadata = metadata;
  factory _Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);

@override final  String gameId;
@override final  String teamId;
@override final  String seasonId;
@override final  String playerId;
// The player this game belongs to
@override final  String userId;
// User who created this entry
@override final  DateTime gameDate;
@override final  String opponent;
@override final  String location;
@override@JsonKey() final  GameType type;
@override@JsonKey() final  GameStatus status;
// embedded per-game stats
@override@JsonKey() final  int atBats;
@override@JsonKey() final  int runs;
@override@JsonKey() final  int hits;
@override@JsonKey() final  int doubles;
@override@JsonKey() final  int triples;
@override@JsonKey() final  int homeRuns;
@override@JsonKey() final  int walks;
@override@JsonKey() final  int hitByPitch;
@override@JsonKey() final  int strikeouts;
@override@JsonKey() final  int sacrificeHits;
@override@JsonKey() final  int stolenBases;
@override@JsonKey() final  int runsBattedIn;
@override@JsonKey() final  int twoStrikeCounts;
@override@JsonKey() final  int successWithTwoStrikes;
@override@JsonKey() final  int earnedRuns;
@override@JsonKey() final  int totalPitches;
@override@JsonKey() final  double inningsPitched;
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

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameCopyWith<_Game> get copyWith => __$GameCopyWithImpl<_Game>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Game&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.gameDate, gameDate) || other.gameDate == gameDate)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.location, location) || other.location == location)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.atBats, atBats) || other.atBats == atBats)&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.hits, hits) || other.hits == hits)&&(identical(other.doubles, doubles) || other.doubles == doubles)&&(identical(other.triples, triples) || other.triples == triples)&&(identical(other.homeRuns, homeRuns) || other.homeRuns == homeRuns)&&(identical(other.walks, walks) || other.walks == walks)&&(identical(other.hitByPitch, hitByPitch) || other.hitByPitch == hitByPitch)&&(identical(other.strikeouts, strikeouts) || other.strikeouts == strikeouts)&&(identical(other.sacrificeHits, sacrificeHits) || other.sacrificeHits == sacrificeHits)&&(identical(other.stolenBases, stolenBases) || other.stolenBases == stolenBases)&&(identical(other.runsBattedIn, runsBattedIn) || other.runsBattedIn == runsBattedIn)&&(identical(other.twoStrikeCounts, twoStrikeCounts) || other.twoStrikeCounts == twoStrikeCounts)&&(identical(other.successWithTwoStrikes, successWithTwoStrikes) || other.successWithTwoStrikes == successWithTwoStrikes)&&(identical(other.earnedRuns, earnedRuns) || other.earnedRuns == earnedRuns)&&(identical(other.totalPitches, totalPitches) || other.totalPitches == totalPitches)&&(identical(other.inningsPitched, inningsPitched) || other.inningsPitched == inningsPitched)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,gameId,teamId,seasonId,playerId,userId,gameDate,opponent,location,type,status,atBats,runs,hits,doubles,triples,homeRuns,walks,hitByPitch,strikeouts,sacrificeHits,stolenBases,runsBattedIn,twoStrikeCounts,successWithTwoStrikes,earnedRuns,totalPitches,inningsPitched,const DeepCollectionEquality().hash(_metadata),createdAt,updatedAt]);

@override
String toString() {
  return 'Game(gameId: $gameId, teamId: $teamId, seasonId: $seasonId, playerId: $playerId, userId: $userId, gameDate: $gameDate, opponent: $opponent, location: $location, type: $type, status: $status, atBats: $atBats, runs: $runs, hits: $hits, doubles: $doubles, triples: $triples, homeRuns: $homeRuns, walks: $walks, hitByPitch: $hitByPitch, strikeouts: $strikeouts, sacrificeHits: $sacrificeHits, stolenBases: $stolenBases, runsBattedIn: $runsBattedIn, twoStrikeCounts: $twoStrikeCounts, successWithTwoStrikes: $successWithTwoStrikes, earnedRuns: $earnedRuns, totalPitches: $totalPitches, inningsPitched: $inningsPitched, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GameCopyWith<$Res> implements $GameCopyWith<$Res> {
  factory _$GameCopyWith(_Game value, $Res Function(_Game) _then) = __$GameCopyWithImpl;
@override @useResult
$Res call({
 String gameId, String teamId, String seasonId, String playerId, String userId, DateTime gameDate, String opponent, String location, GameType type, GameStatus status, int atBats, int runs, int hits, int doubles, int triples, int homeRuns, int walks, int hitByPitch, int strikeouts, int sacrificeHits, int stolenBases, int runsBattedIn, int twoStrikeCounts, int successWithTwoStrikes, int earnedRuns, int totalPitches, double inningsPitched, Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$GameCopyWithImpl<$Res>
    implements _$GameCopyWith<$Res> {
  __$GameCopyWithImpl(this._self, this._then);

  final _Game _self;
  final $Res Function(_Game) _then;

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? teamId = null,Object? seasonId = null,Object? playerId = null,Object? userId = null,Object? gameDate = null,Object? opponent = null,Object? location = null,Object? type = null,Object? status = null,Object? atBats = null,Object? runs = null,Object? hits = null,Object? doubles = null,Object? triples = null,Object? homeRuns = null,Object? walks = null,Object? hitByPitch = null,Object? strikeouts = null,Object? sacrificeHits = null,Object? stolenBases = null,Object? runsBattedIn = null,Object? twoStrikeCounts = null,Object? successWithTwoStrikes = null,Object? earnedRuns = null,Object? totalPitches = null,Object? inningsPitched = null,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Game(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,gameDate: null == gameDate ? _self.gameDate : gameDate // ignore: cast_nullable_to_non_nullable
as DateTime,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GameType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GameStatus,atBats: null == atBats ? _self.atBats : atBats // ignore: cast_nullable_to_non_nullable
as int,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,hits: null == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int,doubles: null == doubles ? _self.doubles : doubles // ignore: cast_nullable_to_non_nullable
as int,triples: null == triples ? _self.triples : triples // ignore: cast_nullable_to_non_nullable
as int,homeRuns: null == homeRuns ? _self.homeRuns : homeRuns // ignore: cast_nullable_to_non_nullable
as int,walks: null == walks ? _self.walks : walks // ignore: cast_nullable_to_non_nullable
as int,hitByPitch: null == hitByPitch ? _self.hitByPitch : hitByPitch // ignore: cast_nullable_to_non_nullable
as int,strikeouts: null == strikeouts ? _self.strikeouts : strikeouts // ignore: cast_nullable_to_non_nullable
as int,sacrificeHits: null == sacrificeHits ? _self.sacrificeHits : sacrificeHits // ignore: cast_nullable_to_non_nullable
as int,stolenBases: null == stolenBases ? _self.stolenBases : stolenBases // ignore: cast_nullable_to_non_nullable
as int,runsBattedIn: null == runsBattedIn ? _self.runsBattedIn : runsBattedIn // ignore: cast_nullable_to_non_nullable
as int,twoStrikeCounts: null == twoStrikeCounts ? _self.twoStrikeCounts : twoStrikeCounts // ignore: cast_nullable_to_non_nullable
as int,successWithTwoStrikes: null == successWithTwoStrikes ? _self.successWithTwoStrikes : successWithTwoStrikes // ignore: cast_nullable_to_non_nullable
as int,earnedRuns: null == earnedRuns ? _self.earnedRuns : earnedRuns // ignore: cast_nullable_to_non_nullable
as int,totalPitches: null == totalPitches ? _self.totalPitches : totalPitches // ignore: cast_nullable_to_non_nullable
as int,inningsPitched: null == inningsPitched ? _self.inningsPitched : inningsPitched // ignore: cast_nullable_to_non_nullable
as double,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
