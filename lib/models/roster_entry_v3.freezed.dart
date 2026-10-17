// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'roster_entry_v3.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RosterEntryV3 {

 String get playerId; String get teamId; String get userId; String get position; int get jerseyNumber; DateTime get joinedAt; DateTime? get leftAt; Map<String, dynamic>? get metadata;
/// Create a copy of RosterEntryV3
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RosterEntryV3CopyWith<RosterEntryV3> get copyWith => _$RosterEntryV3CopyWithImpl<RosterEntryV3>(this as RosterEntryV3, _$identity);

  /// Serializes this RosterEntryV3 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RosterEntryV3&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.position, position) || other.position == position)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.leftAt, leftAt) || other.leftAt == leftAt)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,teamId,userId,position,jerseyNumber,joinedAt,leftAt,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'RosterEntryV3(playerId: $playerId, teamId: $teamId, userId: $userId, position: $position, jerseyNumber: $jerseyNumber, joinedAt: $joinedAt, leftAt: $leftAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $RosterEntryV3CopyWith<$Res>  {
  factory $RosterEntryV3CopyWith(RosterEntryV3 value, $Res Function(RosterEntryV3) _then) = _$RosterEntryV3CopyWithImpl;
@useResult
$Res call({
 String playerId, String teamId, String userId, String position, int jerseyNumber, DateTime joinedAt, DateTime? leftAt, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$RosterEntryV3CopyWithImpl<$Res>
    implements $RosterEntryV3CopyWith<$Res> {
  _$RosterEntryV3CopyWithImpl(this._self, this._then);

  final RosterEntryV3 _self;
  final $Res Function(RosterEntryV3) _then;

/// Create a copy of RosterEntryV3
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? teamId = null,Object? userId = null,Object? position = null,Object? jerseyNumber = null,Object? joinedAt = null,Object? leftAt = freezed,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String,jerseyNumber: null == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as int,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,leftAt: freezed == leftAt ? _self.leftAt : leftAt // ignore: cast_nullable_to_non_nullable
as DateTime?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [RosterEntryV3].
extension RosterEntryV3Patterns on RosterEntryV3 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RosterEntryV3 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RosterEntryV3() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RosterEntryV3 value)  $default,){
final _that = this;
switch (_that) {
case _RosterEntryV3():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RosterEntryV3 value)?  $default,){
final _that = this;
switch (_that) {
case _RosterEntryV3() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  String teamId,  String userId,  String position,  int jerseyNumber,  DateTime joinedAt,  DateTime? leftAt,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RosterEntryV3() when $default != null:
return $default(_that.playerId,_that.teamId,_that.userId,_that.position,_that.jerseyNumber,_that.joinedAt,_that.leftAt,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  String teamId,  String userId,  String position,  int jerseyNumber,  DateTime joinedAt,  DateTime? leftAt,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _RosterEntryV3():
return $default(_that.playerId,_that.teamId,_that.userId,_that.position,_that.jerseyNumber,_that.joinedAt,_that.leftAt,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  String teamId,  String userId,  String position,  int jerseyNumber,  DateTime joinedAt,  DateTime? leftAt,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _RosterEntryV3() when $default != null:
return $default(_that.playerId,_that.teamId,_that.userId,_that.position,_that.jerseyNumber,_that.joinedAt,_that.leftAt,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RosterEntryV3 implements RosterEntryV3 {
  const _RosterEntryV3({required this.playerId, required this.teamId, required this.userId, required this.position, required this.jerseyNumber, required this.joinedAt, this.leftAt, final  Map<String, dynamic>? metadata}): _metadata = metadata;
  factory _RosterEntryV3.fromJson(Map<String, dynamic> json) => _$RosterEntryV3FromJson(json);

@override final  String playerId;
@override final  String teamId;
@override final  String userId;
@override final  String position;
@override final  int jerseyNumber;
@override final  DateTime joinedAt;
@override final  DateTime? leftAt;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of RosterEntryV3
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RosterEntryV3CopyWith<_RosterEntryV3> get copyWith => __$RosterEntryV3CopyWithImpl<_RosterEntryV3>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RosterEntryV3ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RosterEntryV3&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.position, position) || other.position == position)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.leftAt, leftAt) || other.leftAt == leftAt)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,teamId,userId,position,jerseyNumber,joinedAt,leftAt,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'RosterEntryV3(playerId: $playerId, teamId: $teamId, userId: $userId, position: $position, jerseyNumber: $jerseyNumber, joinedAt: $joinedAt, leftAt: $leftAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$RosterEntryV3CopyWith<$Res> implements $RosterEntryV3CopyWith<$Res> {
  factory _$RosterEntryV3CopyWith(_RosterEntryV3 value, $Res Function(_RosterEntryV3) _then) = __$RosterEntryV3CopyWithImpl;
@override @useResult
$Res call({
 String playerId, String teamId, String userId, String position, int jerseyNumber, DateTime joinedAt, DateTime? leftAt, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$RosterEntryV3CopyWithImpl<$Res>
    implements _$RosterEntryV3CopyWith<$Res> {
  __$RosterEntryV3CopyWithImpl(this._self, this._then);

  final _RosterEntryV3 _self;
  final $Res Function(_RosterEntryV3) _then;

/// Create a copy of RosterEntryV3
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? teamId = null,Object? userId = null,Object? position = null,Object? jerseyNumber = null,Object? joinedAt = null,Object? leftAt = freezed,Object? metadata = freezed,}) {
  return _then(_RosterEntryV3(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String,jerseyNumber: null == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as int,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,leftAt: freezed == leftAt ? _self.leftAt : leftAt // ignore: cast_nullable_to_non_nullable
as DateTime?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
