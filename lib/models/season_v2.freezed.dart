// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'season_v2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SeasonV2 {

 String get seasonId; String get userId; String get name; DateTime get startDate; DateTime? get endDate; bool get isActive; SeasonType get type; Map<String, dynamic> get settings;
/// Create a copy of SeasonV2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeasonV2CopyWith<SeasonV2> get copyWith => _$SeasonV2CopyWithImpl<SeasonV2>(this as SeasonV2, _$identity);

  /// Serializes this SeasonV2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeasonV2&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.settings, settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seasonId,userId,name,startDate,endDate,isActive,type,const DeepCollectionEquality().hash(settings));

@override
String toString() {
  return 'SeasonV2(seasonId: $seasonId, userId: $userId, name: $name, startDate: $startDate, endDate: $endDate, isActive: $isActive, type: $type, settings: $settings)';
}


}

/// @nodoc
abstract mixin class $SeasonV2CopyWith<$Res>  {
  factory $SeasonV2CopyWith(SeasonV2 value, $Res Function(SeasonV2) _then) = _$SeasonV2CopyWithImpl;
@useResult
$Res call({
 String seasonId, String userId, String name, DateTime startDate, DateTime? endDate, bool isActive, SeasonType type, Map<String, dynamic> settings
});




}
/// @nodoc
class _$SeasonV2CopyWithImpl<$Res>
    implements $SeasonV2CopyWith<$Res> {
  _$SeasonV2CopyWithImpl(this._self, this._then);

  final SeasonV2 _self;
  final $Res Function(SeasonV2) _then;

/// Create a copy of SeasonV2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seasonId = null,Object? userId = null,Object? name = null,Object? startDate = null,Object? endDate = freezed,Object? isActive = null,Object? type = null,Object? settings = null,}) {
  return _then(_self.copyWith(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SeasonType,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [SeasonV2].
extension SeasonV2Patterns on SeasonV2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeasonV2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeasonV2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeasonV2 value)  $default,){
final _that = this;
switch (_that) {
case _SeasonV2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeasonV2 value)?  $default,){
final _that = this;
switch (_that) {
case _SeasonV2() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String seasonId,  String userId,  String name,  DateTime startDate,  DateTime? endDate,  bool isActive,  SeasonType type,  Map<String, dynamic> settings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeasonV2() when $default != null:
return $default(_that.seasonId,_that.userId,_that.name,_that.startDate,_that.endDate,_that.isActive,_that.type,_that.settings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String seasonId,  String userId,  String name,  DateTime startDate,  DateTime? endDate,  bool isActive,  SeasonType type,  Map<String, dynamic> settings)  $default,) {final _that = this;
switch (_that) {
case _SeasonV2():
return $default(_that.seasonId,_that.userId,_that.name,_that.startDate,_that.endDate,_that.isActive,_that.type,_that.settings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String seasonId,  String userId,  String name,  DateTime startDate,  DateTime? endDate,  bool isActive,  SeasonType type,  Map<String, dynamic> settings)?  $default,) {final _that = this;
switch (_that) {
case _SeasonV2() when $default != null:
return $default(_that.seasonId,_that.userId,_that.name,_that.startDate,_that.endDate,_that.isActive,_that.type,_that.settings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeasonV2 extends SeasonV2 {
  const _SeasonV2({required this.seasonId, required this.userId, required this.name, required this.startDate, this.endDate, this.isActive = true, this.type = SeasonType.regular, final  Map<String, dynamic> settings = const {}}): _settings = settings,super._();
  factory _SeasonV2.fromJson(Map<String, dynamic> json) => _$SeasonV2FromJson(json);

@override final  String seasonId;
@override final  String userId;
@override final  String name;
@override final  DateTime startDate;
@override final  DateTime? endDate;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  SeasonType type;
 final  Map<String, dynamic> _settings;
@override@JsonKey() Map<String, dynamic> get settings {
  if (_settings is EqualUnmodifiableMapView) return _settings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_settings);
}


/// Create a copy of SeasonV2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeasonV2CopyWith<_SeasonV2> get copyWith => __$SeasonV2CopyWithImpl<_SeasonV2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeasonV2ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeasonV2&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._settings, _settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seasonId,userId,name,startDate,endDate,isActive,type,const DeepCollectionEquality().hash(_settings));

@override
String toString() {
  return 'SeasonV2(seasonId: $seasonId, userId: $userId, name: $name, startDate: $startDate, endDate: $endDate, isActive: $isActive, type: $type, settings: $settings)';
}


}

/// @nodoc
abstract mixin class _$SeasonV2CopyWith<$Res> implements $SeasonV2CopyWith<$Res> {
  factory _$SeasonV2CopyWith(_SeasonV2 value, $Res Function(_SeasonV2) _then) = __$SeasonV2CopyWithImpl;
@override @useResult
$Res call({
 String seasonId, String userId, String name, DateTime startDate, DateTime? endDate, bool isActive, SeasonType type, Map<String, dynamic> settings
});




}
/// @nodoc
class __$SeasonV2CopyWithImpl<$Res>
    implements _$SeasonV2CopyWith<$Res> {
  __$SeasonV2CopyWithImpl(this._self, this._then);

  final _SeasonV2 _self;
  final $Res Function(_SeasonV2) _then;

/// Create a copy of SeasonV2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seasonId = null,Object? userId = null,Object? name = null,Object? startDate = null,Object? endDate = freezed,Object? isActive = null,Object? type = null,Object? settings = null,}) {
  return _then(_SeasonV2(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SeasonType,settings: null == settings ? _self._settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
