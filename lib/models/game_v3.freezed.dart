// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_v3.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameV3 {

 String get gameId; String get teamHome; String get teamAway; DateTime get date; GameState get state; int get inning; String get half;// 'top' or 'bottom'
 int get outs; Map<String, bool> get runners;// {'1st': false, '2nd': false, '3rd': false}
 Map<String, int> get score;// {'home': 0, 'away': 0}
 List<String> get lineupHome;// player IDs
 List<String> get lineupAway;// player IDs
 List<String> get events;// event IDs
 Map<String, dynamic>? get metadata; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of GameV3
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameV3CopyWith<GameV3> get copyWith => _$GameV3CopyWithImpl<GameV3>(this as GameV3, _$identity);

  /// Serializes this GameV3 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameV3&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.teamHome, teamHome) || other.teamHome == teamHome)&&(identical(other.teamAway, teamAway) || other.teamAway == teamAway)&&(identical(other.date, date) || other.date == date)&&(identical(other.state, state) || other.state == state)&&(identical(other.inning, inning) || other.inning == inning)&&(identical(other.half, half) || other.half == half)&&(identical(other.outs, outs) || other.outs == outs)&&const DeepCollectionEquality().equals(other.runners, runners)&&const DeepCollectionEquality().equals(other.score, score)&&const DeepCollectionEquality().equals(other.lineupHome, lineupHome)&&const DeepCollectionEquality().equals(other.lineupAway, lineupAway)&&const DeepCollectionEquality().equals(other.events, events)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,teamHome,teamAway,date,state,inning,half,outs,const DeepCollectionEquality().hash(runners),const DeepCollectionEquality().hash(score),const DeepCollectionEquality().hash(lineupHome),const DeepCollectionEquality().hash(lineupAway),const DeepCollectionEquality().hash(events),const DeepCollectionEquality().hash(metadata),createdAt,updatedAt);

@override
String toString() {
  return 'GameV3(gameId: $gameId, teamHome: $teamHome, teamAway: $teamAway, date: $date, state: $state, inning: $inning, half: $half, outs: $outs, runners: $runners, score: $score, lineupHome: $lineupHome, lineupAway: $lineupAway, events: $events, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GameV3CopyWith<$Res>  {
  factory $GameV3CopyWith(GameV3 value, $Res Function(GameV3) _then) = _$GameV3CopyWithImpl;
@useResult
$Res call({
 String gameId, String teamHome, String teamAway, DateTime date, GameState state, int inning, String half, int outs, Map<String, bool> runners, Map<String, int> score, List<String> lineupHome, List<String> lineupAway, List<String> events, Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$GameV3CopyWithImpl<$Res>
    implements $GameV3CopyWith<$Res> {
  _$GameV3CopyWithImpl(this._self, this._then);

  final GameV3 _self;
  final $Res Function(GameV3) _then;

/// Create a copy of GameV3
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? teamHome = null,Object? teamAway = null,Object? date = null,Object? state = null,Object? inning = null,Object? half = null,Object? outs = null,Object? runners = null,Object? score = null,Object? lineupHome = null,Object? lineupAway = null,Object? events = null,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,teamHome: null == teamHome ? _self.teamHome : teamHome // ignore: cast_nullable_to_non_nullable
as String,teamAway: null == teamAway ? _self.teamAway : teamAway // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as GameState,inning: null == inning ? _self.inning : inning // ignore: cast_nullable_to_non_nullable
as int,half: null == half ? _self.half : half // ignore: cast_nullable_to_non_nullable
as String,outs: null == outs ? _self.outs : outs // ignore: cast_nullable_to_non_nullable
as int,runners: null == runners ? _self.runners : runners // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as Map<String, int>,lineupHome: null == lineupHome ? _self.lineupHome : lineupHome // ignore: cast_nullable_to_non_nullable
as List<String>,lineupAway: null == lineupAway ? _self.lineupAway : lineupAway // ignore: cast_nullable_to_non_nullable
as List<String>,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<String>,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameV3].
extension GameV3Patterns on GameV3 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameV3 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameV3() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameV3 value)  $default,){
final _that = this;
switch (_that) {
case _GameV3():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameV3 value)?  $default,){
final _that = this;
switch (_that) {
case _GameV3() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gameId,  String teamHome,  String teamAway,  DateTime date,  GameState state,  int inning,  String half,  int outs,  Map<String, bool> runners,  Map<String, int> score,  List<String> lineupHome,  List<String> lineupAway,  List<String> events,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameV3() when $default != null:
return $default(_that.gameId,_that.teamHome,_that.teamAway,_that.date,_that.state,_that.inning,_that.half,_that.outs,_that.runners,_that.score,_that.lineupHome,_that.lineupAway,_that.events,_that.metadata,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gameId,  String teamHome,  String teamAway,  DateTime date,  GameState state,  int inning,  String half,  int outs,  Map<String, bool> runners,  Map<String, int> score,  List<String> lineupHome,  List<String> lineupAway,  List<String> events,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _GameV3():
return $default(_that.gameId,_that.teamHome,_that.teamAway,_that.date,_that.state,_that.inning,_that.half,_that.outs,_that.runners,_that.score,_that.lineupHome,_that.lineupAway,_that.events,_that.metadata,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gameId,  String teamHome,  String teamAway,  DateTime date,  GameState state,  int inning,  String half,  int outs,  Map<String, bool> runners,  Map<String, int> score,  List<String> lineupHome,  List<String> lineupAway,  List<String> events,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _GameV3() when $default != null:
return $default(_that.gameId,_that.teamHome,_that.teamAway,_that.date,_that.state,_that.inning,_that.half,_that.outs,_that.runners,_that.score,_that.lineupHome,_that.lineupAway,_that.events,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameV3 implements GameV3 {
  const _GameV3({required this.gameId, required this.teamHome, required this.teamAway, required this.date, this.state = GameState.scheduled, this.inning = 1, this.half = 'top', this.outs = 0, final  Map<String, bool> runners = const {}, final  Map<String, int> score = const {}, final  List<String> lineupHome = const [], final  List<String> lineupAway = const [], final  List<String> events = const [], final  Map<String, dynamic>? metadata, this.createdAt, this.updatedAt}): _runners = runners,_score = score,_lineupHome = lineupHome,_lineupAway = lineupAway,_events = events,_metadata = metadata;
  factory _GameV3.fromJson(Map<String, dynamic> json) => _$GameV3FromJson(json);

@override final  String gameId;
@override final  String teamHome;
@override final  String teamAway;
@override final  DateTime date;
@override@JsonKey() final  GameState state;
@override@JsonKey() final  int inning;
@override@JsonKey() final  String half;
// 'top' or 'bottom'
@override@JsonKey() final  int outs;
 final  Map<String, bool> _runners;
@override@JsonKey() Map<String, bool> get runners {
  if (_runners is EqualUnmodifiableMapView) return _runners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_runners);
}

// {'1st': false, '2nd': false, '3rd': false}
 final  Map<String, int> _score;
// {'1st': false, '2nd': false, '3rd': false}
@override@JsonKey() Map<String, int> get score {
  if (_score is EqualUnmodifiableMapView) return _score;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_score);
}

// {'home': 0, 'away': 0}
 final  List<String> _lineupHome;
// {'home': 0, 'away': 0}
@override@JsonKey() List<String> get lineupHome {
  if (_lineupHome is EqualUnmodifiableListView) return _lineupHome;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lineupHome);
}

// player IDs
 final  List<String> _lineupAway;
// player IDs
@override@JsonKey() List<String> get lineupAway {
  if (_lineupAway is EqualUnmodifiableListView) return _lineupAway;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lineupAway);
}

// player IDs
 final  List<String> _events;
// player IDs
@override@JsonKey() List<String> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

// event IDs
 final  Map<String, dynamic>? _metadata;
// event IDs
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of GameV3
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameV3CopyWith<_GameV3> get copyWith => __$GameV3CopyWithImpl<_GameV3>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameV3ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameV3&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.teamHome, teamHome) || other.teamHome == teamHome)&&(identical(other.teamAway, teamAway) || other.teamAway == teamAway)&&(identical(other.date, date) || other.date == date)&&(identical(other.state, state) || other.state == state)&&(identical(other.inning, inning) || other.inning == inning)&&(identical(other.half, half) || other.half == half)&&(identical(other.outs, outs) || other.outs == outs)&&const DeepCollectionEquality().equals(other._runners, _runners)&&const DeepCollectionEquality().equals(other._score, _score)&&const DeepCollectionEquality().equals(other._lineupHome, _lineupHome)&&const DeepCollectionEquality().equals(other._lineupAway, _lineupAway)&&const DeepCollectionEquality().equals(other._events, _events)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,teamHome,teamAway,date,state,inning,half,outs,const DeepCollectionEquality().hash(_runners),const DeepCollectionEquality().hash(_score),const DeepCollectionEquality().hash(_lineupHome),const DeepCollectionEquality().hash(_lineupAway),const DeepCollectionEquality().hash(_events),const DeepCollectionEquality().hash(_metadata),createdAt,updatedAt);

