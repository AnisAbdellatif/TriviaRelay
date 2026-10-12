// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'joinable_game.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JoinableGame {

 String get code;@JsonKey(unknownEnumValue: GameList.public) GameList get list; GamePack? get pack; String? get host; int? get playerCount;@JsonKey(unknownEnumValue: GameStage.playing) GameStage get stage; int? get questionNumber; bool get hasImages;
/// Create a copy of JoinableGame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinableGameCopyWith<JoinableGame> get copyWith => _$JoinableGameCopyWithImpl<JoinableGame>(this as JoinableGame, _$identity);

  /// Serializes this JoinableGame to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as JoinableGame;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinableGame&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.list, _this.list) || other.list == _this.list)&&(identical(other.pack, _this.pack) || other.pack == _this.pack)&&(identical(other.host, _this.host) || other.host == _this.host)&&(identical(other.playerCount, _this.playerCount) || other.playerCount == _this.playerCount)&&(identical(other.stage, _this.stage) || other.stage == _this.stage)&&(identical(other.questionNumber, _this.questionNumber) || other.questionNumber == _this.questionNumber)&&(identical(other.hasImages, _this.hasImages) || other.hasImages == _this.hasImages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JoinableGame;
  return Object.hash(runtimeType,_this.code,_this.list,_this.pack,_this.host,_this.playerCount,_this.stage,_this.questionNumber,_this.hasImages);
}

@override
String toString() {
  final _this = this as JoinableGame;
  return 'JoinableGame(code: ${_this.code}, list: ${_this.list}, pack: ${_this.pack}, host: ${_this.host}, playerCount: ${_this.playerCount}, stage: ${_this.stage}, questionNumber: ${_this.questionNumber}, hasImages: ${_this.hasImages})';
}


}

