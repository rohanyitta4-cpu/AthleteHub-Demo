// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_event_v3.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameEventV3 {

 String get eventId; DateTime get timestamp; int get inning; String get half;// 'top' or 'bottom'
 String get batterId; String get pitcherId; EventOutcome get outcome; Map<String, bool> get runnersBefore;// {'1st': false, '2nd': false, '3rd': false}
 Map<String, bool> get runnersAfter;// {'1st': false, '2nd': false, '3rd': false}
 int get rbi; String? get scorerId;// player ID who scored
 Map<String, dynamic>? get metadata;
/// Create a copy of GameEventV3
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameEventV3CopyWith<GameEventV3> get copyWith => _$GameEventV3CopyWithImpl<GameEventV3>(this as GameEventV3, _$identity);

  /// Serializes this GameEventV3 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameEventV3&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.inning, inning) || other.inning == inning)&&(identical(other.half, half) || other.half == half)&&(identical(other.batterId, batterId) || other.batterId == batterId)&&(identical(other.pitcherId, pitcherId) || other.pitcherId == pitcherId)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&const DeepCollectionEquality().equals(other.runnersBefore, runnersBefore)&&const DeepCollectionEquality().equals(other.runnersAfter, runnersAfter)&&(identical(other.rbi, rbi) || other.rbi == rbi)&&(identical(other.scorerId, scorerId) || other.scorerId == scorerId)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,timestamp,inning,half,batterId,pitcherId,outcome,const DeepCollectionEquality().hash(runnersBefore),const DeepCollectionEquality().hash(runnersAfter),rbi,scorerId,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'GameEventV3(eventId: $eventId, timestamp: $timestamp, inning: $inning, half: $half, batterId: $batterId, pitcherId: $pitcherId, outcome: $outcome, runnersBefore: $runnersBefore, runnersAfter: $runnersAfter, rbi: $rbi, scorerId: $scorerId, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $GameEventV3CopyWith<$Res>  {
  factory $GameEventV3CopyWith(GameEventV3 value, $Res Function(GameEventV3) _then) = _$GameEventV3CopyWithImpl;