@override
String toString() {
  return 'GameV3(gameId: $gameId, teamHome: $teamHome, teamAway: $teamAway, date: $date, state: $state, inning: $inning, half: $half, outs: $outs, runners: $runners, score: $score, lineupHome: $lineupHome, lineupAway: $lineupAway, events: $events, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GameV3CopyWith<$Res> implements $GameV3CopyWith<$Res> {
  factory _$GameV3CopyWith(_GameV3 value, $Res Function(_GameV3) _then) = __$GameV3CopyWithImpl;
@override @useResult
$Res call({
 String gameId, String teamHome, String teamAway, DateTime date, GameState state, int inning, String half, int outs, Map<String, bool> runners, Map<String, int> score, List<String> lineupHome, List<String> lineupAway, List<String> events, Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$GameV3CopyWithImpl<$Res>
    implements _$GameV3CopyWith<$Res> {
  __$GameV3CopyWithImpl(this._self, this._then);

  final _GameV3 _self;
  final $Res Function(_GameV3) _then;

/// Create a copy of GameV3
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? teamHome = null,Object? teamAway = null,Object? date = null,Object? state = null,Object? inning = null,Object? half = null,Object? outs = null,Object? runners = null,Object? score = null,Object? lineupHome = null,Object? lineupAway = null,Object? events = null,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_GameV3(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,teamHome: null == teamHome ? _self.teamHome : teamHome // ignore: cast_nullable_to_non_nullable
as String,teamAway: null == teamAway ? _self.teamAway : teamAway // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as GameState,inning: null == inning ? _self.inning : inning // ignore: cast_nullable_to_non_nullable
as int,half: null == half ? _self.half : half // ignore: cast_nullable_to_non_nullable
as String,outs: null == outs ? _self.outs : outs // ignore: cast_nullable_to_non_nullable
as int,runners: null == runners ? _self._runners : runners // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,score: null == score ? _self._score : score // ignore: cast_nullable_to_non_nullable
as Map<String, int>,lineupHome: null == lineupHome ? _self._lineupHome : lineupHome // ignore: cast_nullable_to_non_nullable
as List<String>,lineupAway: null == lineupAway ? _self._lineupAway : lineupAway // ignore: cast_nullable_to_non_nullable
as List<String>,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<String>,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
