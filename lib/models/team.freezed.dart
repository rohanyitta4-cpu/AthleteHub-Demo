// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Team {

 String get teamId; String get name; List<String> get coachIds;// user ids
 List<String> get playerIds; Map<String, dynamic>? get settings; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamCopyWith<Team> get copyWith => _$TeamCopyWithImpl<Team>(this as Team, _$identity);

  /// Serializes this Team to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Team&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.coachIds, coachIds)&&const DeepCollectionEquality().equals(other.playerIds, playerIds)&&const DeepCollectionEquality().equals(other.settings, settings)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,name,const DeepCollectionEquality().hash(coachIds),const DeepCollectionEquality().hash(playerIds),const DeepCollectionEquality().hash(settings),createdAt,updatedAt);

@override
String toString() {
  return 'Team(teamId: $teamId, name: $name, coachIds: $coachIds, playerIds: $playerIds, settings: $settings, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TeamCopyWith<$Res>  {
  factory $TeamCopyWith(Team value, $Res Function(Team) _then) = _$TeamCopyWithImpl;
@useResult
$Res call({
 String teamId, String name, List<String> coachIds, List<String> playerIds, Map<String, dynamic>? settings, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$TeamCopyWithImpl<$Res>
    implements $TeamCopyWith<$Res> {
  _$TeamCopyWithImpl(this._self, this._then);

  final Team _self;
  final $Res Function(Team) _then;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? teamId = null,Object? name = null,Object? coachIds = null,Object? playerIds = null,Object? settings = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,coachIds: null == coachIds ? _self.coachIds : coachIds // ignore: cast_nullable_to_non_nullable
as List<String>,playerIds: null == playerIds ? _self.playerIds : playerIds // ignore: cast_nullable_to_non_nullable
as List<String>,settings: freezed == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Team].
extension TeamPatterns on Team {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Team value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Team() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Team value)  $default,){
final _that = this;
switch (_that) {
case _Team():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Team value)?  $default,){
final _that = this;
switch (_that) {
case _Team() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String teamId,  String name,  List<String> coachIds,  List<String> playerIds,  Map<String, dynamic>? settings,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Team() when $default != null:
return $default(_that.teamId,_that.name,_that.coachIds,_that.playerIds,_that.settings,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String teamId,  String name,  List<String> coachIds,  List<String> playerIds,  Map<String, dynamic>? settings,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Team():
return $default(_that.teamId,_that.name,_that.coachIds,_that.playerIds,_that.settings,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String teamId,  String name,  List<String> coachIds,  List<String> playerIds,  Map<String, dynamic>? settings,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Team() when $default != null:
return $default(_that.teamId,_that.name,_that.coachIds,_that.playerIds,_that.settings,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Team implements Team {
  const _Team({required this.teamId, required this.name, required final  List<String> coachIds, final  List<String> playerIds = const <String>[], final  Map<String, dynamic>? settings, this.createdAt, this.updatedAt}): _coachIds = coachIds,_playerIds = playerIds,_settings = settings;
  factory _Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);

@override final  String teamId;
@override final  String name;
 final  List<String> _coachIds;
@override List<String> get coachIds {
  if (_coachIds is EqualUnmodifiableListView) return _coachIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coachIds);
}

// user ids
 final  List<String> _playerIds;
// user ids
@override@JsonKey() List<String> get playerIds {
  if (_playerIds is EqualUnmodifiableListView) return _playerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playerIds);
}

 final  Map<String, dynamic>? _settings;
@override Map<String, dynamic>? get settings {
  final value = _settings;
  if (value == null) return null;
  if (_settings is EqualUnmodifiableMapView) return _settings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamCopyWith<_Team> get copyWith => __$TeamCopyWithImpl<_Team>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Team&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._coachIds, _coachIds)&&const DeepCollectionEquality().equals(other._playerIds, _playerIds)&&const DeepCollectionEquality().equals(other._settings, _settings)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,name,const DeepCollectionEquality().hash(_coachIds),const DeepCollectionEquality().hash(_playerIds),const DeepCollectionEquality().hash(_settings),createdAt,updatedAt);

@override
String toString() {
  return 'Team(teamId: $teamId, name: $name, coachIds: $coachIds, playerIds: $playerIds, settings: $settings, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TeamCopyWith<$Res> implements $TeamCopyWith<$Res> {
  factory _$TeamCopyWith(_Team value, $Res Function(_Team) _then) = __$TeamCopyWithImpl;
@override @useResult
$Res call({
 String teamId, String name, List<String> coachIds, List<String> playerIds, Map<String, dynamic>? settings, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$TeamCopyWithImpl<$Res>
    implements _$TeamCopyWith<$Res> {
  __$TeamCopyWithImpl(this._self, this._then);

  final _Team _self;
  final $Res Function(_Team) _then;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teamId = null,Object? name = null,Object? coachIds = null,Object? playerIds = null,Object? settings = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Team(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,coachIds: null == coachIds ? _self._coachIds : coachIds // ignore: cast_nullable_to_non_nullable
as List<String>,playerIds: null == playerIds ? _self._playerIds : playerIds // ignore: cast_nullable_to_non_nullable
as List<String>,settings: freezed == settings ? _self._settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
