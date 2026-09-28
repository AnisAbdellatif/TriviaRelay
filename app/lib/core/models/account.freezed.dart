// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SporcleAccount {

 String get playerId; String get token; String get handle; String get deviceId;
/// Create a copy of SporcleAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SporcleAccountCopyWith<SporcleAccount> get copyWith => _$SporcleAccountCopyWithImpl<SporcleAccount>(this as SporcleAccount, _$identity);

  /// Serializes this SporcleAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SporcleAccount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SporcleAccount&&(identical(other.playerId, _this.playerId) || other.playerId == _this.playerId)&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.handle, _this.handle) || other.handle == _this.handle)&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SporcleAccount;
  return Object.hash(runtimeType,_this.playerId,_this.token,_this.handle,_this.deviceId);
}

@override
String toString() {
  final _this = this as SporcleAccount;
  return 'SporcleAccount(playerId: ${_this.playerId}, token: ${_this.token}, handle: ${_this.handle}, deviceId: ${_this.deviceId})';
}


}

/// @nodoc
abstract mixin class $SporcleAccountCopyWith<$Res>  {
  factory $SporcleAccountCopyWith(SporcleAccount value, $Res Function(SporcleAccount) _then) = _$SporcleAccountCopyWithImpl;
@useResult
$Res call({
 String playerId, String token, String handle, String deviceId
});




}
/// @nodoc
class _$SporcleAccountCopyWithImpl<$Res>
    implements $SporcleAccountCopyWith<$Res> {
  _$SporcleAccountCopyWithImpl(this._self, this._then);

  final SporcleAccount _self;
  final $Res Function(SporcleAccount) _then;

/// Create a copy of SporcleAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? token = null,Object? handle = null,Object? deviceId = null,}) {
  return _then(SporcleAccount(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SporcleAccount].
extension SporcleAccountPatterns on SporcleAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SporcleAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SporcleAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SporcleAccount value)  $default,){
final _that = this;
switch (_that) {
case _SporcleAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SporcleAccount value)?  $default,){
final _that = this;
switch (_that) {
case _SporcleAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  String token,  String handle,  String deviceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SporcleAccount() when $default != null:
return $default(_that.playerId,_that.token,_that.handle,_that.deviceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  String token,  String handle,  String deviceId)  $default,) {final _that = this;
switch (_that) {
case _SporcleAccount():
return $default(_that.playerId,_that.token,_that.handle,_that.deviceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  String token,  String handle,  String deviceId)?  $default,) {final _that = this;
switch (_that) {
case _SporcleAccount() when $default != null:
return $default(_that.playerId,_that.token,_that.handle,_that.deviceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SporcleAccount extends SporcleAccount {
  const _SporcleAccount({required this.playerId, required this.token, required this.handle, required this.deviceId}): super._();
  factory _SporcleAccount.fromJson(Map<String, dynamic> json) => _$SporcleAccountFromJson(json);

@override final  String playerId;
@override final  String token;
@override final  String handle;
@override final  String deviceId;

/// Create a copy of SporcleAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SporcleAccountCopyWith<_SporcleAccount> get copyWith => __$SporcleAccountCopyWithImpl<_SporcleAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SporcleAccountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SporcleAccount&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.token, token) || other.token == token)&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,playerId,token,handle,deviceId);
}

@override
String toString() {
    return 'SporcleAccount(playerId: $playerId, token: $token, handle: $handle, deviceId: $deviceId)';
}


}

/// @nodoc
abstract mixin class _$SporcleAccountCopyWith<$Res> implements $SporcleAccountCopyWith<$Res> {
  factory _$SporcleAccountCopyWith(_SporcleAccount value, $Res Function(_SporcleAccount) _then) = __$SporcleAccountCopyWithImpl;
@override @useResult
$Res call({
 String playerId, String token, String handle, String deviceId
});




}
/// @nodoc
class __$SporcleAccountCopyWithImpl<$Res>
    implements _$SporcleAccountCopyWith<$Res> {
  __$SporcleAccountCopyWithImpl(this._self, this._then);

  final _SporcleAccount _self;
  final $Res Function(_SporcleAccount) _then;

/// Create a copy of SporcleAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? token = null,Object? handle = null,Object? deviceId = null,}) {
  return _then(_SporcleAccount(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SeatTicket {

 String get seatId; String get seatToken; String get gameCode;
/// Create a copy of SeatTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeatTicketCopyWith<SeatTicket> get copyWith => _$SeatTicketCopyWithImpl<SeatTicket>(this as SeatTicket, _$identity);

  /// Serializes this SeatTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SeatTicket;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeatTicket&&(identical(other.seatId, _this.seatId) || other.seatId == _this.seatId)&&(identical(other.seatToken, _this.seatToken) || other.seatToken == _this.seatToken)&&(identical(other.gameCode, _this.gameCode) || other.gameCode == _this.gameCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SeatTicket;
  return Object.hash(runtimeType,_this.seatId,_this.seatToken,_this.gameCode);
}

@override
String toString() {
  final _this = this as SeatTicket;
  return 'SeatTicket(seatId: ${_this.seatId}, seatToken: ${_this.seatToken}, gameCode: ${_this.gameCode})';
}


}

/// @nodoc
abstract mixin class $SeatTicketCopyWith<$Res>  {
  factory $SeatTicketCopyWith(SeatTicket value, $Res Function(SeatTicket) _then) = _$SeatTicketCopyWithImpl;
@useResult
$Res call({
 String seatId, String seatToken, String gameCode
});




}
/// @nodoc
class _$SeatTicketCopyWithImpl<$Res>
    implements $SeatTicketCopyWith<$Res> {
  _$SeatTicketCopyWithImpl(this._self, this._then);

  final SeatTicket _self;
  final $Res Function(SeatTicket) _then;

/// Create a copy of SeatTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seatId = null,Object? seatToken = null,Object? gameCode = null,}) {
  return _then(SeatTicket(
seatId: null == seatId ? _self.seatId : seatId // ignore: cast_nullable_to_non_nullable
as String,seatToken: null == seatToken ? _self.seatToken : seatToken // ignore: cast_nullable_to_non_nullable
as String,gameCode: null == gameCode ? _self.gameCode : gameCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SeatTicket].
extension SeatTicketPatterns on SeatTicket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeatTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeatTicket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeatTicket value)  $default,){
final _that = this;
switch (_that) {
case _SeatTicket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeatTicket value)?  $default,){
final _that = this;
switch (_that) {
case _SeatTicket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String seatId,  String seatToken,  String gameCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeatTicket() when $default != null:
return $default(_that.seatId,_that.seatToken,_that.gameCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String seatId,  String seatToken,  String gameCode)  $default,) {final _that = this;
switch (_that) {
case _SeatTicket():
return $default(_that.seatId,_that.seatToken,_that.gameCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String seatId,  String seatToken,  String gameCode)?  $default,) {final _that = this;
switch (_that) {
case _SeatTicket() when $default != null:
return $default(_that.seatId,_that.seatToken,_that.gameCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeatTicket implements SeatTicket {
  const _SeatTicket({required this.seatId, required this.seatToken, required this.gameCode});
  factory _SeatTicket.fromJson(Map<String, dynamic> json) => _$SeatTicketFromJson(json);

@override final  String seatId;
@override final  String seatToken;
@override final  String gameCode;

/// Create a copy of SeatTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeatTicketCopyWith<_SeatTicket> get copyWith => __$SeatTicketCopyWithImpl<_SeatTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeatTicketToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeatTicket&&(identical(other.seatId, seatId) || other.seatId == seatId)&&(identical(other.seatToken, seatToken) || other.seatToken == seatToken)&&(identical(other.gameCode, gameCode) || other.gameCode == gameCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seatId,seatToken,gameCode);
}

@override
String toString() {
    return 'SeatTicket(seatId: $seatId, seatToken: $seatToken, gameCode: $gameCode)';
}


}

/// @nodoc
abstract mixin class _$SeatTicketCopyWith<$Res> implements $SeatTicketCopyWith<$Res> {
  factory _$SeatTicketCopyWith(_SeatTicket value, $Res Function(_SeatTicket) _then) = __$SeatTicketCopyWithImpl;
@override @useResult
$Res call({
 String seatId, String seatToken, String gameCode
});




}
/// @nodoc
class __$SeatTicketCopyWithImpl<$Res>
    implements _$SeatTicketCopyWith<$Res> {
  __$SeatTicketCopyWithImpl(this._self, this._then);

  final _SeatTicket _self;
  final $Res Function(_SeatTicket) _then;

/// Create a copy of SeatTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seatId = null,Object? seatToken = null,Object? gameCode = null,}) {
  return _then(_SeatTicket(
seatId: null == seatId ? _self.seatId : seatId // ignore: cast_nullable_to_non_nullable
as String,seatToken: null == seatToken ? _self.seatToken : seatToken // ignore: cast_nullable_to_non_nullable
as String,gameCode: null == gameCode ? _self.gameCode : gameCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PackSummary {

 int get id; String get name; String? get description; String? get imageUrl; int? get numQuestions; bool get hasImages; int? get playCount;
/// Create a copy of PackSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackSummaryCopyWith<PackSummary> get copyWith => _$PackSummaryCopyWithImpl<PackSummary>(this as PackSummary, _$identity);

  /// Serializes this PackSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PackSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PackSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.numQuestions, _this.numQuestions) || other.numQuestions == _this.numQuestions)&&(identical(other.hasImages, _this.hasImages) || other.hasImages == _this.hasImages)&&(identical(other.playCount, _this.playCount) || other.playCount == _this.playCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PackSummary;
  return Object.hash(runtimeType,_this.id,_this.name,_this.description,_this.imageUrl,_this.numQuestions,_this.hasImages,_this.playCount);
}

@override
String toString() {
  final _this = this as PackSummary;
  return 'PackSummary(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, imageUrl: ${_this.imageUrl}, numQuestions: ${_this.numQuestions}, hasImages: ${_this.hasImages}, playCount: ${_this.playCount})';
}


}

/// @nodoc
abstract mixin class $PackSummaryCopyWith<$Res>  {
  factory $PackSummaryCopyWith(PackSummary value, $Res Function(PackSummary) _then) = _$PackSummaryCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? description, String? imageUrl, int? numQuestions, bool hasImages, int? playCount
});




}
/// @nodoc
class _$PackSummaryCopyWithImpl<$Res>
    implements $PackSummaryCopyWith<$Res> {
  _$PackSummaryCopyWithImpl(this._self, this._then);

  final PackSummary _self;
  final $Res Function(PackSummary) _then;

/// Create a copy of PackSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? imageUrl = freezed,Object? numQuestions = freezed,Object? hasImages = null,Object? playCount = freezed,}) {
  return _then(PackSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,numQuestions: freezed == numQuestions ? _self.numQuestions : numQuestions // ignore: cast_nullable_to_non_nullable
as int?,hasImages: null == hasImages ? _self.hasImages : hasImages // ignore: cast_nullable_to_non_nullable
as bool,playCount: freezed == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PackSummary].
extension PackSummaryPatterns on PackSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PackSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PackSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PackSummary value)  $default,){
final _that = this;
switch (_that) {
case _PackSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PackSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PackSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? description,  String? imageUrl,  int? numQuestions,  bool hasImages,  int? playCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PackSummary() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.imageUrl,_that.numQuestions,_that.hasImages,_that.playCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? description,  String? imageUrl,  int? numQuestions,  bool hasImages,  int? playCount)  $default,) {final _that = this;
switch (_that) {
case _PackSummary():
return $default(_that.id,_that.name,_that.description,_that.imageUrl,_that.numQuestions,_that.hasImages,_that.playCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? description,  String? imageUrl,  int? numQuestions,  bool hasImages,  int? playCount)?  $default,) {final _that = this;
switch (_that) {
case _PackSummary() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.imageUrl,_that.numQuestions,_that.hasImages,_that.playCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PackSummary implements PackSummary {
  const _PackSummary({required this.id, required this.name, this.description, this.imageUrl, this.numQuestions, this.hasImages = false, this.playCount});
  factory _PackSummary.fromJson(Map<String, dynamic> json) => _$PackSummaryFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? description;
@override final  String? imageUrl;
@override final  int? numQuestions;
@override@JsonKey() final  bool hasImages;
@override final  int? playCount;

/// Create a copy of PackSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackSummaryCopyWith<_PackSummary> get copyWith => __$PackSummaryCopyWithImpl<_PackSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PackSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PackSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.numQuestions, numQuestions) || other.numQuestions == numQuestions)&&(identical(other.hasImages, hasImages) || other.hasImages == hasImages)&&(identical(other.playCount, playCount) || other.playCount == playCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,description,imageUrl,numQuestions,hasImages,playCount);
}

@override
String toString() {
    return 'PackSummary(id: $id, name: $name, description: $description, imageUrl: $imageUrl, numQuestions: $numQuestions, hasImages: $hasImages, playCount: $playCount)';
}


}

/// @nodoc
abstract mixin class _$PackSummaryCopyWith<$Res> implements $PackSummaryCopyWith<$Res> {
  factory _$PackSummaryCopyWith(_PackSummary value, $Res Function(_PackSummary) _then) = __$PackSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? description, String? imageUrl, int? numQuestions, bool hasImages, int? playCount
});




}
/// @nodoc
class __$PackSummaryCopyWithImpl<$Res>
    implements _$PackSummaryCopyWith<$Res> {
  __$PackSummaryCopyWithImpl(this._self, this._then);

  final _PackSummary _self;
  final $Res Function(_PackSummary) _then;

/// Create a copy of PackSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? imageUrl = freezed,Object? numQuestions = freezed,Object? hasImages = null,Object? playCount = freezed,}) {
  return _then(_PackSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,numQuestions: freezed == numQuestions ? _self.numQuestions : numQuestions // ignore: cast_nullable_to_non_nullable
as int?,hasImages: null == hasImages ? _self.hasImages : hasImages // ignore: cast_nullable_to_non_nullable
as bool,playCount: freezed == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$HostOptions {

 int get questionsPerGame; int get questionSeconds; Audience get audience;
/// Create a copy of HostOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HostOptionsCopyWith<HostOptions> get copyWith => _$HostOptionsCopyWithImpl<HostOptions>(this as HostOptions, _$identity);

  /// Serializes this HostOptions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HostOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HostOptions&&(identical(other.questionsPerGame, _this.questionsPerGame) || other.questionsPerGame == _this.questionsPerGame)&&(identical(other.questionSeconds, _this.questionSeconds) || other.questionSeconds == _this.questionSeconds)&&(identical(other.audience, _this.audience) || other.audience == _this.audience));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HostOptions;
  return Object.hash(runtimeType,_this.questionsPerGame,_this.questionSeconds,_this.audience);
}

@override
String toString() {
  final _this = this as HostOptions;
  return 'HostOptions(questionsPerGame: ${_this.questionsPerGame}, questionSeconds: ${_this.questionSeconds}, audience: ${_this.audience})';
}


}

/// @nodoc
abstract mixin class $HostOptionsCopyWith<$Res>  {
  factory $HostOptionsCopyWith(HostOptions value, $Res Function(HostOptions) _then) = _$HostOptionsCopyWithImpl;
@useResult
$Res call({
 int questionsPerGame, int questionSeconds, Audience audience
});




}
/// @nodoc
class _$HostOptionsCopyWithImpl<$Res>
    implements $HostOptionsCopyWith<$Res> {
  _$HostOptionsCopyWithImpl(this._self, this._then);

  final HostOptions _self;
  final $Res Function(HostOptions) _then;

/// Create a copy of HostOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionsPerGame = null,Object? questionSeconds = null,Object? audience = null,}) {
  return _then(HostOptions(
questionsPerGame: null == questionsPerGame ? _self.questionsPerGame : questionsPerGame // ignore: cast_nullable_to_non_nullable
as int,questionSeconds: null == questionSeconds ? _self.questionSeconds : questionSeconds // ignore: cast_nullable_to_non_nullable
as int,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as Audience,
  ));
}

}


/// Adds pattern-matching-related methods to [HostOptions].
extension HostOptionsPatterns on HostOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HostOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HostOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HostOptions value)  $default,){
final _that = this;
switch (_that) {
case _HostOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HostOptions value)?  $default,){
final _that = this;
switch (_that) {
case _HostOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int questionsPerGame,  int questionSeconds,  Audience audience)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HostOptions() when $default != null:
return $default(_that.questionsPerGame,_that.questionSeconds,_that.audience);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int questionsPerGame,  int questionSeconds,  Audience audience)  $default,) {final _that = this;
switch (_that) {
case _HostOptions():
return $default(_that.questionsPerGame,_that.questionSeconds,_that.audience);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int questionsPerGame,  int questionSeconds,  Audience audience)?  $default,) {final _that = this;
switch (_that) {
case _HostOptions() when $default != null:
return $default(_that.questionsPerGame,_that.questionSeconds,_that.audience);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HostOptions implements HostOptions {
  const _HostOptions({this.questionsPerGame = 10, this.questionSeconds = 30, this.audience = Audience.private});
  factory _HostOptions.fromJson(Map<String, dynamic> json) => _$HostOptionsFromJson(json);

@override@JsonKey() final  int questionsPerGame;
@override@JsonKey() final  int questionSeconds;
@override@JsonKey() final  Audience audience;

/// Create a copy of HostOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HostOptionsCopyWith<_HostOptions> get copyWith => __$HostOptionsCopyWithImpl<_HostOptions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HostOptionsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HostOptions&&(identical(other.questionsPerGame, questionsPerGame) || other.questionsPerGame == questionsPerGame)&&(identical(other.questionSeconds, questionSeconds) || other.questionSeconds == questionSeconds)&&(identical(other.audience, audience) || other.audience == audience));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,questionsPerGame,questionSeconds,audience);
}

@override
String toString() {
    return 'HostOptions(questionsPerGame: $questionsPerGame, questionSeconds: $questionSeconds, audience: $audience)';
}


}

/// @nodoc
abstract mixin class _$HostOptionsCopyWith<$Res> implements $HostOptionsCopyWith<$Res> {
  factory _$HostOptionsCopyWith(_HostOptions value, $Res Function(_HostOptions) _then) = __$HostOptionsCopyWithImpl;
@override @useResult
$Res call({
 int questionsPerGame, int questionSeconds, Audience audience
});




}
/// @nodoc
class __$HostOptionsCopyWithImpl<$Res>
    implements _$HostOptionsCopyWith<$Res> {
  __$HostOptionsCopyWithImpl(this._self, this._then);

  final _HostOptions _self;
  final $Res Function(_HostOptions) _then;

/// Create a copy of HostOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionsPerGame = null,Object? questionSeconds = null,Object? audience = null,}) {
  return _then(_HostOptions(
questionsPerGame: null == questionsPerGame ? _self.questionsPerGame : questionsPerGame // ignore: cast_nullable_to_non_nullable
as int,questionSeconds: null == questionSeconds ? _self.questionSeconds : questionSeconds // ignore: cast_nullable_to_non_nullable
as int,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as Audience,
  ));
}


}

// dart format on
