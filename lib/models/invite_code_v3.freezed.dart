// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_code_v3.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InviteCodeV3 {

 String get code; String get teamId; InviteRole get role; DateTime get expiresAt; bool get active; int get uses; int get maxUses; DateTime get createdAt; String? get createdBy;// user ID
 Map<String, dynamic>? get metadata;
/// Create a copy of InviteCodeV3
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteCodeV3CopyWith<InviteCodeV3> get copyWith => _$InviteCodeV3CopyWithImpl<InviteCodeV3>(this as InviteCodeV3, _$identity);

  /// Serializes this InviteCodeV3 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteCodeV3&&(identical(other.code, code) || other.code == code)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.role, role) || other.role == role)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.active, active) || other.active == active)&&(identical(other.uses, uses) || other.uses == uses)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,teamId,role,expiresAt,active,uses,maxUses,createdAt,createdBy,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'InviteCodeV3(code: $code, teamId: $teamId, role: $role, expiresAt: $expiresAt, active: $active, uses: $uses, maxUses: $maxUses, createdAt: $createdAt, createdBy: $createdBy, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $InviteCodeV3CopyWith<$Res>  {
  factory $InviteCodeV3CopyWith(InviteCodeV3 value, $Res Function(InviteCodeV3) _then) = _$InviteCodeV3CopyWithImpl;
@useResult
$Res call({
 String code, String teamId, InviteRole role, DateTime expiresAt, bool active, int uses, int maxUses, DateTime createdAt, String? createdBy, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$InviteCodeV3CopyWithImpl<$Res>
    implements $InviteCodeV3CopyWith<$Res> {
  _$InviteCodeV3CopyWithImpl(this._self, this._then);

  final InviteCodeV3 _self;
  final $Res Function(InviteCodeV3) _then;

/// Create a copy of InviteCodeV3
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? teamId = null,Object? role = null,Object? expiresAt = null,Object? active = null,Object? uses = null,Object? maxUses = null,Object? createdAt = null,Object? createdBy = freezed,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as InviteRole,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,uses: null == uses ? _self.uses : uses // ignore: cast_nullable_to_non_nullable
as int,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteCodeV3].
extension InviteCodeV3Patterns on InviteCodeV3 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteCodeV3 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteCodeV3() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteCodeV3 value)  $default,){
final _that = this;
switch (_that) {
case _InviteCodeV3():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteCodeV3 value)?  $default,){
final _that = this;
switch (_that) {
case _InviteCodeV3() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String teamId,  InviteRole role,  DateTime expiresAt,  bool active,  int uses,  int maxUses,  DateTime createdAt,  String? createdBy,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteCodeV3() when $default != null:
return $default(_that.code,_that.teamId,_that.role,_that.expiresAt,_that.active,_that.uses,_that.maxUses,_that.createdAt,_that.createdBy,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String teamId,  InviteRole role,  DateTime expiresAt,  bool active,  int uses,  int maxUses,  DateTime createdAt,  String? createdBy,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _InviteCodeV3():
return $default(_that.code,_that.teamId,_that.role,_that.expiresAt,_that.active,_that.uses,_that.maxUses,_that.createdAt,_that.createdBy,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String teamId,  InviteRole role,  DateTime expiresAt,  bool active,  int uses,  int maxUses,  DateTime createdAt,  String? createdBy,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _InviteCodeV3() when $default != null:
return $default(_that.code,_that.teamId,_that.role,_that.expiresAt,_that.active,_that.uses,_that.maxUses,_that.createdAt,_that.createdBy,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InviteCodeV3 implements InviteCodeV3 {
  const _InviteCodeV3({required this.code, required this.teamId, required this.role, required this.expiresAt, this.active = true, this.uses = 0, this.maxUses = 0, required this.createdAt, this.createdBy, final  Map<String, dynamic>? metadata}): _metadata = metadata;
  factory _InviteCodeV3.fromJson(Map<String, dynamic> json) => _$InviteCodeV3FromJson(json);

@override final  String code;
@override final  String teamId;
@override final  InviteRole role;
@override final  DateTime expiresAt;
@override@JsonKey() final  bool active;
@override@JsonKey() final  int uses;
@override@JsonKey() final  int maxUses;
@override final  DateTime createdAt;
@override final  String? createdBy;
// user ID
 final  Map<String, dynamic>? _metadata;
// user ID
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of InviteCodeV3
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteCodeV3CopyWith<_InviteCodeV3> get copyWith => __$InviteCodeV3CopyWithImpl<_InviteCodeV3>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InviteCodeV3ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteCodeV3&&(identical(other.code, code) || other.code == code)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.role, role) || other.role == role)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.active, active) || other.active == active)&&(identical(other.uses, uses) || other.uses == uses)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,teamId,role,expiresAt,active,uses,maxUses,createdAt,createdBy,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'InviteCodeV3(code: $code, teamId: $teamId, role: $role, expiresAt: $expiresAt, active: $active, uses: $uses, maxUses: $maxUses, createdAt: $createdAt, createdBy: $createdBy, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$InviteCodeV3CopyWith<$Res> implements $InviteCodeV3CopyWith<$Res> {
  factory _$InviteCodeV3CopyWith(_InviteCodeV3 value, $Res Function(_InviteCodeV3) _then) = __$InviteCodeV3CopyWithImpl;
@override @useResult
$Res call({
 String code, String teamId, InviteRole role, DateTime expiresAt, bool active, int uses, int maxUses, DateTime createdAt, String? createdBy, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$InviteCodeV3CopyWithImpl<$Res>
    implements _$InviteCodeV3CopyWith<$Res> {
  __$InviteCodeV3CopyWithImpl(this._self, this._then);

  final _InviteCodeV3 _self;
  final $Res Function(_InviteCodeV3) _then;

/// Create a copy of InviteCodeV3
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? teamId = null,Object? role = null,Object? expiresAt = null,Object? active = null,Object? uses = null,Object? maxUses = null,Object? createdAt = null,Object? createdBy = freezed,Object? metadata = freezed,}) {
  return _then(_InviteCodeV3(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as InviteRole,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,uses: null == uses ? _self.uses : uses // ignore: cast_nullable_to_non_nullable
as int,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
