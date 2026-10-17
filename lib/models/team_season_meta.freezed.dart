// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_season_meta.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TeamSeasonMeta {

 String get seasonId; String get teamId; String get name; DateTime get startDate; DateTime? get endDate; bool get isActive; int get gamesCount; DateTime? get lastUpdated;
/// Create a copy of TeamSeasonMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamSeasonMetaCopyWith<TeamSeasonMeta> get copyWith => _$TeamSeasonMetaCopyWithImpl<TeamSeasonMeta>(this as TeamSeasonMeta, _$identity);

  /// Serializes this TeamSeasonMeta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamSeasonMeta&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.gamesCount, gamesCount) || other.gamesCount == gamesCount)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seasonId,teamId,name,startDate,endDate,isActive,gamesCount,lastUpdated);

@override
String toString() {
  return 'TeamSeasonMeta(seasonId: $seasonId, teamId: $teamId, name: $name, startDate: $startDate, endDate: $endDate, isActive: $isActive, gamesCount: $gamesCount, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class $TeamSeasonMetaCopyWith<$Res>  {
  factory $TeamSeasonMetaCopyWith(TeamSeasonMeta value, $Res Function(TeamSeasonMeta) _then) = _$TeamSeasonMetaCopyWithImpl;
@useResult
$Res call({
 String seasonId, String teamId, String name, DateTime startDate, DateTime? endDate, bool isActive, int gamesCount, DateTime? lastUpdated
});




}
/// @nodoc
class _$TeamSeasonMetaCopyWithImpl<$Res>
    implements $TeamSeasonMetaCopyWith<$Res> {
  _$TeamSeasonMetaCopyWithImpl(this._self, this._then);

  final TeamSeasonMeta _self;
  final $Res Function(TeamSeasonMeta) _then;

/// Create a copy of TeamSeasonMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seasonId = null,Object? teamId = null,Object? name = null,Object? startDate = null,Object? endDate = freezed,Object? isActive = null,Object? gamesCount = null,Object? lastUpdated = freezed,}) {
  return _then(_self.copyWith(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,gamesCount: null == gamesCount ? _self.gamesCount : gamesCount // ignore: cast_nullable_to_non_nullable
as int,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamSeasonMeta].
extension TeamSeasonMetaPatterns on TeamSeasonMeta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamSeasonMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamSeasonMeta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamSeasonMeta value)  $default,){
final _that = this;
switch (_that) {
case _TeamSeasonMeta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamSeasonMeta value)?  $default,){
final _that = this;
switch (_that) {
case _TeamSeasonMeta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String seasonId,  String teamId,  String name,  DateTime startDate,  DateTime? endDate,  bool isActive,  int gamesCount,  DateTime? lastUpdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamSeasonMeta() when $default != null:
return $default(_that.seasonId,_that.teamId,_that.name,_that.startDate,_that.endDate,_that.isActive,_that.gamesCount,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String seasonId,  String teamId,  String name,  DateTime startDate,  DateTime? endDate,  bool isActive,  int gamesCount,  DateTime? lastUpdated)  $default,) {final _that = this;
switch (_that) {
case _TeamSeasonMeta():
return $default(_that.seasonId,_that.teamId,_that.name,_that.startDate,_that.endDate,_that.isActive,_that.gamesCount,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String seasonId,  String teamId,  String name,  DateTime startDate,  DateTime? endDate,  bool isActive,  int gamesCount,  DateTime? lastUpdated)?  $default,) {final _that = this;
switch (_that) {
case _TeamSeasonMeta() when $default != null:
return $default(_that.seasonId,_that.teamId,_that.name,_that.startDate,_that.endDate,_that.isActive,_that.gamesCount,_that.lastUpdated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamSeasonMeta implements TeamSeasonMeta {
  const _TeamSeasonMeta({required this.seasonId, required this.teamId, required this.name, required this.startDate, this.endDate, this.isActive = true, this.gamesCount = 0, this.lastUpdated});
  factory _TeamSeasonMeta.fromJson(Map<String, dynamic> json) => _$TeamSeasonMetaFromJson(json);

@override final  String seasonId;
@override final  String teamId;
@override final  String name;
@override final  DateTime startDate;
@override final  DateTime? endDate;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  int gamesCount;
@override final  DateTime? lastUpdated;

/// Create a copy of TeamSeasonMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamSeasonMetaCopyWith<_TeamSeasonMeta> get copyWith => __$TeamSeasonMetaCopyWithImpl<_TeamSeasonMeta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamSeasonMetaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamSeasonMeta&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.gamesCount, gamesCount) || other.gamesCount == gamesCount)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seasonId,teamId,name,startDate,endDate,isActive,gamesCount,lastUpdated);

@override
String toString() {
  return 'TeamSeasonMeta(seasonId: $seasonId, teamId: $teamId, name: $name, startDate: $startDate, endDate: $endDate, isActive: $isActive, gamesCount: $gamesCount, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class _$TeamSeasonMetaCopyWith<$Res> implements $TeamSeasonMetaCopyWith<$Res> {
  factory _$TeamSeasonMetaCopyWith(_TeamSeasonMeta value, $Res Function(_TeamSeasonMeta) _then) = __$TeamSeasonMetaCopyWithImpl;
@override @useResult
$Res call({
 String seasonId, String teamId, String name, DateTime startDate, DateTime? endDate, bool isActive, int gamesCount, DateTime? lastUpdated
});




}
/// @nodoc
class __$TeamSeasonMetaCopyWithImpl<$Res>
    implements _$TeamSeasonMetaCopyWith<$Res> {
  __$TeamSeasonMetaCopyWithImpl(this._self, this._then);

  final _TeamSeasonMeta _self;
  final $Res Function(_TeamSeasonMeta) _then;

/// Create a copy of TeamSeasonMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seasonId = null,Object? teamId = null,Object? name = null,Object? startDate = null,Object? endDate = freezed,Object? isActive = null,Object? gamesCount = null,Object? lastUpdated = freezed,}) {
  return _then(_TeamSeasonMeta(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,gamesCount: null == gamesCount ? _self.gamesCount : gamesCount // ignore: cast_nullable_to_non_nullable
as int,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
