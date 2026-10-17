// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_team_membership.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserTeamMembership {

 String get userId; String get teamId; String get teamName; String get role;// "coach" or "player"
 DateTime get joinedAt; DateTime? get leftAt; bool get isActive; bool get isDefault;// User's default team
 Map<String, dynamic>? get metadata;
/// Create a copy of UserTeamMembership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserTeamMembershipCopyWith<UserTeamMembership> get copyWith => _$UserTeamMembershipCopyWithImpl<UserTeamMembership>(this as UserTeamMembership, _$identity);

  /// Serializes this UserTeamMembership to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserTeamMembership&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.leftAt, leftAt) || other.leftAt == leftAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,teamId,teamName,role,joinedAt,leftAt,isActive,isDefault,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'UserTeamMembership(userId: $userId, teamId: $teamId, teamName: $teamName, role: $role, joinedAt: $joinedAt, leftAt: $leftAt, isActive: $isActive, isDefault: $isDefault, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $UserTeamMembershipCopyWith<$Res>  {
  factory $UserTeamMembershipCopyWith(UserTeamMembership value, $Res Function(UserTeamMembership) _then) = _$UserTeamMembershipCopyWithImpl;
@useResult
$Res call({
 String userId, String teamId, String teamName, String role, DateTime joinedAt, DateTime? leftAt, bool isActive, bool isDefault, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$UserTeamMembershipCopyWithImpl<$Res>
    implements $UserTeamMembershipCopyWith<$Res> {
  _$UserTeamMembershipCopyWithImpl(this._self, this._then);

  final UserTeamMembership _self;
  final $Res Function(UserTeamMembership) _then;

/// Create a copy of UserTeamMembership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? teamId = null,Object? teamName = null,Object? role = null,Object? joinedAt = null,Object? leftAt = freezed,Object? isActive = null,Object? isDefault = null,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,leftAt: freezed == leftAt ? _self.leftAt : leftAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserTeamMembership].
extension UserTeamMembershipPatterns on UserTeamMembership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserTeamMembership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserTeamMembership() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserTeamMembership value)  $default,){
final _that = this;
switch (_that) {
case _UserTeamMembership():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserTeamMembership value)?  $default,){
final _that = this;
switch (_that) {
case _UserTeamMembership() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String teamId,  String teamName,  String role,  DateTime joinedAt,  DateTime? leftAt,  bool isActive,  bool isDefault,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserTeamMembership() when $default != null:
return $default(_that.userId,_that.teamId,_that.teamName,_that.role,_that.joinedAt,_that.leftAt,_that.isActive,_that.isDefault,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String teamId,  String teamName,  String role,  DateTime joinedAt,  DateTime? leftAt,  bool isActive,  bool isDefault,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _UserTeamMembership():
return $default(_that.userId,_that.teamId,_that.teamName,_that.role,_that.joinedAt,_that.leftAt,_that.isActive,_that.isDefault,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String teamId,  String teamName,  String role,  DateTime joinedAt,  DateTime? leftAt,  bool isActive,  bool isDefault,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _UserTeamMembership() when $default != null:
return $default(_that.userId,_that.teamId,_that.teamName,_that.role,_that.joinedAt,_that.leftAt,_that.isActive,_that.isDefault,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserTeamMembership implements UserTeamMembership {
  const _UserTeamMembership({required this.userId, required this.teamId, required this.teamName, required this.role, required this.joinedAt, this.leftAt, this.isActive = true, this.isDefault = false, final  Map<String, dynamic>? metadata}): _metadata = metadata;
  factory _UserTeamMembership.fromJson(Map<String, dynamic> json) => _$UserTeamMembershipFromJson(json);

@override final  String userId;
@override final  String teamId;
@override final  String teamName;
@override final  String role;
// "coach" or "player"
@override final  DateTime joinedAt;
@override final  DateTime? leftAt;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  bool isDefault;
// User's default team
 final  Map<String, dynamic>? _metadata;
// User's default team
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of UserTeamMembership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserTeamMembershipCopyWith<_UserTeamMembership> get copyWith => __$UserTeamMembershipCopyWithImpl<_UserTeamMembership>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserTeamMembershipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserTeamMembership&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.leftAt, leftAt) || other.leftAt == leftAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,teamId,teamName,role,joinedAt,leftAt,isActive,isDefault,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'UserTeamMembership(userId: $userId, teamId: $teamId, teamName: $teamName, role: $role, joinedAt: $joinedAt, leftAt: $leftAt, isActive: $isActive, isDefault: $isDefault, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$UserTeamMembershipCopyWith<$Res> implements $UserTeamMembershipCopyWith<$Res> {
  factory _$UserTeamMembershipCopyWith(_UserTeamMembership value, $Res Function(_UserTeamMembership) _then) = __$UserTeamMembershipCopyWithImpl;
@override @useResult
$Res call({
 String userId, String teamId, String teamName, String role, DateTime joinedAt, DateTime? leftAt, bool isActive, bool isDefault, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$UserTeamMembershipCopyWithImpl<$Res>
    implements _$UserTeamMembershipCopyWith<$Res> {
  __$UserTeamMembershipCopyWithImpl(this._self, this._then);

  final _UserTeamMembership _self;
  final $Res Function(_UserTeamMembership) _then;

/// Create a copy of UserTeamMembership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? teamId = null,Object? teamName = null,Object? role = null,Object? joinedAt = null,Object? leftAt = freezed,Object? isActive = null,Object? isDefault = null,Object? metadata = freezed,}) {
  return _then(_UserTeamMembership(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,leftAt: freezed == leftAt ? _self.leftAt : leftAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$UserProfileV3 {

 String get userId; String get email; String? get displayName; String? get firstName; String? get lastName; String? get profileImageUrl; DateTime get createdAt; DateTime? get updatedAt; List<UserTeamMembership> get teamMemberships; String? get defaultTeamId; Map<String, dynamic>? get preferences; Map<String, dynamic>? get metadata;
/// Create a copy of UserProfileV3
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileV3CopyWith<UserProfileV3> get copyWith => _$UserProfileV3CopyWithImpl<UserProfileV3>(this as UserProfileV3, _$identity);

  /// Serializes this UserProfileV3 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfileV3&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.teamMemberships, teamMemberships)&&(identical(other.defaultTeamId, defaultTeamId) || other.defaultTeamId == defaultTeamId)&&const DeepCollectionEquality().equals(other.preferences, preferences)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,email,displayName,firstName,lastName,profileImageUrl,createdAt,updatedAt,const DeepCollectionEquality().hash(teamMemberships),defaultTeamId,const DeepCollectionEquality().hash(preferences),const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'UserProfileV3(userId: $userId, email: $email, displayName: $displayName, firstName: $firstName, lastName: $lastName, profileImageUrl: $profileImageUrl, createdAt: $createdAt, updatedAt: $updatedAt, teamMemberships: $teamMemberships, defaultTeamId: $defaultTeamId, preferences: $preferences, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $UserProfileV3CopyWith<$Res>  {
  factory $UserProfileV3CopyWith(UserProfileV3 value, $Res Function(UserProfileV3) _then) = _$UserProfileV3CopyWithImpl;
@useResult
$Res call({
 String userId, String email, String? displayName, String? firstName, String? lastName, String? profileImageUrl, DateTime createdAt, DateTime? updatedAt, List<UserTeamMembership> teamMemberships, String? defaultTeamId, Map<String, dynamic>? preferences, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$UserProfileV3CopyWithImpl<$Res>
    implements $UserProfileV3CopyWith<$Res> {
  _$UserProfileV3CopyWithImpl(this._self, this._then);

  final UserProfileV3 _self;
  final $Res Function(UserProfileV3) _then;

/// Create a copy of UserProfileV3
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? email = null,Object? displayName = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? profileImageUrl = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? teamMemberships = null,Object? defaultTeamId = freezed,Object? preferences = freezed,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,teamMemberships: null == teamMemberships ? _self.teamMemberships : teamMemberships // ignore: cast_nullable_to_non_nullable
as List<UserTeamMembership>,defaultTeamId: freezed == defaultTeamId ? _self.defaultTeamId : defaultTeamId // ignore: cast_nullable_to_non_nullable
as String?,preferences: freezed == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfileV3].
extension UserProfileV3Patterns on UserProfileV3 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfileV3 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfileV3() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfileV3 value)  $default,){
final _that = this;
switch (_that) {
case _UserProfileV3():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfileV3 value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfileV3() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String email,  String? displayName,  String? firstName,  String? lastName,  String? profileImageUrl,  DateTime createdAt,  DateTime? updatedAt,  List<UserTeamMembership> teamMemberships,  String? defaultTeamId,  Map<String, dynamic>? preferences,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfileV3() when $default != null:
return $default(_that.userId,_that.email,_that.displayName,_that.firstName,_that.lastName,_that.profileImageUrl,_that.createdAt,_that.updatedAt,_that.teamMemberships,_that.defaultTeamId,_that.preferences,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String email,  String? displayName,  String? firstName,  String? lastName,  String? profileImageUrl,  DateTime createdAt,  DateTime? updatedAt,  List<UserTeamMembership> teamMemberships,  String? defaultTeamId,  Map<String, dynamic>? preferences,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _UserProfileV3():
return $default(_that.userId,_that.email,_that.displayName,_that.firstName,_that.lastName,_that.profileImageUrl,_that.createdAt,_that.updatedAt,_that.teamMemberships,_that.defaultTeamId,_that.preferences,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String email,  String? displayName,  String? firstName,  String? lastName,  String? profileImageUrl,  DateTime createdAt,  DateTime? updatedAt,  List<UserTeamMembership> teamMemberships,  String? defaultTeamId,  Map<String, dynamic>? preferences,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _UserProfileV3() when $default != null:
return $default(_that.userId,_that.email,_that.displayName,_that.firstName,_that.lastName,_that.profileImageUrl,_that.createdAt,_that.updatedAt,_that.teamMemberships,_that.defaultTeamId,_that.preferences,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfileV3 implements UserProfileV3 {
  const _UserProfileV3({required this.userId, required this.email, this.displayName, this.firstName, this.lastName, this.profileImageUrl, required this.createdAt, this.updatedAt, final  List<UserTeamMembership> teamMemberships = const [], this.defaultTeamId, final  Map<String, dynamic>? preferences, final  Map<String, dynamic>? metadata}): _teamMemberships = teamMemberships,_preferences = preferences,_metadata = metadata;
  factory _UserProfileV3.fromJson(Map<String, dynamic> json) => _$UserProfileV3FromJson(json);

@override final  String userId;
@override final  String email;
@override final  String? displayName;
@override final  String? firstName;
@override final  String? lastName;
@override final  String? profileImageUrl;
@override final  DateTime createdAt;
@override final  DateTime? updatedAt;
 final  List<UserTeamMembership> _teamMemberships;
@override@JsonKey() List<UserTeamMembership> get teamMemberships {
  if (_teamMemberships is EqualUnmodifiableListView) return _teamMemberships;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teamMemberships);
}

@override final  String? defaultTeamId;
 final  Map<String, dynamic>? _preferences;
@override Map<String, dynamic>? get preferences {
  final value = _preferences;
  if (value == null) return null;
  if (_preferences is EqualUnmodifiableMapView) return _preferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of UserProfileV3
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileV3CopyWith<_UserProfileV3> get copyWith => __$UserProfileV3CopyWithImpl<_UserProfileV3>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileV3ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfileV3&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._teamMemberships, _teamMemberships)&&(identical(other.defaultTeamId, defaultTeamId) || other.defaultTeamId == defaultTeamId)&&const DeepCollectionEquality().equals(other._preferences, _preferences)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,email,displayName,firstName,lastName,profileImageUrl,createdAt,updatedAt,const DeepCollectionEquality().hash(_teamMemberships),defaultTeamId,const DeepCollectionEquality().hash(_preferences),const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'UserProfileV3(userId: $userId, email: $email, displayName: $displayName, firstName: $firstName, lastName: $lastName, profileImageUrl: $profileImageUrl, createdAt: $createdAt, updatedAt: $updatedAt, teamMemberships: $teamMemberships, defaultTeamId: $defaultTeamId, preferences: $preferences, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$UserProfileV3CopyWith<$Res> implements $UserProfileV3CopyWith<$Res> {
  factory _$UserProfileV3CopyWith(_UserProfileV3 value, $Res Function(_UserProfileV3) _then) = __$UserProfileV3CopyWithImpl;
@override @useResult
$Res call({
 String userId, String email, String? displayName, String? firstName, String? lastName, String? profileImageUrl, DateTime createdAt, DateTime? updatedAt, List<UserTeamMembership> teamMemberships, String? defaultTeamId, Map<String, dynamic>? preferences, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$UserProfileV3CopyWithImpl<$Res>
    implements _$UserProfileV3CopyWith<$Res> {
  __$UserProfileV3CopyWithImpl(this._self, this._then);

  final _UserProfileV3 _self;
  final $Res Function(_UserProfileV3) _then;

/// Create a copy of UserProfileV3
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? email = null,Object? displayName = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? profileImageUrl = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? teamMemberships = null,Object? defaultTeamId = freezed,Object? preferences = freezed,Object? metadata = freezed,}) {
  return _then(_UserProfileV3(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,teamMemberships: null == teamMemberships ? _self._teamMemberships : teamMemberships // ignore: cast_nullable_to_non_nullable
as List<UserTeamMembership>,defaultTeamId: freezed == defaultTeamId ? _self.defaultTeamId : defaultTeamId // ignore: cast_nullable_to_non_nullable
as String?,preferences: freezed == preferences ? _self._preferences : preferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
