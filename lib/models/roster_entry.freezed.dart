// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'roster_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RosterEntry {

 String get playerId; String? get role;// eg "starter", "bench"
 int? get jerseyNumber; DateTime? get addedAt;
/// Create a copy of RosterEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RosterEntryCopyWith<RosterEntry> get copyWith => _$RosterEntryCopyWithImpl<RosterEntry>(this as RosterEntry, _$identity);

  /// Serializes this RosterEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RosterEntry&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.role, role) || other.role == role)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,role,jerseyNumber,addedAt);

@override
String toString() {
  return 'RosterEntry(playerId: $playerId, role: $role, jerseyNumber: $jerseyNumber, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class $RosterEntryCopyWith<$Res>  {
  factory $RosterEntryCopyWith(RosterEntry value, $Res Function(RosterEntry) _then) = _$RosterEntryCopyWithImpl;
@useResult
$Res call({
 String playerId, String? role, int? jerseyNumber, DateTime? addedAt
});




}
/// @nodoc
class _$RosterEntryCopyWithImpl<$Res>
    implements $RosterEntryCopyWith<$Res> {
  _$RosterEntryCopyWithImpl(this._self, this._then);

  final RosterEntry _self;
  final $Res Function(RosterEntry) _then;

/// Create a copy of RosterEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? role = freezed,Object? jerseyNumber = freezed,Object? addedAt = freezed,}) {
  return _then(_self.copyWith(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as int?,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RosterEntry].
extension RosterEntryPatterns on RosterEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RosterEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RosterEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RosterEntry value)  $default,){
final _that = this;
switch (_that) {
case _RosterEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RosterEntry value)?  $default,){
final _that = this;
switch (_that) {
case _RosterEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  String? role,  int? jerseyNumber,  DateTime? addedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RosterEntry() when $default != null:
return $default(_that.playerId,_that.role,_that.jerseyNumber,_that.addedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  String? role,  int? jerseyNumber,  DateTime? addedAt)  $default,) {final _that = this;
switch (_that) {
case _RosterEntry():
return $default(_that.playerId,_that.role,_that.jerseyNumber,_that.addedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  String? role,  int? jerseyNumber,  DateTime? addedAt)?  $default,) {final _that = this;
switch (_that) {
case _RosterEntry() when $default != null:
return $default(_that.playerId,_that.role,_that.jerseyNumber,_that.addedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RosterEntry implements RosterEntry {
  const _RosterEntry({required this.playerId, this.role, this.jerseyNumber, this.addedAt});
  factory _RosterEntry.fromJson(Map<String, dynamic> json) => _$RosterEntryFromJson(json);

@override final  String playerId;
@override final  String? role;
// eg "starter", "bench"
@override final  int? jerseyNumber;
@override final  DateTime? addedAt;

/// Create a copy of RosterEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RosterEntryCopyWith<_RosterEntry> get copyWith => __$RosterEntryCopyWithImpl<_RosterEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RosterEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RosterEntry&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.role, role) || other.role == role)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,role,jerseyNumber,addedAt);

@override
String toString() {
  return 'RosterEntry(playerId: $playerId, role: $role, jerseyNumber: $jerseyNumber, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class _$RosterEntryCopyWith<$Res> implements $RosterEntryCopyWith<$Res> {
  factory _$RosterEntryCopyWith(_RosterEntry value, $Res Function(_RosterEntry) _then) = __$RosterEntryCopyWithImpl;
@override @useResult
$Res call({
 String playerId, String? role, int? jerseyNumber, DateTime? addedAt
});




}
/// @nodoc
class __$RosterEntryCopyWithImpl<$Res>
    implements _$RosterEntryCopyWith<$Res> {
  __$RosterEntryCopyWithImpl(this._self, this._then);

  final _RosterEntry _self;
  final $Res Function(_RosterEntry) _then;

/// Create a copy of RosterEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? role = freezed,Object? jerseyNumber = freezed,Object? addedAt = freezed,}) {
  return _then(_RosterEntry(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as int?,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