@useResult
$Res call({
 String eventId, DateTime timestamp, int inning, String half, String batterId, String pitcherId, EventOutcome outcome, Map<String, bool> runnersBefore, Map<String, bool> runnersAfter, int rbi, String? scorerId, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$GameEventV3CopyWithImpl<$Res>
    implements $GameEventV3CopyWith<$Res> {
  _$GameEventV3CopyWithImpl(this._self, this._then);

  final GameEventV3 _self;
  final $Res Function(GameEventV3) _then;

/// Create a copy of GameEventV3
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? timestamp = null,Object? inning = null,Object? half = null,Object? batterId = null,Object? pitcherId = null,Object? outcome = null,Object? runnersBefore = null,Object? runnersAfter = null,Object? rbi = null,Object? scorerId = freezed,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,inning: null == inning ? _self.inning : inning // ignore: cast_nullable_to_non_nullable
as int,half: null == half ? _self.half : half // ignore: cast_nullable_to_non_nullable
as String,batterId: null == batterId ? _self.batterId : batterId // ignore: cast_nullable_to_non_nullable
as String,pitcherId: null == pitcherId ? _self.pitcherId : pitcherId // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as EventOutcome,runnersBefore: null == runnersBefore ? _self.runnersBefore : runnersBefore // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,runnersAfter: null == runnersAfter ? _self.runnersAfter : runnersAfter // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,rbi: null == rbi ? _self.rbi : rbi // ignore: cast_nullable_to_non_nullable
as int,scorerId: freezed == scorerId ? _self.scorerId : scorerId // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameEventV3].
extension GameEventV3Patterns on GameEventV3 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameEventV3 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameEventV3() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameEventV3 value)  $default,){
final _that = this;
switch (_that) {
case _GameEventV3():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameEventV3 value)?  $default,){
final _that = this;
switch (_that) {
case _GameEventV3() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  DateTime timestamp,  int inning,  String half,  String batterId,  String pitcherId,  EventOutcome outcome,  Map<String, bool> runnersBefore,  Map<String, bool> runnersAfter,  int rbi,  String? scorerId,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameEventV3() when $default != null:
return $default(_that.eventId,_that.timestamp,_that.inning,_that.half,_that.batterId,_that.pitcherId,_that.outcome,_that.runnersBefore,_that.runnersAfter,_that.rbi,_that.scorerId,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  DateTime timestamp,  int inning,  String half,  String batterId,  String pitcherId,  EventOutcome outcome,  Map<String, bool> runnersBefore,  Map<String, bool> runnersAfter,  int rbi,  String? scorerId,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _GameEventV3():
return $default(_that.eventId,_that.timestamp,_that.inning,_that.half,_that.batterId,_that.pitcherId,_that.outcome,_that.runnersBefore,_that.runnersAfter,_that.rbi,_that.scorerId,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  DateTime timestamp,  int inning,  String half,  String batterId,  String pitcherId,  EventOutcome outcome,  Map<String, bool> runnersBefore,  Map<String, bool> runnersAfter,  int rbi,  String? scorerId,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _GameEventV3() when $default != null:
return $default(_that.eventId,_that.timestamp,_that.inning,_that.half,_that.batterId,_that.pitcherId,_that.outcome,_that.runnersBefore,_that.runnersAfter,_that.rbi,_that.scorerId,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameEventV3 implements GameEventV3 {
  const _GameEventV3({required this.eventId, required this.timestamp, required this.inning, required this.half, required this.batterId, required this.pitcherId, required this.outcome, final  Map<String, bool> runnersBefore = const {}, final  Map<String, bool> runnersAfter = const {}, this.rbi = 0, this.scorerId, final  Map<String, dynamic>? metadata}): _runnersBefore = runnersBefore,_runnersAfter = runnersAfter,_metadata = metadata;
  factory _GameEventV3.fromJson(Map<String, dynamic> json) => _$GameEventV3FromJson(json);

@override final  String eventId;
@override final  DateTime timestamp;
@override final  int inning;
@override final  String half;
// 'top' or 'bottom'
@override final  String batterId;
@override final  String pitcherId;
@override final  EventOutcome outcome;
 final  Map<String, bool> _runnersBefore;
@override@JsonKey() Map<String, bool> get runnersBefore {
  if (_runnersBefore is EqualUnmodifiableMapView) return _runnersBefore;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_runnersBefore);
}

// {'1st': false, '2nd': false, '3rd': false}
 final  Map<String, bool> _runnersAfter;
// {'1st': false, '2nd': false, '3rd': false}
@override@JsonKey() Map<String, bool> get runnersAfter {
  if (_runnersAfter is EqualUnmodifiableMapView) return _runnersAfter;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_runnersAfter);
}

// {'1st': false, '2nd': false, '3rd': false}
@override@JsonKey() final  int rbi;
@override final  String? scorerId;
// player ID who scored
 final  Map<String, dynamic>? _metadata;
// player ID who scored
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of GameEventV3
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameEventV3CopyWith<_GameEventV3> get copyWith => __$GameEventV3CopyWithImpl<_GameEventV3>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameEventV3ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameEventV3&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.inning, inning) || other.inning == inning)&&(identical(other.half, half) || other.half == half)&&(identical(other.batterId, batterId) || other.batterId == batterId)&&(identical(other.pitcherId, pitcherId) || other.pitcherId == pitcherId)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&const DeepCollectionEquality().equals(other._runnersBefore, _runnersBefore)&&const DeepCollectionEquality().equals(other._runnersAfter, _runnersAfter)&&(identical(other.rbi, rbi) || other.rbi == rbi)&&(identical(other.scorerId, scorerId) || other.scorerId == scorerId)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,timestamp,inning,half,batterId,pitcherId,outcome,const DeepCollectionEquality().hash(_runnersBefore),const DeepCollectionEquality().hash(_runnersAfter),rbi,scorerId,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'GameEventV3(eventId: $eventId, timestamp: $timestamp, inning: $inning, half: $half, batterId: $batterId, pitcherId: $pitcherId, outcome: $outcome, runnersBefore: $runnersBefore, runnersAfter: $runnersAfter, rbi: $rbi, scorerId: $scorerId, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$GameEventV3CopyWith<$Res> implements $GameEventV3CopyWith<$Res> {
  factory _$GameEventV3CopyWith(_GameEventV3 value, $Res Function(_GameEventV3) _then) = __$GameEventV3CopyWithImpl;
@override @useResult
$Res call({
 String eventId, DateTime timestamp, int inning, String half, String batterId, String pitcherId, EventOutcome outcome, Map<String, bool> runnersBefore, Map<String, bool> runnersAfter, int rbi, String? scorerId, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$GameEventV3CopyWithImpl<$Res>
    implements _$GameEventV3CopyWith<$Res> {
  __$GameEventV3CopyWithImpl(this._self, this._then);

  final _GameEventV3 _self;
  final $Res Function(_GameEventV3) _then;

/// Create a copy of GameEventV3
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? timestamp = null,Object? inning = null,Object? half = null,Object? batterId = null,Object? pitcherId = null,Object? outcome = null,Object? runnersBefore = null,Object? runnersAfter = null,Object? rbi = null,Object? scorerId = freezed,Object? metadata = freezed,}) {
  return _then(_GameEventV3(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,inning: null == inning ? _self.inning : inning // ignore: cast_nullable_to_non_nullable
as int,half: null == half ? _self.half : half // ignore: cast_nullable_to_non_nullable
as String,batterId: null == batterId ? _self.batterId : batterId // ignore: cast_nullable_to_non_nullable
as String,pitcherId: null == pitcherId ? _self.pitcherId : pitcherId // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as EventOutcome,runnersBefore: null == runnersBefore ? _self._runnersBefore : runnersBefore // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,runnersAfter: null == runnersAfter ? _self._runnersAfter : runnersAfter // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,rbi: null == rbi ? _self.rbi : rbi // ignore: cast_nullable_to_non_nullable
as int,scorerId: freezed == scorerId ? _self.scorerId : scorerId // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