/// @nodoc
abstract mixin class $JoinableGameCopyWith<$Res>  {
  factory $JoinableGameCopyWith(JoinableGame value, $Res Function(JoinableGame) _then) = _$JoinableGameCopyWithImpl;
@useResult
$Res call({
 String code,@JsonKey(unknownEnumValue: GameList.public) GameList list, GamePack? pack, String? host, int? playerCount,@JsonKey(unknownEnumValue: GameStage.playing) GameStage stage, int? questionNumber, bool hasImages
});


$GamePackCopyWith<$Res>? get pack;

}
/// @nodoc
class _$JoinableGameCopyWithImpl<$Res>
    implements $JoinableGameCopyWith<$Res> {
  _$JoinableGameCopyWithImpl(this._self, this._then);

  final JoinableGame _self;
  final $Res Function(JoinableGame) _then;

/// Create a copy of JoinableGame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? list = null,Object? pack = freezed,Object? host = freezed,Object? playerCount = freezed,Object? stage = null,Object? questionNumber = freezed,Object? hasImages = null,}) {
  return _then(JoinableGame(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as GameList,pack: freezed == pack ? _self.pack : pack // ignore: cast_nullable_to_non_nullable
as GamePack?,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String?,playerCount: freezed == playerCount ? _self.playerCount : playerCount // ignore: cast_nullable_to_non_nullable
as int?,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as GameStage,questionNumber: freezed == questionNumber ? _self.questionNumber : questionNumber // ignore: cast_nullable_to_non_nullable
as int?,hasImages: null == hasImages ? _self.hasImages : hasImages // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of JoinableGame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GamePackCopyWith<$Res>? get pack {
    if (_self.pack == null) {
    return null;
  }

  return $GamePackCopyWith<$Res>(_self.pack!, (value) {
    return _then(_self.copyWith(pack: value));
  });
}
}


/// Adds pattern-matching-related methods to [JoinableGame].
extension JoinableGamePatterns on JoinableGame {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinableGame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinableGame() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinableGame value)  $default,){
final _that = this;
switch (_that) {
case _JoinableGame():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinableGame value)?  $default,){
final _that = this;
switch (_that) {
case _JoinableGame() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code, @JsonKey(unknownEnumValue: GameList.public)  GameList list,  GamePack? pack,  String? host,  int? playerCount, @JsonKey(unknownEnumValue: GameStage.playing)  GameStage stage,  int? questionNumber,  bool hasImages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinableGame() when $default != null:
return $default(_that.code,_that.list,_that.pack,_that.host,_that.playerCount,_that.stage,_that.questionNumber,_that.hasImages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code, @JsonKey(unknownEnumValue: GameList.public)  GameList list,  GamePack? pack,  String? host,  int? playerCount, @JsonKey(unknownEnumValue: GameStage.playing)  GameStage stage,  int? questionNumber,  bool hasImages)  $default,) {final _that = this;
switch (_that) {
case _JoinableGame():
return $default(_that.code,_that.list,_that.pack,_that.host,_that.playerCount,_that.stage,_that.questionNumber,_that.hasImages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code, @JsonKey(unknownEnumValue: GameList.public)  GameList list,  GamePack? pack,  String? host,  int? playerCount, @JsonKey(unknownEnumValue: GameStage.playing)  GameStage stage,  int? questionNumber,  bool hasImages)?  $default,) {final _that = this;
switch (_that) {
case _JoinableGame() when $default != null:
return $default(_that.code,_that.list,_that.pack,_that.host,_that.playerCount,_that.stage,_that.questionNumber,_that.hasImages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JoinableGame extends JoinableGame {
  const _JoinableGame({required this.code, @JsonKey(unknownEnumValue: GameList.public) this.list = GameList.public, this.pack, this.host, this.playerCount, @JsonKey(unknownEnumValue: GameStage.playing) this.stage = GameStage.playing, this.questionNumber, this.hasImages = false}): super._();
  factory _JoinableGame.fromJson(Map<String, dynamic> json) => _$JoinableGameFromJson(json);

@override final  String code;
@override@JsonKey(unknownEnumValue: GameList.public) final  GameList list;
@override final  GamePack? pack;
@override final  String? host;
@override final  int? playerCount;
@override@JsonKey(unknownEnumValue: GameStage.playing) final  GameStage stage;
@override final  int? questionNumber;
@override@JsonKey() final  bool hasImages;

/// Create a copy of JoinableGame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinableGameCopyWith<_JoinableGame> get copyWith => __$JoinableGameCopyWithImpl<_JoinableGame>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JoinableGameToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinableGame&&(identical(other.code, code) || other.code == code)&&(identical(other.list, list) || other.list == list)&&(identical(other.pack, pack) || other.pack == pack)&&(identical(other.host, host) || other.host == host)&&(identical(other.playerCount, playerCount) || other.playerCount == playerCount)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.questionNumber, questionNumber) || other.questionNumber == questionNumber)&&(identical(other.hasImages, hasImages) || other.hasImages == hasImages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,list,pack,host,playerCount,stage,questionNumber,hasImages);
}

@override
String toString() {
    return 'JoinableGame(code: $code, list: $list, pack: $pack, host: $host, playerCount: $playerCount, stage: $stage, questionNumber: $questionNumber, hasImages: $hasImages)';
}


}

/// @nodoc
abstract mixin class _$JoinableGameCopyWith<$Res> implements $JoinableGameCopyWith<$Res> {
  factory _$JoinableGameCopyWith(_JoinableGame value, $Res Function(_JoinableGame) _then) = __$JoinableGameCopyWithImpl;
@override @useResult
$Res call({
 String code,@JsonKey(unknownEnumValue: GameList.public) GameList list, GamePack? pack, String? host, int? playerCount,@JsonKey(unknownEnumValue: GameStage.playing) GameStage stage, int? questionNumber, bool hasImages
});


@override $GamePackCopyWith<$Res>? get pack;

}
/// @nodoc
class __$JoinableGameCopyWithImpl<$Res>
    implements _$JoinableGameCopyWith<$Res> {
  __$JoinableGameCopyWithImpl(this._self, this._then);

  final _JoinableGame _self;
  final $Res Function(_JoinableGame) _then;

/// Create a copy of JoinableGame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? list = null,Object? pack = freezed,Object? host = freezed,Object? playerCount = freezed,Object? stage = null,Object? questionNumber = freezed,Object? hasImages = null,}) {
  return _then(_JoinableGame(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as GameList,pack: freezed == pack ? _self.pack : pack // ignore: cast_nullable_to_non_nullable
as GamePack?,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String?,playerCount: freezed == playerCount ? _self.playerCount : playerCount // ignore: cast_nullable_to_non_nullable
as int?,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as GameStage,questionNumber: freezed == questionNumber ? _self.questionNumber : questionNumber // ignore: cast_nullable_to_non_nullable
as int?,hasImages: null == hasImages ? _self.hasImages : hasImages // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of JoinableGame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GamePackCopyWith<$Res>? get pack {
    if (_self.pack == null) {
    return null;
  }

  return $GamePackCopyWith<$Res>(_self.pack!, (value) {
    return _then(_self.copyWith(pack: value));
  });
}
}


/// @nodoc
mixin _$GamePack {

 int? get id; String get name; String? get description; String? get imageUrl;
/// Create a copy of GamePack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GamePackCopyWith<GamePack> get copyWith => _$GamePackCopyWithImpl<GamePack>(this as GamePack, _$identity);

  /// Serializes this GamePack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GamePack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GamePack&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GamePack;
  return Object.hash(runtimeType,_this.id,_this.name,_this.description,_this.imageUrl);
}

@override
String toString() {
  final _this = this as GamePack;
  return 'GamePack(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, imageUrl: ${_this.imageUrl})';
}


}

/// @nodoc
abstract mixin class $GamePackCopyWith<$Res>  {
  factory $GamePackCopyWith(GamePack value, $Res Function(GamePack) _then) = _$GamePackCopyWithImpl;
@useResult
$Res call({
 int? id, String name, String? description, String? imageUrl
});




}
/// @nodoc
class _$GamePackCopyWithImpl<$Res>
    implements $GamePackCopyWith<$Res> {
  _$GamePackCopyWithImpl(this._self, this._then);

  final GamePack _self;
  final $Res Function(GamePack) _then;

/// Create a copy of GamePack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? description = freezed,Object? imageUrl = freezed,}) {
  return _then(GamePack(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GamePack].
extension GamePackPatterns on GamePack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GamePack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GamePack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GamePack value)  $default,){
final _that = this;
switch (_that) {
case _GamePack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GamePack value)?  $default,){
final _that = this;
switch (_that) {
case _GamePack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String name,  String? description,  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GamePack() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String name,  String? description,  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _GamePack():
return $default(_that.id,_that.name,_that.description,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String name,  String? description,  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _GamePack() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GamePack implements GamePack {
  const _GamePack({this.id, this.name = '', this.description, this.imageUrl});
  factory _GamePack.fromJson(Map<String, dynamic> json) => _$GamePackFromJson(json);

@override final  int? id;
@override@JsonKey() final  String name;
@override final  String? description;
@override final  String? imageUrl;

/// Create a copy of GamePack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GamePackCopyWith<_GamePack> get copyWith => __$GamePackCopyWithImpl<_GamePack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GamePackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GamePack&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,description,imageUrl);
}

@override
String toString() {
    return 'GamePack(id: $id, name: $name, description: $description, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$GamePackCopyWith<$Res> implements $GamePackCopyWith<$Res> {
  factory _$GamePackCopyWith(_GamePack value, $Res Function(_GamePack) _then) = __$GamePackCopyWithImpl;
@override @useResult
$Res call({
 int? id, String name, String? description, String? imageUrl
});




}
/// @nodoc
class __$GamePackCopyWithImpl<$Res>
    implements _$GamePackCopyWith<$Res> {
  __$GamePackCopyWithImpl(this._self, this._then);

  final _GamePack _self;
  final $Res Function(_GamePack) _then;

/// Create a copy of GamePack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? description = freezed,Object? imageUrl = freezed,}) {
  return _then(_GamePack(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
