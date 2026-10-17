// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile_v2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfileV2 {

 String get userId; String get displayName; String get email; DateTime get createdAt; DateTime get lastActive; UserRole get role; String? get profileImageUrl; String? get teamId; Map<String, dynamic> get preferences;
/// Create a copy of UserProfileV2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileV2CopyWith<UserProfileV2> get copyWith => _$UserProfileV2CopyWithImpl<UserProfileV2>(this as UserProfileV2, _$identity);

  /// Serializes this UserProfileV2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfileV2&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastActive, lastActive) || other.lastActive == lastActive)&&(identical(other.role, role) || other.role == role)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&const DeepCollectionEquality().equals(other.preferences, preferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,email,createdAt,lastActive,role,profileImageUrl,teamId,const DeepCollectionEquality().hash(preferences));

@override
String toString() {
  return 'UserProfileV2(userId: $userId, displayName: $displayName, email: $email, createdAt: $createdAt, lastActive: $lastActive, role: $role, profileImageUrl: $profileImageUrl, teamId: $teamId, preferences: $preferences)';
}


}

/// @nodoc
abstract mixin class $UserProfileV2CopyWith<$Res>  {
  factory $UserProfileV2CopyWith(UserProfileV2 value, $Res Function(UserProfileV2) _then) = _$UserProfileV2CopyWithImpl;
@useResult
$Res call({
 String userId, String displayName, String email, DateTime createdAt, DateTime lastActive, UserRole role, String? profileImageUrl, String? teamId, Map<String, dynamic> preferences
});




}
/// @nodoc
class _$UserProfileV2CopyWithImpl<$Res>
    implements $UserProfileV2CopyWith<$Res> {
  _$UserProfileV2CopyWithImpl(this._self, this._then);

  final UserProfileV2 _self;
  final $Res Function(UserProfileV2) _then;

/// Create a copy of UserProfileV2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? email = null,Object? createdAt = null,Object? lastActive = null,Object? role = null,Object? profileImageUrl = freezed,Object? teamId = freezed,Object? preferences = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastActive: null == lastActive ? _self.lastActive : lastActive // ignore: cast_nullable_to_non_nullable
as DateTime,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,teamId: freezed == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String?,preferences: null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfileV2].
extension UserProfileV2Patterns on UserProfileV2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfileV2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfileV2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfileV2 value)  $default,){
final _that = this;
switch (_that) {
case _UserProfileV2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfileV2 value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfileV2() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName,  String email,  DateTime createdAt,  DateTime lastActive,  UserRole role,  String? profileImageUrl,  String? teamId,  Map<String, dynamic> preferences)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfileV2() when $default != null:
return $default(_that.userId,_that.displayName,_that.email,_that.createdAt,_that.lastActive,_that.role,_that.profileImageUrl,_that.teamId,_that.preferences);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName,  String email,  DateTime createdAt,  DateTime lastActive,  UserRole role,  String? profileImageUrl,  String? teamId,  Map<String, dynamic> preferences)  $default,) {final _that = this;
switch (_that) {
case _UserProfileV2():
return $default(_that.userId,_that.displayName,_that.email,_that.createdAt,_that.lastActive,_that.role,_that.profileImageUrl,_that.teamId,_that.preferences);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName,  String email,  DateTime createdAt,  DateTime lastActive,  UserRole role,  String? profileImageUrl,  String? teamId,  Map<String, dynamic> preferences)?  $default,) {final _that = this;
switch (_that) {
case _UserProfileV2() when $default != null:
return $default(_that.userId,_that.displayName,_that.email,_that.createdAt,_that.lastActive,_that.role,_that.profileImageUrl,_that.teamId,_that.preferences);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfileV2 implements UserProfileV2 {
  const _UserProfileV2({required this.userId, required this.displayName, required this.email, required this.createdAt, required this.lastActive, this.role = UserRole.player, this.profileImageUrl, this.teamId, final  Map<String, dynamic> preferences = const {}}): _preferences = preferences;
  factory _UserProfileV2.fromJson(Map<String, dynamic> json) => _$UserProfileV2FromJson(json);

@override final  String userId;
@override final  String displayName;
@override final  String email;
@override final  DateTime createdAt;
@override final  DateTime lastActive;
@override@JsonKey() final  UserRole role;
@override final  String? profileImageUrl;
@override final  String? teamId;
 final  Map<String, dynamic> _preferences;
@override@JsonKey() Map<String, dynamic> get preferences {
  if (_preferences is EqualUnmodifiableMapView) return _preferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_preferences);
}


/// Create a copy of UserProfileV2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileV2CopyWith<_UserProfileV2> get copyWith => __$UserProfileV2CopyWithImpl<_UserProfileV2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileV2ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfileV2&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastActive, lastActive) || other.lastActive == lastActive)&&(identical(other.role, role) || other.role == role)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&const DeepCollectionEquality().equals(other._preferences, _preferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,email,createdAt,lastActive,role,profileImageUrl,teamId,const DeepCollectionEquality().hash(_preferences));

@override
String toString() {
  return 'UserProfileV2(userId: $userId, displayName: $displayName, email: $email, createdAt: $createdAt, lastActive: $lastActive, role: $role, profileImageUrl: $profileImageUrl, teamId: $teamId, preferences: $preferences)';
}


}

/// @nodoc
abstract mixin class _$UserProfileV2CopyWith<$Res> implements $UserProfileV2CopyWith<$Res> {
  factory _$UserProfileV2CopyWith(_UserProfileV2 value, $Res Function(_UserProfileV2) _then) = __$UserProfileV2CopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName, String email, DateTime createdAt, DateTime lastActive, UserRole role, String? profileImageUrl, String? teamId, Map<String, dynamic> preferences
});




}
/// @nodoc
class __$UserProfileV2CopyWithImpl<$Res>
    implements _$UserProfileV2CopyWith<$Res> {
  __$UserProfileV2CopyWithImpl(this._self, this._then);

  final _UserProfileV2 _self;
  final $Res Function(_UserProfileV2) _then;

/// Create a copy of UserProfileV2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? email = null,Object? createdAt = null,Object? lastActive = null,Object? role = null,Object? profileImageUrl = freezed,Object? teamId = freezed,Object? preferences = null,}) {
  return _then(_UserProfileV2(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastActive: null == lastActive ? _self.lastActive : lastActive // ignore: cast_nullable_to_non_nullable
as DateTime,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,teamId: freezed == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String?,preferences: null == preferences ? _self._preferences : preferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
