// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_season_totals.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerSeasonTotals {

 String get playerId; int get games; int get atBats; int get hits; int get runs; int get rbi; int get homeRuns; int get walks; int get strikeouts; double get inningsPitched;// ...other totals
 DateTime? get lastUpdated;
/// Create a copy of PlayerSeasonTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerSeasonTotalsCopyWith<PlayerSeasonTotals> get copyWith => _$PlayerSeasonTotalsCopyWithImpl<PlayerSeasonTotals>(this as PlayerSeasonTotals, _$identity);

  /// Serializes this PlayerSeasonTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerSeasonTotals&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.games, games) || other.games == games)&&(identical(other.atBats, atBats) || other.atBats == atBats)&&(identical(other.hits, hits) || other.hits == hits)&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.rbi, rbi) || other.rbi == rbi)&&(identical(other.homeRuns, homeRuns) || other.homeRuns == homeRuns)&&(identical(other.walks, walks) || other.walks == walks)&&(identical(other.strikeouts, strikeouts) || other.strikeouts == strikeouts)&&(identical(other.inningsPitched, inningsPitched) || other.inningsPitched == inningsPitched)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,games,atBats,hits,runs,rbi,homeRuns,walks,strikeouts,inningsPitched,lastUpdated);

@override
String toString() {
  return 'PlayerSeasonTotals(playerId: $playerId, games: $games, atBats: $atBats, hits: $hits, runs: $runs, rbi: $rbi, homeRuns: $homeRuns, walks: $walks, strikeouts: $strikeouts, inningsPitched: $inningsPitched, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class $PlayerSeasonTotalsCopyWith<$Res>  {
  factory $PlayerSeasonTotalsCopyWith(PlayerSeasonTotals value, $Res Function(PlayerSeasonTotals) _then) = _$PlayerSeasonTotalsCopyWithImpl;
@useResult
$Res call({
 String playerId, int games, int atBats, int hits, int runs, int rbi, int homeRuns, int walks, int strikeouts, double inningsPitched, DateTime? lastUpdated
});




}
/// @nodoc
class _$PlayerSeasonTotalsCopyWithImpl<$Res>
    implements $PlayerSeasonTotalsCopyWith<$Res> {
  _$PlayerSeasonTotalsCopyWithImpl(this._self, this._then);

  final PlayerSeasonTotals _self;
  final $Res Function(PlayerSeasonTotals) _then;

/// Create a copy of PlayerSeasonTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? games = null,Object? atBats = null,Object? hits = null,Object? runs = null,Object? rbi = null,Object? homeRuns = null,Object? walks = null,Object? strikeouts = null,Object? inningsPitched = null,Object? lastUpdated = freezed,}) {
  return _then(_self.copyWith(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,games: null == games ? _self.games : games // ignore: cast_nullable_to_non_nullable
as int,atBats: null == atBats ? _self.atBats : atBats // ignore: cast_nullable_to_non_nullable
as int,hits: null == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,rbi: null == rbi ? _self.rbi : rbi // ignore: cast_nullable_to_non_nullable
as int,homeRuns: null == homeRuns ? _self.homeRuns : homeRuns // ignore: cast_nullable_to_non_nullable
as int,walks: null == walks ? _self.walks : walks // ignore: cast_nullable_to_non_nullable
as int,strikeouts: null == strikeouts ? _self.strikeouts : strikeouts // ignore: cast_nullable_to_non_nullable
as int,inningsPitched: null == inningsPitched ? _self.inningsPitched : inningsPitched // ignore: cast_nullable_to_non_nullable
as double,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerSeasonTotals].
extension PlayerSeasonTotalsPatterns on PlayerSeasonTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerSeasonTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerSeasonTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerSeasonTotals value)  $default,){
final _that = this;
switch (_that) {
case _PlayerSeasonTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerSeasonTotals value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerSeasonTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  int games,  int atBats,  int hits,  int runs,  int rbi,  int homeRuns,  int walks,  int strikeouts,  double inningsPitched,  DateTime? lastUpdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerSeasonTotals() when $default != null:
return $default(_that.playerId,_that.games,_that.atBats,_that.hits,_that.runs,_that.rbi,_that.homeRuns,_that.walks,_that.strikeouts,_that.inningsPitched,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  int games,  int atBats,  int hits,  int runs,  int rbi,  int homeRuns,  int walks,  int strikeouts,  double inningsPitched,  DateTime? lastUpdated)  $default,) {final _that = this;
switch (_that) {
case _PlayerSeasonTotals():
return $default(_that.playerId,_that.games,_that.atBats,_that.hits,_that.runs,_that.rbi,_that.homeRuns,_that.walks,_that.strikeouts,_that.inningsPitched,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  int games,  int atBats,  int hits,  int runs,  int rbi,  int homeRuns,  int walks,  int strikeouts,  double inningsPitched,  DateTime? lastUpdated)?  $default,) {final _that = this;
switch (_that) {
case _PlayerSeasonTotals() when $default != null:
return $default(_that.playerId,_that.games,_that.atBats,_that.hits,_that.runs,_that.rbi,_that.homeRuns,_that.walks,_that.strikeouts,_that.inningsPitched,_that.lastUpdated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerSeasonTotals implements PlayerSeasonTotals {
  const _PlayerSeasonTotals({required this.playerId, this.games = 0, this.atBats = 0, this.hits = 0, this.runs = 0, this.rbi = 0, this.homeRuns = 0, this.walks = 0, this.strikeouts = 0, this.inningsPitched = 0.0, this.lastUpdated});
  factory _PlayerSeasonTotals.fromJson(Map<String, dynamic> json) => _$PlayerSeasonTotalsFromJson(json);

@override final  String playerId;
@override@JsonKey() final  int games;
@override@JsonKey() final  int atBats;
@override@JsonKey() final  int hits;
@override@JsonKey() final  int runs;
@override@JsonKey() final  int rbi;
@override@JsonKey() final  int homeRuns;
@override@JsonKey() final  int walks;
@override@JsonKey() final  int strikeouts;
@override@JsonKey() final  double inningsPitched;
// ...other totals
@override final  DateTime? lastUpdated;

/// Create a copy of PlayerSeasonTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerSeasonTotalsCopyWith<_PlayerSeasonTotals> get copyWith => __$PlayerSeasonTotalsCopyWithImpl<_PlayerSeasonTotals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerSeasonTotalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerSeasonTotals&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.games, games) || other.games == games)&&(identical(other.atBats, atBats) || other.atBats == atBats)&&(identical(other.hits, hits) || other.hits == hits)&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.rbi, rbi) || other.rbi == rbi)&&(identical(other.homeRuns, homeRuns) || other.homeRuns == homeRuns)&&(identical(other.walks, walks) || other.walks == walks)&&(identical(other.strikeouts, strikeouts) || other.strikeouts == strikeouts)&&(identical(other.inningsPitched, inningsPitched) || other.inningsPitched == inningsPitched)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,games,atBats,hits,runs,rbi,homeRuns,walks,strikeouts,inningsPitched,lastUpdated);

@override
String toString() {
  return 'PlayerSeasonTotals(playerId: $playerId, games: $games, atBats: $atBats, hits: $hits, runs: $runs, rbi: $rbi, homeRuns: $homeRuns, walks: $walks, strikeouts: $strikeouts, inningsPitched: $inningsPitched, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class _$PlayerSeasonTotalsCopyWith<$Res> implements $PlayerSeasonTotalsCopyWith<$Res> {
  factory _$PlayerSeasonTotalsCopyWith(_PlayerSeasonTotals value, $Res Function(_PlayerSeasonTotals) _then) = __$PlayerSeasonTotalsCopyWithImpl;
@override @useResult
$Res call({
 String playerId, int games, int atBats, int hits, int runs, int rbi, int homeRuns, int walks, int strikeouts, double inningsPitched, DateTime? lastUpdated
});




}
/// @nodoc
class __$PlayerSeasonTotalsCopyWithImpl<$Res>
    implements _$PlayerSeasonTotalsCopyWith<$Res> {
  __$PlayerSeasonTotalsCopyWithImpl(this._self, this._then);

  final _PlayerSeasonTotals _self;
  final $Res Function(_PlayerSeasonTotals) _then;

/// Create a copy of PlayerSeasonTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? games = null,Object? atBats = null,Object? hits = null,Object? runs = null,Object? rbi = null,Object? homeRuns = null,Object? walks = null,Object? strikeouts = null,Object? inningsPitched = null,Object? lastUpdated = freezed,}) {
  return _then(_PlayerSeasonTotals(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,games: null == games ? _self.games : games // ignore: cast_nullable_to_non_nullable
as int,atBats: null == atBats ? _self.atBats : atBats // ignore: cast_nullable_to_non_nullable
as int,hits: null == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,rbi: null == rbi ? _self.rbi : rbi // ignore: cast_nullable_to_non_nullable
as int,homeRuns: null == homeRuns ? _self.homeRuns : homeRuns // ignore: cast_nullable_to_non_nullable
as int,walks: null == walks ? _self.walks : walks // ignore: cast_nullable_to_non_nullable
as int,strikeouts: null == strikeouts ? _self.strikeouts : strikeouts // ignore: cast_nullable_to_non_nullable
as int,inningsPitched: null == inningsPitched ? _self.inningsPitched : inningsPitched // ignore: cast_nullable_to_non_nullable
as double,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
