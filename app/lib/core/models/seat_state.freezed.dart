// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'seat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SeatState {

 int get protocolVersion; int get protocolMinor; int get serverTime; String get gameCode; SeatStatus get status; Phase get phase; Pack? get pack; GameOptions get options; List<RoundInfo> get rounds; Question? get question; int? get deadline; List<PlayerView> get players; You get you; Reveal? get reveal;@JsonKey(name: 'final') FinalRound? get finalRound;/// Something to tell the player for a moment (since 1.2).
 Notice? get notice;/// The count down before the open question shows (since 1.2).
 StartCountdown? get countdown;/// The lobby's pack votes, the most voted first (since 1.2).
 List<PackVote> get packVotes;/// The game's chat (since 1.2).
 ChatState get chat;/// Reactions other players sent this one, while they show (since 1.2).
 List<Reaction> get reactions;
/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeatStateCopyWith<SeatState> get copyWith => _$SeatStateCopyWithImpl<SeatState>(this as SeatState, _$identity);

  /// Serializes this SeatState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SeatState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeatState&&(identical(other.protocolVersion, _this.protocolVersion) || other.protocolVersion == _this.protocolVersion)&&(identical(other.protocolMinor, _this.protocolMinor) || other.protocolMinor == _this.protocolMinor)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime)&&(identical(other.gameCode, _this.gameCode) || other.gameCode == _this.gameCode)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.pack, _this.pack) || other.pack == _this.pack)&&(identical(other.options, _this.options) || other.options == _this.options)&&const DeepCollectionEquality().equals(other.rounds, _this.rounds)&&(identical(other.question, _this.question) || other.question == _this.question)&&(identical(other.deadline, _this.deadline) || other.deadline == _this.deadline)&&const DeepCollectionEquality().equals(other.players, _this.players)&&(identical(other.you, _this.you) || other.you == _this.you)&&(identical(other.reveal, _this.reveal) || other.reveal == _this.reveal)&&(identical(other.finalRound, _this.finalRound) || other.finalRound == _this.finalRound)&&(identical(other.notice, _this.notice) || other.notice == _this.notice)&&(identical(other.countdown, _this.countdown) || other.countdown == _this.countdown)&&const DeepCollectionEquality().equals(other.packVotes, _this.packVotes)&&(identical(other.chat, _this.chat) || other.chat == _this.chat)&&const DeepCollectionEquality().equals(other.reactions, _this.reactions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SeatState;
  return Object.hashAll([runtimeType,_this.protocolVersion,_this.protocolMinor,_this.serverTime,_this.gameCode,_this.status,_this.phase,_this.pack,_this.options,const DeepCollectionEquality().hash(_this.rounds),_this.question,_this.deadline,const DeepCollectionEquality().hash(_this.players),_this.you,_this.reveal,_this.finalRound,_this.notice,_this.countdown,const DeepCollectionEquality().hash(_this.packVotes),_this.chat,const DeepCollectionEquality().hash(_this.reactions)]);
}

@override
String toString() {
  final _this = this as SeatState;
  return 'SeatState(protocolVersion: ${_this.protocolVersion}, protocolMinor: ${_this.protocolMinor}, serverTime: ${_this.serverTime}, gameCode: ${_this.gameCode}, status: ${_this.status}, phase: ${_this.phase}, pack: ${_this.pack}, options: ${_this.options}, rounds: ${_this.rounds}, question: ${_this.question}, deadline: ${_this.deadline}, players: ${_this.players}, you: ${_this.you}, reveal: ${_this.reveal}, finalRound: ${_this.finalRound}, notice: ${_this.notice}, countdown: ${_this.countdown}, packVotes: ${_this.packVotes}, chat: ${_this.chat}, reactions: ${_this.reactions})';
}


}

/// @nodoc
abstract mixin class $SeatStateCopyWith<$Res>  {
  factory $SeatStateCopyWith(SeatState value, $Res Function(SeatState) _then) = _$SeatStateCopyWithImpl;
@useResult
$Res call({
 int protocolVersion, int protocolMinor, int serverTime, String gameCode, SeatStatus status, Phase phase, Pack? pack, GameOptions options, List<RoundInfo> rounds, Question? question, int? deadline, List<PlayerView> players, You you, Reveal? reveal,@JsonKey(name: 'final') FinalRound? finalRound, Notice? notice, StartCountdown? countdown, List<PackVote> packVotes, ChatState chat, List<Reaction> reactions
});


$PackCopyWith<$Res>? get pack;$GameOptionsCopyWith<$Res> get options;$QuestionCopyWith<$Res>? get question;$YouCopyWith<$Res> get you;$RevealCopyWith<$Res>? get reveal;$FinalRoundCopyWith<$Res>? get finalRound;$NoticeCopyWith<$Res>? get notice;$StartCountdownCopyWith<$Res>? get countdown;$ChatStateCopyWith<$Res> get chat;

}
/// @nodoc
class _$SeatStateCopyWithImpl<$Res>
    implements $SeatStateCopyWith<$Res> {
  _$SeatStateCopyWithImpl(this._self, this._then);

  final SeatState _self;
  final $Res Function(SeatState) _then;

/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? protocolVersion = null,Object? protocolMinor = null,Object? serverTime = null,Object? gameCode = null,Object? status = null,Object? phase = null,Object? pack = freezed,Object? options = null,Object? rounds = null,Object? question = freezed,Object? deadline = freezed,Object? players = null,Object? you = null,Object? reveal = freezed,Object? finalRound = freezed,Object? notice = freezed,Object? countdown = freezed,Object? packVotes = null,Object? chat = null,Object? reactions = null,}) {
  return _then(SeatState(
protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as int,protocolMinor: null == protocolMinor ? _self.protocolMinor : protocolMinor // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as int,gameCode: null == gameCode ? _self.gameCode : gameCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SeatStatus,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as Phase,pack: freezed == pack ? _self.pack : pack // ignore: cast_nullable_to_non_nullable
as Pack?,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as GameOptions,rounds: null == rounds ? _self.rounds : rounds // ignore: cast_nullable_to_non_nullable
as List<RoundInfo>,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as Question?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as int?,players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as List<PlayerView>,you: null == you ? _self.you : you // ignore: cast_nullable_to_non_nullable
as You,reveal: freezed == reveal ? _self.reveal : reveal // ignore: cast_nullable_to_non_nullable
as Reveal?,finalRound: freezed == finalRound ? _self.finalRound : finalRound // ignore: cast_nullable_to_non_nullable
as FinalRound?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as Notice?,countdown: freezed == countdown ? _self.countdown : countdown // ignore: cast_nullable_to_non_nullable
as StartCountdown?,packVotes: null == packVotes ? _self.packVotes : packVotes // ignore: cast_nullable_to_non_nullable
as List<PackVote>,chat: null == chat ? _self.chat : chat // ignore: cast_nullable_to_non_nullable
as ChatState,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<Reaction>,
  ));
}
/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PackCopyWith<$Res>? get pack {
    if (_self.pack == null) {
    return null;
  }

  return $PackCopyWith<$Res>(_self.pack!, (value) {
    return _then(_self.copyWith(pack: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameOptionsCopyWith<$Res> get options {
  
  return $GameOptionsCopyWith<$Res>(_self.options, (value) {
    return _then(_self.copyWith(options: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionCopyWith<$Res>? get question {
    if (_self.question == null) {
    return null;
  }

  return $QuestionCopyWith<$Res>(_self.question!, (value) {
    return _then(_self.copyWith(question: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouCopyWith<$Res> get you {
  
  return $YouCopyWith<$Res>(_self.you, (value) {
    return _then(_self.copyWith(you: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RevealCopyWith<$Res>? get reveal {
    if (_self.reveal == null) {
    return null;
  }

  return $RevealCopyWith<$Res>(_self.reveal!, (value) {
    return _then(_self.copyWith(reveal: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FinalRoundCopyWith<$Res>? get finalRound {
    if (_self.finalRound == null) {
    return null;
  }

  return $FinalRoundCopyWith<$Res>(_self.finalRound!, (value) {
    return _then(_self.copyWith(finalRound: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NoticeCopyWith<$Res>? get notice {
    if (_self.notice == null) {
    return null;
  }

  return $NoticeCopyWith<$Res>(_self.notice!, (value) {
    return _then(_self.copyWith(notice: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StartCountdownCopyWith<$Res>? get countdown {
    if (_self.countdown == null) {
    return null;
  }

  return $StartCountdownCopyWith<$Res>(_self.countdown!, (value) {
    return _then(_self.copyWith(countdown: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatStateCopyWith<$Res> get chat {
  
  return $ChatStateCopyWith<$Res>(_self.chat, (value) {
    return _then(_self.copyWith(chat: value));
  });
}
}


/// Adds pattern-matching-related methods to [SeatState].
extension SeatStatePatterns on SeatState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeatState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeatState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeatState value)  $default,){
final _that = this;
switch (_that) {
case _SeatState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeatState value)?  $default,){
final _that = this;
switch (_that) {
case _SeatState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int protocolVersion,  int protocolMinor,  int serverTime,  String gameCode,  SeatStatus status,  Phase phase,  Pack? pack,  GameOptions options,  List<RoundInfo> rounds,  Question? question,  int? deadline,  List<PlayerView> players,  You you,  Reveal? reveal, @JsonKey(name: 'final')  FinalRound? finalRound,  Notice? notice,  StartCountdown? countdown,  List<PackVote> packVotes,  ChatState chat,  List<Reaction> reactions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeatState() when $default != null:
return $default(_that.protocolVersion,_that.protocolMinor,_that.serverTime,_that.gameCode,_that.status,_that.phase,_that.pack,_that.options,_that.rounds,_that.question,_that.deadline,_that.players,_that.you,_that.reveal,_that.finalRound,_that.notice,_that.countdown,_that.packVotes,_that.chat,_that.reactions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int protocolVersion,  int protocolMinor,  int serverTime,  String gameCode,  SeatStatus status,  Phase phase,  Pack? pack,  GameOptions options,  List<RoundInfo> rounds,  Question? question,  int? deadline,  List<PlayerView> players,  You you,  Reveal? reveal, @JsonKey(name: 'final')  FinalRound? finalRound,  Notice? notice,  StartCountdown? countdown,  List<PackVote> packVotes,  ChatState chat,  List<Reaction> reactions)  $default,) {final _that = this;
switch (_that) {
case _SeatState():
return $default(_that.protocolVersion,_that.protocolMinor,_that.serverTime,_that.gameCode,_that.status,_that.phase,_that.pack,_that.options,_that.rounds,_that.question,_that.deadline,_that.players,_that.you,_that.reveal,_that.finalRound,_that.notice,_that.countdown,_that.packVotes,_that.chat,_that.reactions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int protocolVersion,  int protocolMinor,  int serverTime,  String gameCode,  SeatStatus status,  Phase phase,  Pack? pack,  GameOptions options,  List<RoundInfo> rounds,  Question? question,  int? deadline,  List<PlayerView> players,  You you,  Reveal? reveal, @JsonKey(name: 'final')  FinalRound? finalRound,  Notice? notice,  StartCountdown? countdown,  List<PackVote> packVotes,  ChatState chat,  List<Reaction> reactions)?  $default,) {final _that = this;
switch (_that) {
case _SeatState() when $default != null:
return $default(_that.protocolVersion,_that.protocolMinor,_that.serverTime,_that.gameCode,_that.status,_that.phase,_that.pack,_that.options,_that.rounds,_that.question,_that.deadline,_that.players,_that.you,_that.reveal,_that.finalRound,_that.notice,_that.countdown,_that.packVotes,_that.chat,_that.reactions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeatState extends SeatState {
  const _SeatState({required this.protocolVersion, this.protocolMinor = 0, required this.serverTime, required this.gameCode, required this.status, required this.phase, this.pack, required this.options,  List<RoundInfo> rounds = const <RoundInfo>[], this.question, this.deadline,  List<PlayerView> players = const <PlayerView>[], required this.you, this.reveal, @JsonKey(name: 'final') this.finalRound, this.notice, this.countdown,  List<PackVote> packVotes = const <PackVote>[], this.chat = const ChatState(),  List<Reaction> reactions = const <Reaction>[]}): _rounds = rounds,_players = players,_packVotes = packVotes,_reactions = reactions,super._();
  factory _SeatState.fromJson(Map<String, dynamic> json) => _$SeatStateFromJson(json);

@override final  int protocolVersion;
@override@JsonKey() final  int protocolMinor;
@override final  int serverTime;
@override final  String gameCode;
@override final  SeatStatus status;
@override final  Phase phase;
@override final  Pack? pack;
@override final  GameOptions options;
 final  List<RoundInfo> _rounds;
@override@JsonKey() List<RoundInfo> get rounds {
  if (_rounds is EqualUnmodifiableListView) return _rounds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rounds);
}

@override final  Question? question;
@override final  int? deadline;
 final  List<PlayerView> _players;
@override@JsonKey() List<PlayerView> get players {
  if (_players is EqualUnmodifiableListView) return _players;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_players);
}

@override final  You you;
@override final  Reveal? reveal;
@override@JsonKey(name: 'final') final  FinalRound? finalRound;
/// Something to tell the player for a moment (since 1.2).
@override final  Notice? notice;
/// The count down before the open question shows (since 1.2).
@override final  StartCountdown? countdown;
/// The lobby's pack votes, the most voted first (since 1.2).
 final  List<PackVote> _packVotes;
/// The lobby's pack votes, the most voted first (since 1.2).
@override@JsonKey() List<PackVote> get packVotes {
  if (_packVotes is EqualUnmodifiableListView) return _packVotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_packVotes);
}

/// The game's chat (since 1.2).
@override@JsonKey() final  ChatState chat;
/// Reactions other players sent this one, while they show (since 1.2).
 final  List<Reaction> _reactions;
/// Reactions other players sent this one, while they show (since 1.2).
@override@JsonKey() List<Reaction> get reactions {
  if (_reactions is EqualUnmodifiableListView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reactions);
}


/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeatStateCopyWith<_SeatState> get copyWith => __$SeatStateCopyWithImpl<_SeatState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeatStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeatState&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.protocolMinor, protocolMinor) || other.protocolMinor == protocolMinor)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.gameCode, gameCode) || other.gameCode == gameCode)&&(identical(other.status, status) || other.status == status)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.pack, pack) || other.pack == pack)&&(identical(other.options, options) || other.options == options)&&const DeepCollectionEquality().equals(other.rounds, _rounds)&&(identical(other.question, question) || other.question == question)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&const DeepCollectionEquality().equals(other.players, _players)&&(identical(other.you, you) || other.you == you)&&(identical(other.reveal, reveal) || other.reveal == reveal)&&(identical(other.finalRound, finalRound) || other.finalRound == finalRound)&&(identical(other.notice, notice) || other.notice == notice)&&(identical(other.countdown, countdown) || other.countdown == countdown)&&const DeepCollectionEquality().equals(other.packVotes, _packVotes)&&(identical(other.chat, chat) || other.chat == chat)&&const DeepCollectionEquality().equals(other.reactions, _reactions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,protocolVersion,protocolMinor,serverTime,gameCode,status,phase,pack,options,const DeepCollectionEquality().hash(_rounds),question,deadline,const DeepCollectionEquality().hash(_players),you,reveal,finalRound,notice,countdown,const DeepCollectionEquality().hash(_packVotes),chat,const DeepCollectionEquality().hash(_reactions)]);
}

@override
String toString() {
    return 'SeatState(protocolVersion: $protocolVersion, protocolMinor: $protocolMinor, serverTime: $serverTime, gameCode: $gameCode, status: $status, phase: $phase, pack: $pack, options: $options, rounds: $rounds, question: $question, deadline: $deadline, players: $players, you: $you, reveal: $reveal, finalRound: $finalRound, notice: $notice, countdown: $countdown, packVotes: $packVotes, chat: $chat, reactions: $reactions)';
}


}

/// @nodoc
abstract mixin class _$SeatStateCopyWith<$Res> implements $SeatStateCopyWith<$Res> {
  factory _$SeatStateCopyWith(_SeatState value, $Res Function(_SeatState) _then) = __$SeatStateCopyWithImpl;
@override @useResult
$Res call({
 int protocolVersion, int protocolMinor, int serverTime, String gameCode, SeatStatus status, Phase phase, Pack? pack, GameOptions options, List<RoundInfo> rounds, Question? question, int? deadline, List<PlayerView> players, You you, Reveal? reveal,@JsonKey(name: 'final') FinalRound? finalRound, Notice? notice, StartCountdown? countdown, List<PackVote> packVotes, ChatState chat, List<Reaction> reactions
});


@override $PackCopyWith<$Res>? get pack;@override $GameOptionsCopyWith<$Res> get options;@override $QuestionCopyWith<$Res>? get question;@override $YouCopyWith<$Res> get you;@override $RevealCopyWith<$Res>? get reveal;@override $FinalRoundCopyWith<$Res>? get finalRound;@override $NoticeCopyWith<$Res>? get notice;@override $StartCountdownCopyWith<$Res>? get countdown;@override $ChatStateCopyWith<$Res> get chat;

}
/// @nodoc
class __$SeatStateCopyWithImpl<$Res>
    implements _$SeatStateCopyWith<$Res> {
  __$SeatStateCopyWithImpl(this._self, this._then);

  final _SeatState _self;
  final $Res Function(_SeatState) _then;

/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? protocolVersion = null,Object? protocolMinor = null,Object? serverTime = null,Object? gameCode = null,Object? status = null,Object? phase = null,Object? pack = freezed,Object? options = null,Object? rounds = null,Object? question = freezed,Object? deadline = freezed,Object? players = null,Object? you = null,Object? reveal = freezed,Object? finalRound = freezed,Object? notice = freezed,Object? countdown = freezed,Object? packVotes = null,Object? chat = null,Object? reactions = null,}) {
  return _then(_SeatState(
protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as int,protocolMinor: null == protocolMinor ? _self.protocolMinor : protocolMinor // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as int,gameCode: null == gameCode ? _self.gameCode : gameCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SeatStatus,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as Phase,pack: freezed == pack ? _self.pack : pack // ignore: cast_nullable_to_non_nullable
as Pack?,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as GameOptions,rounds: null == rounds ? _self._rounds : rounds // ignore: cast_nullable_to_non_nullable
as List<RoundInfo>,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as Question?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as int?,players: null == players ? _self._players : players // ignore: cast_nullable_to_non_nullable
as List<PlayerView>,you: null == you ? _self.you : you // ignore: cast_nullable_to_non_nullable
as You,reveal: freezed == reveal ? _self.reveal : reveal // ignore: cast_nullable_to_non_nullable
as Reveal?,finalRound: freezed == finalRound ? _self.finalRound : finalRound // ignore: cast_nullable_to_non_nullable
as FinalRound?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as Notice?,countdown: freezed == countdown ? _self.countdown : countdown // ignore: cast_nullable_to_non_nullable
as StartCountdown?,packVotes: null == packVotes ? _self._packVotes : packVotes // ignore: cast_nullable_to_non_nullable
as List<PackVote>,chat: null == chat ? _self.chat : chat // ignore: cast_nullable_to_non_nullable
as ChatState,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<Reaction>,
  ));
}

/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PackCopyWith<$Res>? get pack {
    if (_self.pack == null) {
    return null;
  }

  return $PackCopyWith<$Res>(_self.pack!, (value) {
    return _then(_self.copyWith(pack: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameOptionsCopyWith<$Res> get options {
  
  return $GameOptionsCopyWith<$Res>(_self.options, (value) {
    return _then(_self.copyWith(options: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionCopyWith<$Res>? get question {
    if (_self.question == null) {
    return null;
  }

  return $QuestionCopyWith<$Res>(_self.question!, (value) {
    return _then(_self.copyWith(question: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouCopyWith<$Res> get you {
  
  return $YouCopyWith<$Res>(_self.you, (value) {
    return _then(_self.copyWith(you: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RevealCopyWith<$Res>? get reveal {
    if (_self.reveal == null) {
    return null;
  }

  return $RevealCopyWith<$Res>(_self.reveal!, (value) {
    return _then(_self.copyWith(reveal: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FinalRoundCopyWith<$Res>? get finalRound {
    if (_self.finalRound == null) {
    return null;
  }

  return $FinalRoundCopyWith<$Res>(_self.finalRound!, (value) {
    return _then(_self.copyWith(finalRound: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NoticeCopyWith<$Res>? get notice {
    if (_self.notice == null) {
    return null;
  }

  return $NoticeCopyWith<$Res>(_self.notice!, (value) {
    return _then(_self.copyWith(notice: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StartCountdownCopyWith<$Res>? get countdown {
    if (_self.countdown == null) {
    return null;
  }

  return $StartCountdownCopyWith<$Res>(_self.countdown!, (value) {
    return _then(_self.copyWith(countdown: value));
  });
}/// Create a copy of SeatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatStateCopyWith<$Res> get chat {
  
  return $ChatStateCopyWith<$Res>(_self.chat, (value) {
    return _then(_self.copyWith(chat: value));
  });
}
}


/// @nodoc
mixin _$Pack {

 int get id; String get name; String? get description; String? get imageUrl; int? get numQuestions; bool get hasImages;
/// Create a copy of Pack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackCopyWith<Pack> get copyWith => _$PackCopyWithImpl<Pack>(this as Pack, _$identity);

  /// Serializes this Pack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Pack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Pack&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.numQuestions, _this.numQuestions) || other.numQuestions == _this.numQuestions)&&(identical(other.hasImages, _this.hasImages) || other.hasImages == _this.hasImages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Pack;
  return Object.hash(runtimeType,_this.id,_this.name,_this.description,_this.imageUrl,_this.numQuestions,_this.hasImages);
}

@override
String toString() {
  final _this = this as Pack;
  return 'Pack(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, imageUrl: ${_this.imageUrl}, numQuestions: ${_this.numQuestions}, hasImages: ${_this.hasImages})';
}


}

/// @nodoc
abstract mixin class $PackCopyWith<$Res>  {
  factory $PackCopyWith(Pack value, $Res Function(Pack) _then) = _$PackCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? description, String? imageUrl, int? numQuestions, bool hasImages
});




}
/// @nodoc
class _$PackCopyWithImpl<$Res>
    implements $PackCopyWith<$Res> {
  _$PackCopyWithImpl(this._self, this._then);

  final Pack _self;
  final $Res Function(Pack) _then;

/// Create a copy of Pack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? imageUrl = freezed,Object? numQuestions = freezed,Object? hasImages = null,}) {
  return _then(Pack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,numQuestions: freezed == numQuestions ? _self.numQuestions : numQuestions // ignore: cast_nullable_to_non_nullable
as int?,hasImages: null == hasImages ? _self.hasImages : hasImages // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Pack].
extension PackPatterns on Pack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Pack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Pack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Pack value)  $default,){
final _that = this;
switch (_that) {
case _Pack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Pack value)?  $default,){
final _that = this;
switch (_that) {
case _Pack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? description,  String? imageUrl,  int? numQuestions,  bool hasImages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Pack() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.imageUrl,_that.numQuestions,_that.hasImages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? description,  String? imageUrl,  int? numQuestions,  bool hasImages)  $default,) {final _that = this;
switch (_that) {
case _Pack():
return $default(_that.id,_that.name,_that.description,_that.imageUrl,_that.numQuestions,_that.hasImages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? description,  String? imageUrl,  int? numQuestions,  bool hasImages)?  $default,) {final _that = this;
switch (_that) {
case _Pack() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.imageUrl,_that.numQuestions,_that.hasImages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Pack implements Pack {
  const _Pack({required this.id, required this.name, this.description, this.imageUrl, this.numQuestions, this.hasImages = false});
  factory _Pack.fromJson(Map<String, dynamic> json) => _$PackFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? description;
@override final  String? imageUrl;
@override final  int? numQuestions;
@override@JsonKey() final  bool hasImages;

/// Create a copy of Pack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackCopyWith<_Pack> get copyWith => __$PackCopyWithImpl<_Pack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pack&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.numQuestions, numQuestions) || other.numQuestions == numQuestions)&&(identical(other.hasImages, hasImages) || other.hasImages == hasImages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,description,imageUrl,numQuestions,hasImages);
}

@override
String toString() {
    return 'Pack(id: $id, name: $name, description: $description, imageUrl: $imageUrl, numQuestions: $numQuestions, hasImages: $hasImages)';
}


}

/// @nodoc
abstract mixin class _$PackCopyWith<$Res> implements $PackCopyWith<$Res> {
  factory _$PackCopyWith(_Pack value, $Res Function(_Pack) _then) = __$PackCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? description, String? imageUrl, int? numQuestions, bool hasImages
});




}
/// @nodoc
class __$PackCopyWithImpl<$Res>
    implements _$PackCopyWith<$Res> {
  __$PackCopyWithImpl(this._self, this._then);

  final _Pack _self;
  final $Res Function(_Pack) _then;

/// Create a copy of Pack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? imageUrl = freezed,Object? numQuestions = freezed,Object? hasImages = null,}) {
  return _then(_Pack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,numQuestions: freezed == numQuestions ? _self.numQuestions : numQuestions // ignore: cast_nullable_to_non_nullable
as int?,hasImages: null == hasImages ? _self.hasImages : hasImages // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$GameOptions {

 int get questionsPerGame; int get questionSeconds;
/// Create a copy of GameOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameOptionsCopyWith<GameOptions> get copyWith => _$GameOptionsCopyWithImpl<GameOptions>(this as GameOptions, _$identity);

  /// Serializes this GameOptions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GameOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameOptions&&(identical(other.questionsPerGame, _this.questionsPerGame) || other.questionsPerGame == _this.questionsPerGame)&&(identical(other.questionSeconds, _this.questionSeconds) || other.questionSeconds == _this.questionSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GameOptions;
  return Object.hash(runtimeType,_this.questionsPerGame,_this.questionSeconds);
}

@override
String toString() {
  final _this = this as GameOptions;
  return 'GameOptions(questionsPerGame: ${_this.questionsPerGame}, questionSeconds: ${_this.questionSeconds})';
}


}

/// @nodoc
abstract mixin class $GameOptionsCopyWith<$Res>  {
  factory $GameOptionsCopyWith(GameOptions value, $Res Function(GameOptions) _then) = _$GameOptionsCopyWithImpl;
@useResult
$Res call({
 int questionsPerGame, int questionSeconds
});




}
/// @nodoc
class _$GameOptionsCopyWithImpl<$Res>
    implements $GameOptionsCopyWith<$Res> {
  _$GameOptionsCopyWithImpl(this._self, this._then);

  final GameOptions _self;
  final $Res Function(GameOptions) _then;

/// Create a copy of GameOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionsPerGame = null,Object? questionSeconds = null,}) {
  return _then(GameOptions(
questionsPerGame: null == questionsPerGame ? _self.questionsPerGame : questionsPerGame // ignore: cast_nullable_to_non_nullable
as int,questionSeconds: null == questionSeconds ? _self.questionSeconds : questionSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GameOptions].
extension GameOptionsPatterns on GameOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameOptions value)  $default,){
final _that = this;
switch (_that) {
case _GameOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameOptions value)?  $default,){
final _that = this;
switch (_that) {
case _GameOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int questionsPerGame,  int questionSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameOptions() when $default != null:
return $default(_that.questionsPerGame,_that.questionSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int questionsPerGame,  int questionSeconds)  $default,) {final _that = this;
switch (_that) {
case _GameOptions():
return $default(_that.questionsPerGame,_that.questionSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int questionsPerGame,  int questionSeconds)?  $default,) {final _that = this;
switch (_that) {
case _GameOptions() when $default != null:
return $default(_that.questionsPerGame,_that.questionSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameOptions implements GameOptions {
  const _GameOptions({required this.questionsPerGame, required this.questionSeconds});
  factory _GameOptions.fromJson(Map<String, dynamic> json) => _$GameOptionsFromJson(json);

@override final  int questionsPerGame;
@override final  int questionSeconds;

/// Create a copy of GameOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameOptionsCopyWith<_GameOptions> get copyWith => __$GameOptionsCopyWithImpl<_GameOptions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameOptionsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameOptions&&(identical(other.questionsPerGame, questionsPerGame) || other.questionsPerGame == questionsPerGame)&&(identical(other.questionSeconds, questionSeconds) || other.questionSeconds == questionSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,questionsPerGame,questionSeconds);
}

@override
String toString() {
    return 'GameOptions(questionsPerGame: $questionsPerGame, questionSeconds: $questionSeconds)';
}


}

/// @nodoc
abstract mixin class _$GameOptionsCopyWith<$Res> implements $GameOptionsCopyWith<$Res> {
  factory _$GameOptionsCopyWith(_GameOptions value, $Res Function(_GameOptions) _then) = __$GameOptionsCopyWithImpl;
@override @useResult
$Res call({
 int questionsPerGame, int questionSeconds
});




}
/// @nodoc
class __$GameOptionsCopyWithImpl<$Res>
    implements _$GameOptionsCopyWith<$Res> {
  __$GameOptionsCopyWithImpl(this._self, this._then);

  final _GameOptions _self;
  final $Res Function(_GameOptions) _then;

/// Create a copy of GameOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionsPerGame = null,Object? questionSeconds = null,}) {
  return _then(_GameOptions(
questionsPerGame: null == questionsPerGame ? _self.questionsPerGame : questionsPerGame // ignore: cast_nullable_to_non_nullable
as int,questionSeconds: null == questionSeconds ? _self.questionSeconds : questionSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$RoundInfo {

 int get index; int? get percent;
/// Create a copy of RoundInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoundInfoCopyWith<RoundInfo> get copyWith => _$RoundInfoCopyWithImpl<RoundInfo>(this as RoundInfo, _$identity);

  /// Serializes this RoundInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RoundInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoundInfo&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.percent, _this.percent) || other.percent == _this.percent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RoundInfo;
  return Object.hash(runtimeType,_this.index,_this.percent);
}

@override
String toString() {
  final _this = this as RoundInfo;
  return 'RoundInfo(index: ${_this.index}, percent: ${_this.percent})';
}


}

/// @nodoc
abstract mixin class $RoundInfoCopyWith<$Res>  {
  factory $RoundInfoCopyWith(RoundInfo value, $Res Function(RoundInfo) _then) = _$RoundInfoCopyWithImpl;
@useResult
$Res call({
 int index, int? percent
});




}
/// @nodoc
class _$RoundInfoCopyWithImpl<$Res>
    implements $RoundInfoCopyWith<$Res> {
  _$RoundInfoCopyWithImpl(this._self, this._then);

  final RoundInfo _self;
  final $Res Function(RoundInfo) _then;

/// Create a copy of RoundInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? percent = freezed,}) {
  return _then(RoundInfo(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,percent: freezed == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RoundInfo].
extension RoundInfoPatterns on RoundInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoundInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoundInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoundInfo value)  $default,){
final _that = this;
switch (_that) {
case _RoundInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoundInfo value)?  $default,){
final _that = this;
switch (_that) {
case _RoundInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  int? percent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoundInfo() when $default != null:
return $default(_that.index,_that.percent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  int? percent)  $default,) {final _that = this;
switch (_that) {
case _RoundInfo():
return $default(_that.index,_that.percent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  int? percent)?  $default,) {final _that = this;
switch (_that) {
case _RoundInfo() when $default != null:
return $default(_that.index,_that.percent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoundInfo implements RoundInfo {
  const _RoundInfo({required this.index, this.percent});
  factory _RoundInfo.fromJson(Map<String, dynamic> json) => _$RoundInfoFromJson(json);

@override final  int index;
@override final  int? percent;

/// Create a copy of RoundInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoundInfoCopyWith<_RoundInfo> get copyWith => __$RoundInfoCopyWithImpl<_RoundInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoundInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoundInfo&&(identical(other.index, index) || other.index == index)&&(identical(other.percent, percent) || other.percent == percent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,index,percent);
}

@override
String toString() {
    return 'RoundInfo(index: $index, percent: $percent)';
}


}

/// @nodoc
abstract mixin class _$RoundInfoCopyWith<$Res> implements $RoundInfoCopyWith<$Res> {
  factory _$RoundInfoCopyWith(_RoundInfo value, $Res Function(_RoundInfo) _then) = __$RoundInfoCopyWithImpl;
@override @useResult
$Res call({
 int index, int? percent
});




}
/// @nodoc
class __$RoundInfoCopyWithImpl<$Res>
    implements _$RoundInfoCopyWith<$Res> {
  __$RoundInfoCopyWithImpl(this._self, this._then);

  final _RoundInfo _self;
  final $Res Function(_RoundInfo) _then;

/// Create a copy of RoundInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? percent = freezed,}) {
  return _then(_RoundInfo(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,percent: freezed == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Question {

 int get index; String get text; String? get category; String? get difficulty; String? get imageUrl; bool get isFinal;
/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionCopyWith<Question> get copyWith => _$QuestionCopyWithImpl<Question>(this as Question, _$identity);

  /// Serializes this Question to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Question;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Question&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.difficulty, _this.difficulty) || other.difficulty == _this.difficulty)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.isFinal, _this.isFinal) || other.isFinal == _this.isFinal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Question;
  return Object.hash(runtimeType,_this.index,_this.text,_this.category,_this.difficulty,_this.imageUrl,_this.isFinal);
}

@override
String toString() {
  final _this = this as Question;
  return 'Question(index: ${_this.index}, text: ${_this.text}, category: ${_this.category}, difficulty: ${_this.difficulty}, imageUrl: ${_this.imageUrl}, isFinal: ${_this.isFinal})';
}


}

/// @nodoc
abstract mixin class $QuestionCopyWith<$Res>  {
  factory $QuestionCopyWith(Question value, $Res Function(Question) _then) = _$QuestionCopyWithImpl;
@useResult
$Res call({
 int index, String text, String? category, String? difficulty, String? imageUrl, bool isFinal
});




}
/// @nodoc
class _$QuestionCopyWithImpl<$Res>
    implements $QuestionCopyWith<$Res> {
  _$QuestionCopyWithImpl(this._self, this._then);

  final Question _self;
  final $Res Function(Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? text = null,Object? category = freezed,Object? difficulty = freezed,Object? imageUrl = freezed,Object? isFinal = null,}) {
  return _then(Question(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,difficulty: freezed == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Question].
extension QuestionPatterns on Question {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Question value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Question value)  $default,){
final _that = this;
switch (_that) {
case _Question():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Question value)?  $default,){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String text,  String? category,  String? difficulty,  String? imageUrl,  bool isFinal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.index,_that.text,_that.category,_that.difficulty,_that.imageUrl,_that.isFinal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String text,  String? category,  String? difficulty,  String? imageUrl,  bool isFinal)  $default,) {final _that = this;
switch (_that) {
case _Question():
return $default(_that.index,_that.text,_that.category,_that.difficulty,_that.imageUrl,_that.isFinal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String text,  String? category,  String? difficulty,  String? imageUrl,  bool isFinal)?  $default,) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.index,_that.text,_that.category,_that.difficulty,_that.imageUrl,_that.isFinal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Question implements Question {
  const _Question({required this.index, required this.text, this.category, this.difficulty, this.imageUrl, this.isFinal = false});
  factory _Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);

@override final  int index;
@override final  String text;
@override final  String? category;
@override final  String? difficulty;
@override final  String? imageUrl;
@override@JsonKey() final  bool isFinal;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionCopyWith<_Question> get copyWith => __$QuestionCopyWithImpl<_Question>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Question&&(identical(other.index, index) || other.index == index)&&(identical(other.text, text) || other.text == text)&&(identical(other.category, category) || other.category == category)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.isFinal, isFinal) || other.isFinal == isFinal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,index,text,category,difficulty,imageUrl,isFinal);
}

@override
String toString() {
    return 'Question(index: $index, text: $text, category: $category, difficulty: $difficulty, imageUrl: $imageUrl, isFinal: $isFinal)';
}


}

/// @nodoc
abstract mixin class _$QuestionCopyWith<$Res> implements $QuestionCopyWith<$Res> {
  factory _$QuestionCopyWith(_Question value, $Res Function(_Question) _then) = __$QuestionCopyWithImpl;
@override @useResult
$Res call({
 int index, String text, String? category, String? difficulty, String? imageUrl, bool isFinal
});




}
/// @nodoc
class __$QuestionCopyWithImpl<$Res>
    implements _$QuestionCopyWith<$Res> {
  __$QuestionCopyWithImpl(this._self, this._then);

  final _Question _self;
  final $Res Function(_Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? text = null,Object? category = freezed,Object? difficulty = freezed,Object? imageUrl = freezed,Object? isFinal = null,}) {
  return _then(_Question(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,difficulty: freezed == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PlayerView {

 int get peerId; String get name; bool get host; bool get connected; bool get ready;/// They asked to play again, on the final scores (since 1.2).
 bool get readyForNextGame;/// Watching, not playing: a host who hosts as a spectator (since 1.2).
 bool get spectating; int get score; bool get answered;/// Their answer to the open question, once you have answered it yourself.
 String? get guess; bool get finalWagered;/// The reactions they have had this game (since 1.2).
 PlayerReactions get reactions;
/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerViewCopyWith<PlayerView> get copyWith => _$PlayerViewCopyWithImpl<PlayerView>(this as PlayerView, _$identity);

  /// Serializes this PlayerView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlayerView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerView&&(identical(other.peerId, _this.peerId) || other.peerId == _this.peerId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.host, _this.host) || other.host == _this.host)&&(identical(other.connected, _this.connected) || other.connected == _this.connected)&&(identical(other.ready, _this.ready) || other.ready == _this.ready)&&(identical(other.readyForNextGame, _this.readyForNextGame) || other.readyForNextGame == _this.readyForNextGame)&&(identical(other.spectating, _this.spectating) || other.spectating == _this.spectating)&&(identical(other.score, _this.score) || other.score == _this.score)&&(identical(other.answered, _this.answered) || other.answered == _this.answered)&&(identical(other.guess, _this.guess) || other.guess == _this.guess)&&(identical(other.finalWagered, _this.finalWagered) || other.finalWagered == _this.finalWagered)&&(identical(other.reactions, _this.reactions) || other.reactions == _this.reactions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlayerView;
  return Object.hash(runtimeType,_this.peerId,_this.name,_this.host,_this.connected,_this.ready,_this.readyForNextGame,_this.spectating,_this.score,_this.answered,_this.guess,_this.finalWagered,_this.reactions);
}

@override
String toString() {
  final _this = this as PlayerView;
  return 'PlayerView(peerId: ${_this.peerId}, name: ${_this.name}, host: ${_this.host}, connected: ${_this.connected}, ready: ${_this.ready}, readyForNextGame: ${_this.readyForNextGame}, spectating: ${_this.spectating}, score: ${_this.score}, answered: ${_this.answered}, guess: ${_this.guess}, finalWagered: ${_this.finalWagered}, reactions: ${_this.reactions})';
}


}

/// @nodoc
abstract mixin class $PlayerViewCopyWith<$Res>  {
  factory $PlayerViewCopyWith(PlayerView value, $Res Function(PlayerView) _then) = _$PlayerViewCopyWithImpl;
@useResult
$Res call({
 int peerId, String name, bool host, bool connected, bool ready, bool readyForNextGame, bool spectating, int score, bool answered, String? guess, bool finalWagered, PlayerReactions reactions
});


$PlayerReactionsCopyWith<$Res> get reactions;

}
/// @nodoc
class _$PlayerViewCopyWithImpl<$Res>
    implements $PlayerViewCopyWith<$Res> {
  _$PlayerViewCopyWithImpl(this._self, this._then);

  final PlayerView _self;
  final $Res Function(PlayerView) _then;

/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? peerId = null,Object? name = null,Object? host = null,Object? connected = null,Object? ready = null,Object? readyForNextGame = null,Object? spectating = null,Object? score = null,Object? answered = null,Object? guess = freezed,Object? finalWagered = null,Object? reactions = null,}) {
  return _then(PlayerView(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as bool,connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,readyForNextGame: null == readyForNextGame ? _self.readyForNextGame : readyForNextGame // ignore: cast_nullable_to_non_nullable
as bool,spectating: null == spectating ? _self.spectating : spectating // ignore: cast_nullable_to_non_nullable
as bool,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,answered: null == answered ? _self.answered : answered // ignore: cast_nullable_to_non_nullable
as bool,guess: freezed == guess ? _self.guess : guess // ignore: cast_nullable_to_non_nullable
as String?,finalWagered: null == finalWagered ? _self.finalWagered : finalWagered // ignore: cast_nullable_to_non_nullable
as bool,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as PlayerReactions,
  ));
}
/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerReactionsCopyWith<$Res> get reactions {
  
  return $PlayerReactionsCopyWith<$Res>(_self.reactions, (value) {
    return _then(_self.copyWith(reactions: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlayerView].
extension PlayerViewPatterns on PlayerView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerView value)  $default,){
final _that = this;
switch (_that) {
case _PlayerView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerView value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int peerId,  String name,  bool host,  bool connected,  bool ready,  bool readyForNextGame,  bool spectating,  int score,  bool answered,  String? guess,  bool finalWagered,  PlayerReactions reactions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerView() when $default != null:
return $default(_that.peerId,_that.name,_that.host,_that.connected,_that.ready,_that.readyForNextGame,_that.spectating,_that.score,_that.answered,_that.guess,_that.finalWagered,_that.reactions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int peerId,  String name,  bool host,  bool connected,  bool ready,  bool readyForNextGame,  bool spectating,  int score,  bool answered,  String? guess,  bool finalWagered,  PlayerReactions reactions)  $default,) {final _that = this;
switch (_that) {
case _PlayerView():
return $default(_that.peerId,_that.name,_that.host,_that.connected,_that.ready,_that.readyForNextGame,_that.spectating,_that.score,_that.answered,_that.guess,_that.finalWagered,_that.reactions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int peerId,  String name,  bool host,  bool connected,  bool ready,  bool readyForNextGame,  bool spectating,  int score,  bool answered,  String? guess,  bool finalWagered,  PlayerReactions reactions)?  $default,) {final _that = this;
switch (_that) {
case _PlayerView() when $default != null:
return $default(_that.peerId,_that.name,_that.host,_that.connected,_that.ready,_that.readyForNextGame,_that.spectating,_that.score,_that.answered,_that.guess,_that.finalWagered,_that.reactions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerView implements PlayerView {
  const _PlayerView({required this.peerId, required this.name, this.host = false, this.connected = true, this.ready = false, this.readyForNextGame = false, this.spectating = false, this.score = 0, this.answered = false, this.guess, this.finalWagered = false, this.reactions = const PlayerReactions()});
  factory _PlayerView.fromJson(Map<String, dynamic> json) => _$PlayerViewFromJson(json);

@override final  int peerId;
@override final  String name;
@override@JsonKey() final  bool host;
@override@JsonKey() final  bool connected;
@override@JsonKey() final  bool ready;
/// They asked to play again, on the final scores (since 1.2).
@override@JsonKey() final  bool readyForNextGame;
/// Watching, not playing: a host who hosts as a spectator (since 1.2).
@override@JsonKey() final  bool spectating;
@override@JsonKey() final  int score;
@override@JsonKey() final  bool answered;
/// Their answer to the open question, once you have answered it yourself.
@override final  String? guess;
@override@JsonKey() final  bool finalWagered;
/// The reactions they have had this game (since 1.2).
@override@JsonKey() final  PlayerReactions reactions;

/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerViewCopyWith<_PlayerView> get copyWith => __$PlayerViewCopyWithImpl<_PlayerView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerView&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.host, host) || other.host == host)&&(identical(other.connected, connected) || other.connected == connected)&&(identical(other.ready, ready) || other.ready == ready)&&(identical(other.readyForNextGame, readyForNextGame) || other.readyForNextGame == readyForNextGame)&&(identical(other.spectating, spectating) || other.spectating == spectating)&&(identical(other.score, score) || other.score == score)&&(identical(other.answered, answered) || other.answered == answered)&&(identical(other.guess, guess) || other.guess == guess)&&(identical(other.finalWagered, finalWagered) || other.finalWagered == finalWagered)&&(identical(other.reactions, reactions) || other.reactions == reactions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,peerId,name,host,connected,ready,readyForNextGame,spectating,score,answered,guess,finalWagered,reactions);
}

@override
String toString() {
    return 'PlayerView(peerId: $peerId, name: $name, host: $host, connected: $connected, ready: $ready, readyForNextGame: $readyForNextGame, spectating: $spectating, score: $score, answered: $answered, guess: $guess, finalWagered: $finalWagered, reactions: $reactions)';
}


}

/// @nodoc
abstract mixin class _$PlayerViewCopyWith<$Res> implements $PlayerViewCopyWith<$Res> {
  factory _$PlayerViewCopyWith(_PlayerView value, $Res Function(_PlayerView) _then) = __$PlayerViewCopyWithImpl;
@override @useResult
$Res call({
 int peerId, String name, bool host, bool connected, bool ready, bool readyForNextGame, bool spectating, int score, bool answered, String? guess, bool finalWagered, PlayerReactions reactions
});


@override $PlayerReactionsCopyWith<$Res> get reactions;

}
/// @nodoc
class __$PlayerViewCopyWithImpl<$Res>
    implements _$PlayerViewCopyWith<$Res> {
  __$PlayerViewCopyWithImpl(this._self, this._then);

  final _PlayerView _self;
  final $Res Function(_PlayerView) _then;

/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? peerId = null,Object? name = null,Object? host = null,Object? connected = null,Object? ready = null,Object? readyForNextGame = null,Object? spectating = null,Object? score = null,Object? answered = null,Object? guess = freezed,Object? finalWagered = null,Object? reactions = null,}) {
  return _then(_PlayerView(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as bool,connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,readyForNextGame: null == readyForNextGame ? _self.readyForNextGame : readyForNextGame // ignore: cast_nullable_to_non_nullable
as bool,spectating: null == spectating ? _self.spectating : spectating // ignore: cast_nullable_to_non_nullable
as bool,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,answered: null == answered ? _self.answered : answered // ignore: cast_nullable_to_non_nullable
as bool,guess: freezed == guess ? _self.guess : guess // ignore: cast_nullable_to_non_nullable
as String?,finalWagered: null == finalWagered ? _self.finalWagered : finalWagered // ignore: cast_nullable_to_non_nullable
as bool,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as PlayerReactions,
  ));
}

/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerReactionsCopyWith<$Res> get reactions {
  
  return $PlayerReactionsCopyWith<$Res>(_self.reactions, (value) {
    return _then(_self.copyWith(reactions: value));
  });
}
}


/// @nodoc
mixin _$You {

 int? get peerId; bool get host;/// Whether the host may reveal the open question (a relay before 1.1
/// doesn't say, and allowed it any time).
 bool get canReveal; OwnAnswer? get answer; List<int> get wagerChoices; Map<String, bool> get judgements; bool get judged;/// This player asked to play again; the host's asking starts the next game.
 bool get playedAgain;/// Hosting without playing (since 1.2): no answers, votes or wagers.
 bool get spectating;/// Whether the question on screen may be rated and reported now: once
/// answered, and while revealed (since 1.2).
 bool get canRate;/// This player's thumb on it: 1 up, -1 down, 0 none (since 1.2).
 int get rating;/// This player reported it (since 1.2).
 bool get reported;/// The Party Poppers this player has, as far as the seat knows: what
/// Sporcle said as they took it, less any spent since (since 1.2).
 int? get poppers;
/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouCopyWith<You> get copyWith => _$YouCopyWithImpl<You>(this as You, _$identity);

  /// Serializes this You to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as You;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is You&&(identical(other.peerId, _this.peerId) || other.peerId == _this.peerId)&&(identical(other.host, _this.host) || other.host == _this.host)&&(identical(other.canReveal, _this.canReveal) || other.canReveal == _this.canReveal)&&(identical(other.answer, _this.answer) || other.answer == _this.answer)&&const DeepCollectionEquality().equals(other.wagerChoices, _this.wagerChoices)&&const DeepCollectionEquality().equals(other.judgements, _this.judgements)&&(identical(other.judged, _this.judged) || other.judged == _this.judged)&&(identical(other.playedAgain, _this.playedAgain) || other.playedAgain == _this.playedAgain)&&(identical(other.spectating, _this.spectating) || other.spectating == _this.spectating)&&(identical(other.canRate, _this.canRate) || other.canRate == _this.canRate)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.reported, _this.reported) || other.reported == _this.reported)&&(identical(other.poppers, _this.poppers) || other.poppers == _this.poppers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as You;
  return Object.hash(runtimeType,_this.peerId,_this.host,_this.canReveal,_this.answer,const DeepCollectionEquality().hash(_this.wagerChoices),const DeepCollectionEquality().hash(_this.judgements),_this.judged,_this.playedAgain,_this.spectating,_this.canRate,_this.rating,_this.reported,_this.poppers);
}

@override
String toString() {
  final _this = this as You;
  return 'You(peerId: ${_this.peerId}, host: ${_this.host}, canReveal: ${_this.canReveal}, answer: ${_this.answer}, wagerChoices: ${_this.wagerChoices}, judgements: ${_this.judgements}, judged: ${_this.judged}, playedAgain: ${_this.playedAgain}, spectating: ${_this.spectating}, canRate: ${_this.canRate}, rating: ${_this.rating}, reported: ${_this.reported}, poppers: ${_this.poppers})';
}


}

/// @nodoc
abstract mixin class $YouCopyWith<$Res>  {
  factory $YouCopyWith(You value, $Res Function(You) _then) = _$YouCopyWithImpl;
@useResult
$Res call({
 int? peerId, bool host, bool canReveal, OwnAnswer? answer, List<int> wagerChoices, Map<String, bool> judgements, bool judged, bool playedAgain, bool spectating, bool canRate, int rating, bool reported, int? poppers
});


$OwnAnswerCopyWith<$Res>? get answer;

}
/// @nodoc
class _$YouCopyWithImpl<$Res>
    implements $YouCopyWith<$Res> {
  _$YouCopyWithImpl(this._self, this._then);

  final You _self;
  final $Res Function(You) _then;

/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? peerId = freezed,Object? host = null,Object? canReveal = null,Object? answer = freezed,Object? wagerChoices = null,Object? judgements = null,Object? judged = null,Object? playedAgain = null,Object? spectating = null,Object? canRate = null,Object? rating = null,Object? reported = null,Object? poppers = freezed,}) {
  return _then(You(
peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int?,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as bool,canReveal: null == canReveal ? _self.canReveal : canReveal // ignore: cast_nullable_to_non_nullable
as bool,answer: freezed == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as OwnAnswer?,wagerChoices: null == wagerChoices ? _self.wagerChoices : wagerChoices // ignore: cast_nullable_to_non_nullable
as List<int>,judgements: null == judgements ? _self.judgements : judgements // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,judged: null == judged ? _self.judged : judged // ignore: cast_nullable_to_non_nullable
as bool,playedAgain: null == playedAgain ? _self.playedAgain : playedAgain // ignore: cast_nullable_to_non_nullable
as bool,spectating: null == spectating ? _self.spectating : spectating // ignore: cast_nullable_to_non_nullable
as bool,canRate: null == canRate ? _self.canRate : canRate // ignore: cast_nullable_to_non_nullable
as bool,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,reported: null == reported ? _self.reported : reported // ignore: cast_nullable_to_non_nullable
as bool,poppers: freezed == poppers ? _self.poppers : poppers // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OwnAnswerCopyWith<$Res>? get answer {
    if (_self.answer == null) {
    return null;
  }

  return $OwnAnswerCopyWith<$Res>(_self.answer!, (value) {
    return _then(_self.copyWith(answer: value));
  });
}
}


/// Adds pattern-matching-related methods to [You].
extension YouPatterns on You {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _You value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _You() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _You value)  $default,){
final _that = this;
switch (_that) {
case _You():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _You value)?  $default,){
final _that = this;
switch (_that) {
case _You() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? peerId,  bool host,  bool canReveal,  OwnAnswer? answer,  List<int> wagerChoices,  Map<String, bool> judgements,  bool judged,  bool playedAgain,  bool spectating,  bool canRate,  int rating,  bool reported,  int? poppers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _You() when $default != null:
return $default(_that.peerId,_that.host,_that.canReveal,_that.answer,_that.wagerChoices,_that.judgements,_that.judged,_that.playedAgain,_that.spectating,_that.canRate,_that.rating,_that.reported,_that.poppers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? peerId,  bool host,  bool canReveal,  OwnAnswer? answer,  List<int> wagerChoices,  Map<String, bool> judgements,  bool judged,  bool playedAgain,  bool spectating,  bool canRate,  int rating,  bool reported,  int? poppers)  $default,) {final _that = this;
switch (_that) {
case _You():
return $default(_that.peerId,_that.host,_that.canReveal,_that.answer,_that.wagerChoices,_that.judgements,_that.judged,_that.playedAgain,_that.spectating,_that.canRate,_that.rating,_that.reported,_that.poppers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? peerId,  bool host,  bool canReveal,  OwnAnswer? answer,  List<int> wagerChoices,  Map<String, bool> judgements,  bool judged,  bool playedAgain,  bool spectating,  bool canRate,  int rating,  bool reported,  int? poppers)?  $default,) {final _that = this;
switch (_that) {
case _You() when $default != null:
return $default(_that.peerId,_that.host,_that.canReveal,_that.answer,_that.wagerChoices,_that.judgements,_that.judged,_that.playedAgain,_that.spectating,_that.canRate,_that.rating,_that.reported,_that.poppers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _You implements You {
  const _You({this.peerId, this.host = false, this.canReveal = true, this.answer,  List<int> wagerChoices = const <int>[],  Map<String, bool> judgements = const <String, bool>{}, this.judged = false, this.playedAgain = false, this.spectating = false, this.canRate = false, this.rating = 0, this.reported = false, this.poppers}): _wagerChoices = wagerChoices,_judgements = judgements;
  factory _You.fromJson(Map<String, dynamic> json) => _$YouFromJson(json);

@override final  int? peerId;
@override@JsonKey() final  bool host;
/// Whether the host may reveal the open question (a relay before 1.1
/// doesn't say, and allowed it any time).
@override@JsonKey() final  bool canReveal;
@override final  OwnAnswer? answer;
 final  List<int> _wagerChoices;
@override@JsonKey() List<int> get wagerChoices {
  if (_wagerChoices is EqualUnmodifiableListView) return _wagerChoices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_wagerChoices);
}

 final  Map<String, bool> _judgements;
@override@JsonKey() Map<String, bool> get judgements {
  if (_judgements is EqualUnmodifiableMapView) return _judgements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_judgements);
}

@override@JsonKey() final  bool judged;
/// This player asked to play again; the host's asking starts the next game.
@override@JsonKey() final  bool playedAgain;
/// Hosting without playing (since 1.2): no answers, votes or wagers.
@override@JsonKey() final  bool spectating;
/// Whether the question on screen may be rated and reported now: once
/// answered, and while revealed (since 1.2).
@override@JsonKey() final  bool canRate;
/// This player's thumb on it: 1 up, -1 down, 0 none (since 1.2).
@override@JsonKey() final  int rating;
/// This player reported it (since 1.2).
@override@JsonKey() final  bool reported;
/// The Party Poppers this player has, as far as the seat knows: what
/// Sporcle said as they took it, less any spent since (since 1.2).
@override final  int? poppers;

/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouCopyWith<_You> get copyWith => __$YouCopyWithImpl<_You>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YouToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _You&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.host, host) || other.host == host)&&(identical(other.canReveal, canReveal) || other.canReveal == canReveal)&&(identical(other.answer, answer) || other.answer == answer)&&const DeepCollectionEquality().equals(other.wagerChoices, _wagerChoices)&&const DeepCollectionEquality().equals(other.judgements, _judgements)&&(identical(other.judged, judged) || other.judged == judged)&&(identical(other.playedAgain, playedAgain) || other.playedAgain == playedAgain)&&(identical(other.spectating, spectating) || other.spectating == spectating)&&(identical(other.canRate, canRate) || other.canRate == canRate)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reported, reported) || other.reported == reported)&&(identical(other.poppers, poppers) || other.poppers == poppers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,peerId,host,canReveal,answer,const DeepCollectionEquality().hash(_wagerChoices),const DeepCollectionEquality().hash(_judgements),judged,playedAgain,spectating,canRate,rating,reported,poppers);
}

@override
String toString() {
    return 'You(peerId: $peerId, host: $host, canReveal: $canReveal, answer: $answer, wagerChoices: $wagerChoices, judgements: $judgements, judged: $judged, playedAgain: $playedAgain, spectating: $spectating, canRate: $canRate, rating: $rating, reported: $reported, poppers: $poppers)';
}


}

/// @nodoc
abstract mixin class _$YouCopyWith<$Res> implements $YouCopyWith<$Res> {
  factory _$YouCopyWith(_You value, $Res Function(_You) _then) = __$YouCopyWithImpl;
@override @useResult
$Res call({
 int? peerId, bool host, bool canReveal, OwnAnswer? answer, List<int> wagerChoices, Map<String, bool> judgements, bool judged, bool playedAgain, bool spectating, bool canRate, int rating, bool reported, int? poppers
});


@override $OwnAnswerCopyWith<$Res>? get answer;

}
/// @nodoc
class __$YouCopyWithImpl<$Res>
    implements _$YouCopyWith<$Res> {
  __$YouCopyWithImpl(this._self, this._then);

  final _You _self;
  final $Res Function(_You) _then;

/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? peerId = freezed,Object? host = null,Object? canReveal = null,Object? answer = freezed,Object? wagerChoices = null,Object? judgements = null,Object? judged = null,Object? playedAgain = null,Object? spectating = null,Object? canRate = null,Object? rating = null,Object? reported = null,Object? poppers = freezed,}) {
  return _then(_You(
peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int?,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as bool,canReveal: null == canReveal ? _self.canReveal : canReveal // ignore: cast_nullable_to_non_nullable
as bool,answer: freezed == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as OwnAnswer?,wagerChoices: null == wagerChoices ? _self._wagerChoices : wagerChoices // ignore: cast_nullable_to_non_nullable
as List<int>,judgements: null == judgements ? _self._judgements : judgements // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,judged: null == judged ? _self.judged : judged // ignore: cast_nullable_to_non_nullable
as bool,playedAgain: null == playedAgain ? _self.playedAgain : playedAgain // ignore: cast_nullable_to_non_nullable
as bool,spectating: null == spectating ? _self.spectating : spectating // ignore: cast_nullable_to_non_nullable
as bool,canRate: null == canRate ? _self.canRate : canRate // ignore: cast_nullable_to_non_nullable
as bool,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,reported: null == reported ? _self.reported : reported // ignore: cast_nullable_to_non_nullable
as bool,poppers: freezed == poppers ? _self.poppers : poppers // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OwnAnswerCopyWith<$Res>? get answer {
    if (_self.answer == null) {
    return null;
  }

  return $OwnAnswerCopyWith<$Res>(_self.answer!, (value) {
    return _then(_self.copyWith(answer: value));
  });
}
}


/// @nodoc
mixin _$OwnAnswer {

 String get text; int get wager;
/// Create a copy of OwnAnswer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnAnswerCopyWith<OwnAnswer> get copyWith => _$OwnAnswerCopyWithImpl<OwnAnswer>(this as OwnAnswer, _$identity);

  /// Serializes this OwnAnswer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OwnAnswer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OwnAnswer&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.wager, _this.wager) || other.wager == _this.wager));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OwnAnswer;
  return Object.hash(runtimeType,_this.text,_this.wager);
}

@override
String toString() {
  final _this = this as OwnAnswer;
  return 'OwnAnswer(text: ${_this.text}, wager: ${_this.wager})';
}


}

/// @nodoc
abstract mixin class $OwnAnswerCopyWith<$Res>  {
  factory $OwnAnswerCopyWith(OwnAnswer value, $Res Function(OwnAnswer) _then) = _$OwnAnswerCopyWithImpl;
@useResult
$Res call({
 String text, int wager
});




}
/// @nodoc
class _$OwnAnswerCopyWithImpl<$Res>
    implements $OwnAnswerCopyWith<$Res> {
  _$OwnAnswerCopyWithImpl(this._self, this._then);

  final OwnAnswer _self;
  final $Res Function(OwnAnswer) _then;

/// Create a copy of OwnAnswer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? wager = null,}) {
  return _then(OwnAnswer(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,wager: null == wager ? _self.wager : wager // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OwnAnswer].
extension OwnAnswerPatterns on OwnAnswer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OwnAnswer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OwnAnswer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OwnAnswer value)  $default,){
final _that = this;
switch (_that) {
case _OwnAnswer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OwnAnswer value)?  $default,){
final _that = this;
switch (_that) {
case _OwnAnswer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  int wager)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OwnAnswer() when $default != null:
return $default(_that.text,_that.wager);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  int wager)  $default,) {final _that = this;
switch (_that) {
case _OwnAnswer():
return $default(_that.text,_that.wager);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  int wager)?  $default,) {final _that = this;
switch (_that) {
case _OwnAnswer() when $default != null:
return $default(_that.text,_that.wager);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OwnAnswer implements OwnAnswer {
  const _OwnAnswer({required this.text, required this.wager});
  factory _OwnAnswer.fromJson(Map<String, dynamic> json) => _$OwnAnswerFromJson(json);

@override final  String text;
@override final  int wager;

/// Create a copy of OwnAnswer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnAnswerCopyWith<_OwnAnswer> get copyWith => __$OwnAnswerCopyWithImpl<_OwnAnswer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OwnAnswerToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OwnAnswer&&(identical(other.text, text) || other.text == text)&&(identical(other.wager, wager) || other.wager == wager));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,wager);
}

@override
String toString() {
    return 'OwnAnswer(text: $text, wager: $wager)';
}


}

/// @nodoc
abstract mixin class _$OwnAnswerCopyWith<$Res> implements $OwnAnswerCopyWith<$Res> {
  factory _$OwnAnswerCopyWith(_OwnAnswer value, $Res Function(_OwnAnswer) _then) = __$OwnAnswerCopyWithImpl;
@override @useResult
$Res call({
 String text, int wager
});




}
/// @nodoc
class __$OwnAnswerCopyWithImpl<$Res>
    implements _$OwnAnswerCopyWith<$Res> {
  __$OwnAnswerCopyWithImpl(this._self, this._then);

  final _OwnAnswer _self;
  final $Res Function(_OwnAnswer) _then;

/// Create a copy of OwnAnswer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? wager = null,}) {
  return _then(_OwnAnswer(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,wager: null == wager ? _self.wager : wager // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Reveal {

 String? get answer; List<RevealAnswer> get answers;
/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevealCopyWith<Reveal> get copyWith => _$RevealCopyWithImpl<Reveal>(this as Reveal, _$identity);

  /// Serializes this Reveal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Reveal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reveal&&(identical(other.answer, _this.answer) || other.answer == _this.answer)&&const DeepCollectionEquality().equals(other.answers, _this.answers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Reveal;
  return Object.hash(runtimeType,_this.answer,const DeepCollectionEquality().hash(_this.answers));
}

@override
String toString() {
  final _this = this as Reveal;
  return 'Reveal(answer: ${_this.answer}, answers: ${_this.answers})';
}


}

/// @nodoc
abstract mixin class $RevealCopyWith<$Res>  {
  factory $RevealCopyWith(Reveal value, $Res Function(Reveal) _then) = _$RevealCopyWithImpl;
@useResult
$Res call({
 String? answer, List<RevealAnswer> answers
});




}
/// @nodoc
class _$RevealCopyWithImpl<$Res>
    implements $RevealCopyWith<$Res> {
  _$RevealCopyWithImpl(this._self, this._then);

  final Reveal _self;
  final $Res Function(Reveal) _then;

/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? answer = freezed,Object? answers = null,}) {
  return _then(Reveal(
answer: freezed == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String?,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as List<RevealAnswer>,
  ));
}

}


/// Adds pattern-matching-related methods to [Reveal].
extension RevealPatterns on Reveal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reveal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reveal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reveal value)  $default,){
final _that = this;
switch (_that) {
case _Reveal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reveal value)?  $default,){
final _that = this;
switch (_that) {
case _Reveal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? answer,  List<RevealAnswer> answers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reveal() when $default != null:
return $default(_that.answer,_that.answers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? answer,  List<RevealAnswer> answers)  $default,) {final _that = this;
switch (_that) {
case _Reveal():
return $default(_that.answer,_that.answers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? answer,  List<RevealAnswer> answers)?  $default,) {final _that = this;
switch (_that) {
case _Reveal() when $default != null:
return $default(_that.answer,_that.answers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reveal implements Reveal {
  const _Reveal({this.answer,  List<RevealAnswer> answers = const <RevealAnswer>[]}): _answers = answers;
  factory _Reveal.fromJson(Map<String, dynamic> json) => _$RevealFromJson(json);

@override final  String? answer;
 final  List<RevealAnswer> _answers;
@override@JsonKey() List<RevealAnswer> get answers {
  if (_answers is EqualUnmodifiableListView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answers);
}


/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevealCopyWith<_Reveal> get copyWith => __$RevealCopyWithImpl<_Reveal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevealToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reveal&&(identical(other.answer, answer) || other.answer == answer)&&const DeepCollectionEquality().equals(other.answers, _answers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,answer,const DeepCollectionEquality().hash(_answers));
}

@override
String toString() {
    return 'Reveal(answer: $answer, answers: $answers)';
}


}

/// @nodoc
abstract mixin class _$RevealCopyWith<$Res> implements $RevealCopyWith<$Res> {
  factory _$RevealCopyWith(_Reveal value, $Res Function(_Reveal) _then) = __$RevealCopyWithImpl;
@override @useResult
$Res call({
 String? answer, List<RevealAnswer> answers
});




}
/// @nodoc
class __$RevealCopyWithImpl<$Res>
    implements _$RevealCopyWith<$Res> {
  __$RevealCopyWithImpl(this._self, this._then);

  final _Reveal _self;
  final $Res Function(_Reveal) _then;

/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? answer = freezed,Object? answers = null,}) {
  return _then(_Reveal(
answer: freezed == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String?,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as List<RevealAnswer>,
  ));
}


}


/// @nodoc
mixin _$RevealAnswer {

 int get peerId; String? get text; int get wager; bool get correct; int? get score;
/// Create a copy of RevealAnswer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevealAnswerCopyWith<RevealAnswer> get copyWith => _$RevealAnswerCopyWithImpl<RevealAnswer>(this as RevealAnswer, _$identity);

  /// Serializes this RevealAnswer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RevealAnswer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RevealAnswer&&(identical(other.peerId, _this.peerId) || other.peerId == _this.peerId)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.wager, _this.wager) || other.wager == _this.wager)&&(identical(other.correct, _this.correct) || other.correct == _this.correct)&&(identical(other.score, _this.score) || other.score == _this.score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RevealAnswer;
  return Object.hash(runtimeType,_this.peerId,_this.text,_this.wager,_this.correct,_this.score);
}

@override
String toString() {
  final _this = this as RevealAnswer;
  return 'RevealAnswer(peerId: ${_this.peerId}, text: ${_this.text}, wager: ${_this.wager}, correct: ${_this.correct}, score: ${_this.score})';
}


}

/// @nodoc
abstract mixin class $RevealAnswerCopyWith<$Res>  {
  factory $RevealAnswerCopyWith(RevealAnswer value, $Res Function(RevealAnswer) _then) = _$RevealAnswerCopyWithImpl;
@useResult
$Res call({
 int peerId, String? text, int wager, bool correct, int? score
});




}
/// @nodoc
class _$RevealAnswerCopyWithImpl<$Res>
    implements $RevealAnswerCopyWith<$Res> {
  _$RevealAnswerCopyWithImpl(this._self, this._then);

  final RevealAnswer _self;
  final $Res Function(RevealAnswer) _then;

/// Create a copy of RevealAnswer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? peerId = null,Object? text = freezed,Object? wager = null,Object? correct = null,Object? score = freezed,}) {
  return _then(RevealAnswer(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,wager: null == wager ? _self.wager : wager // ignore: cast_nullable_to_non_nullable
as int,correct: null == correct ? _self.correct : correct // ignore: cast_nullable_to_non_nullable
as bool,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RevealAnswer].
extension RevealAnswerPatterns on RevealAnswer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RevealAnswer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RevealAnswer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RevealAnswer value)  $default,){
final _that = this;
switch (_that) {
case _RevealAnswer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RevealAnswer value)?  $default,){
final _that = this;
switch (_that) {
case _RevealAnswer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int peerId,  String? text,  int wager,  bool correct,  int? score)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RevealAnswer() when $default != null:
return $default(_that.peerId,_that.text,_that.wager,_that.correct,_that.score);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int peerId,  String? text,  int wager,  bool correct,  int? score)  $default,) {final _that = this;
switch (_that) {
case _RevealAnswer():
return $default(_that.peerId,_that.text,_that.wager,_that.correct,_that.score);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int peerId,  String? text,  int wager,  bool correct,  int? score)?  $default,) {final _that = this;
switch (_that) {
case _RevealAnswer() when $default != null:
return $default(_that.peerId,_that.text,_that.wager,_that.correct,_that.score);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RevealAnswer implements RevealAnswer {
  const _RevealAnswer({required this.peerId, this.text, this.wager = 0, this.correct = false, this.score});
  factory _RevealAnswer.fromJson(Map<String, dynamic> json) => _$RevealAnswerFromJson(json);

@override final  int peerId;
@override final  String? text;
@override@JsonKey() final  int wager;
@override@JsonKey() final  bool correct;
@override final  int? score;

/// Create a copy of RevealAnswer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevealAnswerCopyWith<_RevealAnswer> get copyWith => __$RevealAnswerCopyWithImpl<_RevealAnswer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevealAnswerToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RevealAnswer&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.text, text) || other.text == text)&&(identical(other.wager, wager) || other.wager == wager)&&(identical(other.correct, correct) || other.correct == correct)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,peerId,text,wager,correct,score);
}

@override
String toString() {
    return 'RevealAnswer(peerId: $peerId, text: $text, wager: $wager, correct: $correct, score: $score)';
}


}

/// @nodoc
abstract mixin class _$RevealAnswerCopyWith<$Res> implements $RevealAnswerCopyWith<$Res> {
  factory _$RevealAnswerCopyWith(_RevealAnswer value, $Res Function(_RevealAnswer) _then) = __$RevealAnswerCopyWithImpl;
@override @useResult
$Res call({
 int peerId, String? text, int wager, bool correct, int? score
});




}
/// @nodoc
class __$RevealAnswerCopyWithImpl<$Res>
    implements _$RevealAnswerCopyWith<$Res> {
  __$RevealAnswerCopyWithImpl(this._self, this._then);

  final _RevealAnswer _self;
  final $Res Function(_RevealAnswer) _then;

/// Create a copy of RevealAnswer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? peerId = null,Object? text = freezed,Object? wager = null,Object? correct = null,Object? score = freezed,}) {
  return _then(_RevealAnswer(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,wager: null == wager ? _self.wager : wager // ignore: cast_nullable_to_non_nullable
as int,correct: null == correct ? _self.correct : correct // ignore: cast_nullable_to_non_nullable
as bool,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$FinalRound {

 Map<String, int> get votes; String? get picked; String? get vote;/// The next game's code, when it started without this player: Play Again
/// joins it (since 1.2).
 String? get nextGameCode; int? get wager; List<FinalWager> get wagers;
/// Create a copy of FinalRound
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinalRoundCopyWith<FinalRound> get copyWith => _$FinalRoundCopyWithImpl<FinalRound>(this as FinalRound, _$identity);

  /// Serializes this FinalRound to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FinalRound;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinalRound&&const DeepCollectionEquality().equals(other.votes, _this.votes)&&(identical(other.picked, _this.picked) || other.picked == _this.picked)&&(identical(other.vote, _this.vote) || other.vote == _this.vote)&&(identical(other.nextGameCode, _this.nextGameCode) || other.nextGameCode == _this.nextGameCode)&&(identical(other.wager, _this.wager) || other.wager == _this.wager)&&const DeepCollectionEquality().equals(other.wagers, _this.wagers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FinalRound;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.votes),_this.picked,_this.vote,_this.nextGameCode,_this.wager,const DeepCollectionEquality().hash(_this.wagers));
}

@override
String toString() {
  final _this = this as FinalRound;
  return 'FinalRound(votes: ${_this.votes}, picked: ${_this.picked}, vote: ${_this.vote}, nextGameCode: ${_this.nextGameCode}, wager: ${_this.wager}, wagers: ${_this.wagers})';
}


}

/// @nodoc
abstract mixin class $FinalRoundCopyWith<$Res>  {
  factory $FinalRoundCopyWith(FinalRound value, $Res Function(FinalRound) _then) = _$FinalRoundCopyWithImpl;
@useResult
$Res call({
 Map<String, int> votes, String? picked, String? vote, String? nextGameCode, int? wager, List<FinalWager> wagers
});




}
/// @nodoc
class _$FinalRoundCopyWithImpl<$Res>
    implements $FinalRoundCopyWith<$Res> {
  _$FinalRoundCopyWithImpl(this._self, this._then);

  final FinalRound _self;
  final $Res Function(FinalRound) _then;

/// Create a copy of FinalRound
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? votes = null,Object? picked = freezed,Object? vote = freezed,Object? nextGameCode = freezed,Object? wager = freezed,Object? wagers = null,}) {
  return _then(FinalRound(
votes: null == votes ? _self.votes : votes // ignore: cast_nullable_to_non_nullable
as Map<String, int>,picked: freezed == picked ? _self.picked : picked // ignore: cast_nullable_to_non_nullable
as String?,vote: freezed == vote ? _self.vote : vote // ignore: cast_nullable_to_non_nullable
as String?,nextGameCode: freezed == nextGameCode ? _self.nextGameCode : nextGameCode // ignore: cast_nullable_to_non_nullable
as String?,wager: freezed == wager ? _self.wager : wager // ignore: cast_nullable_to_non_nullable
as int?,wagers: null == wagers ? _self.wagers : wagers // ignore: cast_nullable_to_non_nullable
as List<FinalWager>,
  ));
}

}


/// Adds pattern-matching-related methods to [FinalRound].
extension FinalRoundPatterns on FinalRound {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinalRound value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinalRound() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinalRound value)  $default,){
final _that = this;
switch (_that) {
case _FinalRound():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinalRound value)?  $default,){
final _that = this;
switch (_that) {
case _FinalRound() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, int> votes,  String? picked,  String? vote,  String? nextGameCode,  int? wager,  List<FinalWager> wagers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinalRound() when $default != null:
return $default(_that.votes,_that.picked,_that.vote,_that.nextGameCode,_that.wager,_that.wagers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, int> votes,  String? picked,  String? vote,  String? nextGameCode,  int? wager,  List<FinalWager> wagers)  $default,) {final _that = this;
switch (_that) {
case _FinalRound():
return $default(_that.votes,_that.picked,_that.vote,_that.nextGameCode,_that.wager,_that.wagers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, int> votes,  String? picked,  String? vote,  String? nextGameCode,  int? wager,  List<FinalWager> wagers)?  $default,) {final _that = this;
switch (_that) {
case _FinalRound() when $default != null:
return $default(_that.votes,_that.picked,_that.vote,_that.nextGameCode,_that.wager,_that.wagers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinalRound implements FinalRound {
  const _FinalRound({ Map<String, int> votes = const <String, int>{}, this.picked, this.vote, this.nextGameCode, this.wager,  List<FinalWager> wagers = const <FinalWager>[]}): _votes = votes,_wagers = wagers;
  factory _FinalRound.fromJson(Map<String, dynamic> json) => _$FinalRoundFromJson(json);

 final  Map<String, int> _votes;
@override@JsonKey() Map<String, int> get votes {
  if (_votes is EqualUnmodifiableMapView) return _votes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_votes);
}

@override final  String? picked;
@override final  String? vote;
/// The next game's code, when it started without this player: Play Again
/// joins it (since 1.2).
@override final  String? nextGameCode;
@override final  int? wager;
 final  List<FinalWager> _wagers;
@override@JsonKey() List<FinalWager> get wagers {
  if (_wagers is EqualUnmodifiableListView) return _wagers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_wagers);
}


/// Create a copy of FinalRound
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinalRoundCopyWith<_FinalRound> get copyWith => __$FinalRoundCopyWithImpl<_FinalRound>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinalRoundToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinalRound&&const DeepCollectionEquality().equals(other.votes, _votes)&&(identical(other.picked, picked) || other.picked == picked)&&(identical(other.vote, vote) || other.vote == vote)&&(identical(other.nextGameCode, nextGameCode) || other.nextGameCode == nextGameCode)&&(identical(other.wager, wager) || other.wager == wager)&&const DeepCollectionEquality().equals(other.wagers, _wagers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_votes),picked,vote,nextGameCode,wager,const DeepCollectionEquality().hash(_wagers));
}

@override
String toString() {
    return 'FinalRound(votes: $votes, picked: $picked, vote: $vote, nextGameCode: $nextGameCode, wager: $wager, wagers: $wagers)';
}


}

/// @nodoc
abstract mixin class _$FinalRoundCopyWith<$Res> implements $FinalRoundCopyWith<$Res> {
  factory _$FinalRoundCopyWith(_FinalRound value, $Res Function(_FinalRound) _then) = __$FinalRoundCopyWithImpl;
@override @useResult
$Res call({
 Map<String, int> votes, String? picked, String? vote, String? nextGameCode, int? wager, List<FinalWager> wagers
});




}
/// @nodoc
class __$FinalRoundCopyWithImpl<$Res>
    implements _$FinalRoundCopyWith<$Res> {
  __$FinalRoundCopyWithImpl(this._self, this._then);

  final _FinalRound _self;
  final $Res Function(_FinalRound) _then;

/// Create a copy of FinalRound
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? votes = null,Object? picked = freezed,Object? vote = freezed,Object? nextGameCode = freezed,Object? wager = freezed,Object? wagers = null,}) {
  return _then(_FinalRound(
votes: null == votes ? _self._votes : votes // ignore: cast_nullable_to_non_nullable
as Map<String, int>,picked: freezed == picked ? _self.picked : picked // ignore: cast_nullable_to_non_nullable
as String?,vote: freezed == vote ? _self.vote : vote // ignore: cast_nullable_to_non_nullable
as String?,nextGameCode: freezed == nextGameCode ? _self.nextGameCode : nextGameCode // ignore: cast_nullable_to_non_nullable
as String?,wager: freezed == wager ? _self.wager : wager // ignore: cast_nullable_to_non_nullable
as int?,wagers: null == wagers ? _self._wagers : wagers // ignore: cast_nullable_to_non_nullable
as List<FinalWager>,
  ));
}


}


/// @nodoc
mixin _$Notice {

 String get kind;/// `info`, `warn`, `error` or `success`.
 String get level; String? get title; String? get message; int get until;
/// Create a copy of Notice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoticeCopyWith<Notice> get copyWith => _$NoticeCopyWithImpl<Notice>(this as Notice, _$identity);

  /// Serializes this Notice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Notice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Notice&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.until, _this.until) || other.until == _this.until));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Notice;
  return Object.hash(runtimeType,_this.kind,_this.level,_this.title,_this.message,_this.until);
}

@override
String toString() {
  final _this = this as Notice;
  return 'Notice(kind: ${_this.kind}, level: ${_this.level}, title: ${_this.title}, message: ${_this.message}, until: ${_this.until})';
}


}

/// @nodoc
abstract mixin class $NoticeCopyWith<$Res>  {
  factory $NoticeCopyWith(Notice value, $Res Function(Notice) _then) = _$NoticeCopyWithImpl;
@useResult
$Res call({
 String kind, String level, String? title, String? message, int until
});




}
/// @nodoc
class _$NoticeCopyWithImpl<$Res>
    implements $NoticeCopyWith<$Res> {
  _$NoticeCopyWithImpl(this._self, this._then);

  final Notice _self;
  final $Res Function(Notice) _then;

/// Create a copy of Notice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? level = null,Object? title = freezed,Object? message = freezed,Object? until = null,}) {
  return _then(Notice(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Notice].
extension NoticePatterns on Notice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Notice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Notice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Notice value)  $default,){
final _that = this;
switch (_that) {
case _Notice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Notice value)?  $default,){
final _that = this;
switch (_that) {
case _Notice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String level,  String? title,  String? message,  int until)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Notice() when $default != null:
return $default(_that.kind,_that.level,_that.title,_that.message,_that.until);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String level,  String? title,  String? message,  int until)  $default,) {final _that = this;
switch (_that) {
case _Notice():
return $default(_that.kind,_that.level,_that.title,_that.message,_that.until);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String level,  String? title,  String? message,  int until)?  $default,) {final _that = this;
switch (_that) {
case _Notice() when $default != null:
return $default(_that.kind,_that.level,_that.title,_that.message,_that.until);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Notice implements Notice {
  const _Notice({required this.kind, this.level = 'info', this.title, this.message, required this.until});
  factory _Notice.fromJson(Map<String, dynamic> json) => _$NoticeFromJson(json);

@override final  String kind;
/// `info`, `warn`, `error` or `success`.
@override@JsonKey() final  String level;
@override final  String? title;
@override final  String? message;
@override final  int until;

/// Create a copy of Notice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoticeCopyWith<_Notice> get copyWith => __$NoticeCopyWithImpl<_Notice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoticeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Notice&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.level, level) || other.level == level)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.until, until) || other.until == until));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,level,title,message,until);
}

@override
String toString() {
    return 'Notice(kind: $kind, level: $level, title: $title, message: $message, until: $until)';
}


}

/// @nodoc
abstract mixin class _$NoticeCopyWith<$Res> implements $NoticeCopyWith<$Res> {
  factory _$NoticeCopyWith(_Notice value, $Res Function(_Notice) _then) = __$NoticeCopyWithImpl;
@override @useResult
$Res call({
 String kind, String level, String? title, String? message, int until
});




}
/// @nodoc
class __$NoticeCopyWithImpl<$Res>
    implements _$NoticeCopyWith<$Res> {
  __$NoticeCopyWithImpl(this._self, this._then);

  final _Notice _self;
  final $Res Function(_Notice) _then;

/// Create a copy of Notice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? level = null,Object? title = freezed,Object? message = freezed,Object? until = null,}) {
  return _then(_Notice(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StartCountdown {

 String get kind; int get until;
/// Create a copy of StartCountdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartCountdownCopyWith<StartCountdown> get copyWith => _$StartCountdownCopyWithImpl<StartCountdown>(this as StartCountdown, _$identity);

  /// Serializes this StartCountdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StartCountdown;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartCountdown&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.until, _this.until) || other.until == _this.until));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StartCountdown;
  return Object.hash(runtimeType,_this.kind,_this.until);
}

@override
String toString() {
  final _this = this as StartCountdown;
  return 'StartCountdown(kind: ${_this.kind}, until: ${_this.until})';
}


}

/// @nodoc
abstract mixin class $StartCountdownCopyWith<$Res>  {
  factory $StartCountdownCopyWith(StartCountdown value, $Res Function(StartCountdown) _then) = _$StartCountdownCopyWithImpl;
@useResult
$Res call({
 String kind, int until
});




}
/// @nodoc
class _$StartCountdownCopyWithImpl<$Res>
    implements $StartCountdownCopyWith<$Res> {
  _$StartCountdownCopyWithImpl(this._self, this._then);

  final StartCountdown _self;
  final $Res Function(StartCountdown) _then;

/// Create a copy of StartCountdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? until = null,}) {
  return _then(StartCountdown(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StartCountdown].
extension StartCountdownPatterns on StartCountdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StartCountdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StartCountdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StartCountdown value)  $default,){
final _that = this;
switch (_that) {
case _StartCountdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StartCountdown value)?  $default,){
final _that = this;
switch (_that) {
case _StartCountdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  int until)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StartCountdown() when $default != null:
return $default(_that.kind,_that.until);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  int until)  $default,) {final _that = this;
switch (_that) {
case _StartCountdown():
return $default(_that.kind,_that.until);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  int until)?  $default,) {final _that = this;
switch (_that) {
case _StartCountdown() when $default != null:
return $default(_that.kind,_that.until);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StartCountdown implements StartCountdown {
  const _StartCountdown({required this.kind, required this.until});
  factory _StartCountdown.fromJson(Map<String, dynamic> json) => _$StartCountdownFromJson(json);

@override final  String kind;
@override final  int until;

/// Create a copy of StartCountdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StartCountdownCopyWith<_StartCountdown> get copyWith => __$StartCountdownCopyWithImpl<_StartCountdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StartCountdownToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartCountdown&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.until, until) || other.until == until));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,until);
}

@override
String toString() {
    return 'StartCountdown(kind: $kind, until: $until)';
}


}

/// @nodoc
abstract mixin class _$StartCountdownCopyWith<$Res> implements $StartCountdownCopyWith<$Res> {
  factory _$StartCountdownCopyWith(_StartCountdown value, $Res Function(_StartCountdown) _then) = __$StartCountdownCopyWithImpl;
@override @useResult
$Res call({
 String kind, int until
});




}
/// @nodoc
class __$StartCountdownCopyWithImpl<$Res>
    implements _$StartCountdownCopyWith<$Res> {
  __$StartCountdownCopyWithImpl(this._self, this._then);

  final _StartCountdown _self;
  final $Res Function(_StartCountdown) _then;

/// Create a copy of StartCountdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? until = null,}) {
  return _then(_StartCountdown(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PackVote {

 Pack get pack; int get votes; List<int> get voters;/// This player voted for it.
 bool get you;
/// Create a copy of PackVote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackVoteCopyWith<PackVote> get copyWith => _$PackVoteCopyWithImpl<PackVote>(this as PackVote, _$identity);

  /// Serializes this PackVote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PackVote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PackVote&&(identical(other.pack, _this.pack) || other.pack == _this.pack)&&(identical(other.votes, _this.votes) || other.votes == _this.votes)&&const DeepCollectionEquality().equals(other.voters, _this.voters)&&(identical(other.you, _this.you) || other.you == _this.you));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PackVote;
  return Object.hash(runtimeType,_this.pack,_this.votes,const DeepCollectionEquality().hash(_this.voters),_this.you);
}

@override
String toString() {
  final _this = this as PackVote;
  return 'PackVote(pack: ${_this.pack}, votes: ${_this.votes}, voters: ${_this.voters}, you: ${_this.you})';
}


}

/// @nodoc
abstract mixin class $PackVoteCopyWith<$Res>  {
  factory $PackVoteCopyWith(PackVote value, $Res Function(PackVote) _then) = _$PackVoteCopyWithImpl;
@useResult
$Res call({
 Pack pack, int votes, List<int> voters, bool you
});


$PackCopyWith<$Res> get pack;

}
/// @nodoc
class _$PackVoteCopyWithImpl<$Res>
    implements $PackVoteCopyWith<$Res> {
  _$PackVoteCopyWithImpl(this._self, this._then);

  final PackVote _self;
  final $Res Function(PackVote) _then;

/// Create a copy of PackVote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pack = null,Object? votes = null,Object? voters = null,Object? you = null,}) {
  return _then(PackVote(
pack: null == pack ? _self.pack : pack // ignore: cast_nullable_to_non_nullable
as Pack,votes: null == votes ? _self.votes : votes // ignore: cast_nullable_to_non_nullable
as int,voters: null == voters ? _self.voters : voters // ignore: cast_nullable_to_non_nullable
as List<int>,you: null == you ? _self.you : you // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PackVote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PackCopyWith<$Res> get pack {
  
  return $PackCopyWith<$Res>(_self.pack, (value) {
    return _then(_self.copyWith(pack: value));
  });
}
}


/// Adds pattern-matching-related methods to [PackVote].
extension PackVotePatterns on PackVote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PackVote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PackVote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PackVote value)  $default,){
final _that = this;
switch (_that) {
case _PackVote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PackVote value)?  $default,){
final _that = this;
switch (_that) {
case _PackVote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Pack pack,  int votes,  List<int> voters,  bool you)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PackVote() when $default != null:
return $default(_that.pack,_that.votes,_that.voters,_that.you);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Pack pack,  int votes,  List<int> voters,  bool you)  $default,) {final _that = this;
switch (_that) {
case _PackVote():
return $default(_that.pack,_that.votes,_that.voters,_that.you);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Pack pack,  int votes,  List<int> voters,  bool you)?  $default,) {final _that = this;
switch (_that) {
case _PackVote() when $default != null:
return $default(_that.pack,_that.votes,_that.voters,_that.you);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PackVote implements PackVote {
  const _PackVote({required this.pack, this.votes = 0,  List<int> voters = const <int>[], this.you = false}): _voters = voters;
  factory _PackVote.fromJson(Map<String, dynamic> json) => _$PackVoteFromJson(json);

@override final  Pack pack;
@override@JsonKey() final  int votes;
 final  List<int> _voters;
@override@JsonKey() List<int> get voters {
  if (_voters is EqualUnmodifiableListView) return _voters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_voters);
}

/// This player voted for it.
@override@JsonKey() final  bool you;

/// Create a copy of PackVote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackVoteCopyWith<_PackVote> get copyWith => __$PackVoteCopyWithImpl<_PackVote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PackVoteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PackVote&&(identical(other.pack, pack) || other.pack == pack)&&(identical(other.votes, votes) || other.votes == votes)&&const DeepCollectionEquality().equals(other.voters, _voters)&&(identical(other.you, you) || other.you == you));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,pack,votes,const DeepCollectionEquality().hash(_voters),you);
}

@override
String toString() {
    return 'PackVote(pack: $pack, votes: $votes, voters: $voters, you: $you)';
}


}

/// @nodoc
abstract mixin class _$PackVoteCopyWith<$Res> implements $PackVoteCopyWith<$Res> {
  factory _$PackVoteCopyWith(_PackVote value, $Res Function(_PackVote) _then) = __$PackVoteCopyWithImpl;
@override @useResult
$Res call({
 Pack pack, int votes, List<int> voters, bool you
});


@override $PackCopyWith<$Res> get pack;

}
/// @nodoc
class __$PackVoteCopyWithImpl<$Res>
    implements _$PackVoteCopyWith<$Res> {
  __$PackVoteCopyWithImpl(this._self, this._then);

  final _PackVote _self;
  final $Res Function(_PackVote) _then;

/// Create a copy of PackVote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pack = null,Object? votes = null,Object? voters = null,Object? you = null,}) {
  return _then(_PackVote(
pack: null == pack ? _self.pack : pack // ignore: cast_nullable_to_non_nullable
as Pack,votes: null == votes ? _self.votes : votes // ignore: cast_nullable_to_non_nullable
as int,voters: null == voters ? _self._voters : voters // ignore: cast_nullable_to_non_nullable
as List<int>,you: null == you ? _self.you : you // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PackVote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PackCopyWith<$Res> get pack {
  
  return $PackCopyWith<$Res>(_self.pack, (value) {
    return _then(_self.copyWith(pack: value));
  });
}
}


/// @nodoc
mixin _$FinalWager {

 int get peerId; int get wager;
/// Create a copy of FinalWager
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinalWagerCopyWith<FinalWager> get copyWith => _$FinalWagerCopyWithImpl<FinalWager>(this as FinalWager, _$identity);

  /// Serializes this FinalWager to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FinalWager;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinalWager&&(identical(other.peerId, _this.peerId) || other.peerId == _this.peerId)&&(identical(other.wager, _this.wager) || other.wager == _this.wager));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FinalWager;
  return Object.hash(runtimeType,_this.peerId,_this.wager);
}

@override
String toString() {
  final _this = this as FinalWager;
  return 'FinalWager(peerId: ${_this.peerId}, wager: ${_this.wager})';
}


}

/// @nodoc
abstract mixin class $FinalWagerCopyWith<$Res>  {
  factory $FinalWagerCopyWith(FinalWager value, $Res Function(FinalWager) _then) = _$FinalWagerCopyWithImpl;
@useResult
$Res call({
 int peerId, int wager
});




}
/// @nodoc
class _$FinalWagerCopyWithImpl<$Res>
    implements $FinalWagerCopyWith<$Res> {
  _$FinalWagerCopyWithImpl(this._self, this._then);

  final FinalWager _self;
  final $Res Function(FinalWager) _then;

/// Create a copy of FinalWager
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? peerId = null,Object? wager = null,}) {
  return _then(FinalWager(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int,wager: null == wager ? _self.wager : wager // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FinalWager].
extension FinalWagerPatterns on FinalWager {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinalWager value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinalWager() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinalWager value)  $default,){
final _that = this;
switch (_that) {
case _FinalWager():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinalWager value)?  $default,){
final _that = this;
switch (_that) {
case _FinalWager() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int peerId,  int wager)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinalWager() when $default != null:
return $default(_that.peerId,_that.wager);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int peerId,  int wager)  $default,) {final _that = this;
switch (_that) {
case _FinalWager():
return $default(_that.peerId,_that.wager);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int peerId,  int wager)?  $default,) {final _that = this;
switch (_that) {
case _FinalWager() when $default != null:
return $default(_that.peerId,_that.wager);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinalWager implements FinalWager {
  const _FinalWager({required this.peerId, required this.wager});
  factory _FinalWager.fromJson(Map<String, dynamic> json) => _$FinalWagerFromJson(json);

@override final  int peerId;
@override final  int wager;

/// Create a copy of FinalWager
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinalWagerCopyWith<_FinalWager> get copyWith => __$FinalWagerCopyWithImpl<_FinalWager>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinalWagerToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinalWager&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.wager, wager) || other.wager == wager));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,peerId,wager);
}

@override
String toString() {
    return 'FinalWager(peerId: $peerId, wager: $wager)';
}


}

/// @nodoc
abstract mixin class _$FinalWagerCopyWith<$Res> implements $FinalWagerCopyWith<$Res> {
  factory _$FinalWagerCopyWith(_FinalWager value, $Res Function(_FinalWager) _then) = __$FinalWagerCopyWithImpl;
@override @useResult
$Res call({
 int peerId, int wager
});




}
/// @nodoc
class __$FinalWagerCopyWithImpl<$Res>
    implements _$FinalWagerCopyWith<$Res> {
  __$FinalWagerCopyWithImpl(this._self, this._then);

  final _FinalWager _self;
  final $Res Function(_FinalWager) _then;

/// Create a copy of FinalWager
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? peerId = null,Object? wager = null,}) {
  return _then(_FinalWager(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int,wager: null == wager ? _self.wager : wager // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PlayerReactions {

 int get total; List<String> get recent;
/// Create a copy of PlayerReactions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerReactionsCopyWith<PlayerReactions> get copyWith => _$PlayerReactionsCopyWithImpl<PlayerReactions>(this as PlayerReactions, _$identity);

  /// Serializes this PlayerReactions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlayerReactions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerReactions&&(identical(other.total, _this.total) || other.total == _this.total)&&const DeepCollectionEquality().equals(other.recent, _this.recent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlayerReactions;
  return Object.hash(runtimeType,_this.total,const DeepCollectionEquality().hash(_this.recent));
}

@override
String toString() {
  final _this = this as PlayerReactions;
  return 'PlayerReactions(total: ${_this.total}, recent: ${_this.recent})';
}


}

/// @nodoc
abstract mixin class $PlayerReactionsCopyWith<$Res>  {
  factory $PlayerReactionsCopyWith(PlayerReactions value, $Res Function(PlayerReactions) _then) = _$PlayerReactionsCopyWithImpl;
@useResult
$Res call({
 int total, List<String> recent
});




}
/// @nodoc
class _$PlayerReactionsCopyWithImpl<$Res>
    implements $PlayerReactionsCopyWith<$Res> {
  _$PlayerReactionsCopyWithImpl(this._self, this._then);

  final PlayerReactions _self;
  final $Res Function(PlayerReactions) _then;

/// Create a copy of PlayerReactions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? recent = null,}) {
  return _then(PlayerReactions(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,recent: null == recent ? _self.recent : recent // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerReactions].
extension PlayerReactionsPatterns on PlayerReactions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerReactions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerReactions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerReactions value)  $default,){
final _that = this;
switch (_that) {
case _PlayerReactions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerReactions value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerReactions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  List<String> recent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerReactions() when $default != null:
return $default(_that.total,_that.recent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  List<String> recent)  $default,) {final _that = this;
switch (_that) {
case _PlayerReactions():
return $default(_that.total,_that.recent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  List<String> recent)?  $default,) {final _that = this;
switch (_that) {
case _PlayerReactions() when $default != null:
return $default(_that.total,_that.recent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerReactions implements PlayerReactions {
  const _PlayerReactions({this.total = 0,  List<String> recent = const <String>[]}): _recent = recent;
  factory _PlayerReactions.fromJson(Map<String, dynamic> json) => _$PlayerReactionsFromJson(json);

@override@JsonKey() final  int total;
 final  List<String> _recent;
@override@JsonKey() List<String> get recent {
  if (_recent is EqualUnmodifiableListView) return _recent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recent);
}


/// Create a copy of PlayerReactions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerReactionsCopyWith<_PlayerReactions> get copyWith => __$PlayerReactionsCopyWithImpl<_PlayerReactions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerReactionsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerReactions&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.recent, _recent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,total,const DeepCollectionEquality().hash(_recent));
}

@override
String toString() {
    return 'PlayerReactions(total: $total, recent: $recent)';
}


}

/// @nodoc
abstract mixin class _$PlayerReactionsCopyWith<$Res> implements $PlayerReactionsCopyWith<$Res> {
  factory _$PlayerReactionsCopyWith(_PlayerReactions value, $Res Function(_PlayerReactions) _then) = __$PlayerReactionsCopyWithImpl;
@override @useResult
$Res call({
 int total, List<String> recent
});




}
/// @nodoc
class __$PlayerReactionsCopyWithImpl<$Res>
    implements _$PlayerReactionsCopyWith<$Res> {
  __$PlayerReactionsCopyWithImpl(this._self, this._then);

  final _PlayerReactions _self;
  final $Res Function(_PlayerReactions) _then;

/// Create a copy of PlayerReactions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? recent = null,}) {
  return _then(_PlayerReactions(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,recent: null == recent ? _self._recent : recent // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$Reaction {

 int get id; int? get peerId; String get type; int get until;
/// Create a copy of Reaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReactionCopyWith<Reaction> get copyWith => _$ReactionCopyWithImpl<Reaction>(this as Reaction, _$identity);

  /// Serializes this Reaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Reaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reaction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.peerId, _this.peerId) || other.peerId == _this.peerId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.until, _this.until) || other.until == _this.until));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Reaction;
  return Object.hash(runtimeType,_this.id,_this.peerId,_this.type,_this.until);
}

@override
String toString() {
  final _this = this as Reaction;
  return 'Reaction(id: ${_this.id}, peerId: ${_this.peerId}, type: ${_this.type}, until: ${_this.until})';
}


}

/// @nodoc
abstract mixin class $ReactionCopyWith<$Res>  {
  factory $ReactionCopyWith(Reaction value, $Res Function(Reaction) _then) = _$ReactionCopyWithImpl;
@useResult
$Res call({
 int id, int? peerId, String type, int until
});




}
/// @nodoc
class _$ReactionCopyWithImpl<$Res>
    implements $ReactionCopyWith<$Res> {
  _$ReactionCopyWithImpl(this._self, this._then);

  final Reaction _self;
  final $Res Function(Reaction) _then;

/// Create a copy of Reaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? peerId = freezed,Object? type = null,Object? until = null,}) {
  return _then(Reaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Reaction].
extension ReactionPatterns on Reaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reaction value)  $default,){
final _that = this;
switch (_that) {
case _Reaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reaction value)?  $default,){
final _that = this;
switch (_that) {
case _Reaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int? peerId,  String type,  int until)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reaction() when $default != null:
return $default(_that.id,_that.peerId,_that.type,_that.until);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int? peerId,  String type,  int until)  $default,) {final _that = this;
switch (_that) {
case _Reaction():
return $default(_that.id,_that.peerId,_that.type,_that.until);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int? peerId,  String type,  int until)?  $default,) {final _that = this;
switch (_that) {
case _Reaction() when $default != null:
return $default(_that.id,_that.peerId,_that.type,_that.until);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reaction implements Reaction {
  const _Reaction({required this.id, this.peerId, required this.type, required this.until});
  factory _Reaction.fromJson(Map<String, dynamic> json) => _$ReactionFromJson(json);

@override final  int id;
@override final  int? peerId;
@override final  String type;
@override final  int until;

/// Create a copy of Reaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReactionCopyWith<_Reaction> get copyWith => __$ReactionCopyWithImpl<_Reaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReactionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reaction&&(identical(other.id, id) || other.id == id)&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.type, type) || other.type == type)&&(identical(other.until, until) || other.until == until));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,peerId,type,until);
}

@override
String toString() {
    return 'Reaction(id: $id, peerId: $peerId, type: $type, until: $until)';
}


}

/// @nodoc
abstract mixin class _$ReactionCopyWith<$Res> implements $ReactionCopyWith<$Res> {
  factory _$ReactionCopyWith(_Reaction value, $Res Function(_Reaction) _then) = __$ReactionCopyWithImpl;
@override @useResult
$Res call({
 int id, int? peerId, String type, int until
});




}
/// @nodoc
class __$ReactionCopyWithImpl<$Res>
    implements _$ReactionCopyWith<$Res> {
  __$ReactionCopyWithImpl(this._self, this._then);

  final _Reaction _self;
  final $Res Function(_Reaction) _then;

/// Create a copy of Reaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? peerId = freezed,Object? type = null,Object? until = null,}) {
  return _then(_Reaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ChatState {

 List<ChatMessage> get messages;/// Other players' messages since the chat was last open.
 int get unread;/// The names of the others typing.
 List<String> get typing;/// An app joined to the seat shows the chat.
 bool get open;/// There is more before the first message.
 bool get hasMore;/// The relay is fetching earlier messages.
 bool get loading;
/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStateCopyWith<ChatState> get copyWith => _$ChatStateCopyWithImpl<ChatState>(this as ChatState, _$identity);

  /// Serializes this ChatState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatState&&const DeepCollectionEquality().equals(other.messages, _this.messages)&&(identical(other.unread, _this.unread) || other.unread == _this.unread)&&const DeepCollectionEquality().equals(other.typing, _this.typing)&&(identical(other.open, _this.open) || other.open == _this.open)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore)&&(identical(other.loading, _this.loading) || other.loading == _this.loading));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.messages),_this.unread,const DeepCollectionEquality().hash(_this.typing),_this.open,_this.hasMore,_this.loading);
}

@override
String toString() {
  final _this = this as ChatState;
  return 'ChatState(messages: ${_this.messages}, unread: ${_this.unread}, typing: ${_this.typing}, open: ${_this.open}, hasMore: ${_this.hasMore}, loading: ${_this.loading})';
}


}

/// @nodoc
abstract mixin class $ChatStateCopyWith<$Res>  {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) _then) = _$ChatStateCopyWithImpl;
@useResult
$Res call({
 List<ChatMessage> messages, int unread, List<String> typing, bool open, bool hasMore, bool loading
});




}
/// @nodoc
class _$ChatStateCopyWithImpl<$Res>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._self, this._then);

  final ChatState _self;
  final $Res Function(ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? unread = null,Object? typing = null,Object? open = null,Object? hasMore = null,Object? loading = null,}) {
  return _then(ChatState(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as int,typing: null == typing ? _self.typing : typing // ignore: cast_nullable_to_non_nullable
as List<String>,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatState].
extension ChatStatePatterns on ChatState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatState value)  $default,){
final _that = this;
switch (_that) {
case _ChatState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatState value)?  $default,){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ChatMessage> messages,  int unread,  List<String> typing,  bool open,  bool hasMore,  bool loading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.messages,_that.unread,_that.typing,_that.open,_that.hasMore,_that.loading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ChatMessage> messages,  int unread,  List<String> typing,  bool open,  bool hasMore,  bool loading)  $default,) {final _that = this;
switch (_that) {
case _ChatState():
return $default(_that.messages,_that.unread,_that.typing,_that.open,_that.hasMore,_that.loading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ChatMessage> messages,  int unread,  List<String> typing,  bool open,  bool hasMore,  bool loading)?  $default,) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.messages,_that.unread,_that.typing,_that.open,_that.hasMore,_that.loading);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatState extends ChatState {
  const _ChatState({ List<ChatMessage> messages = const <ChatMessage>[], this.unread = 0,  List<String> typing = const <String>[], this.open = false, this.hasMore = false, this.loading = false}): _messages = messages,_typing = typing,super._();
  factory _ChatState.fromJson(Map<String, dynamic> json) => _$ChatStateFromJson(json);

 final  List<ChatMessage> _messages;
@override@JsonKey() List<ChatMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

/// Other players' messages since the chat was last open.
@override@JsonKey() final  int unread;
/// The names of the others typing.
 final  List<String> _typing;
/// The names of the others typing.
@override@JsonKey() List<String> get typing {
  if (_typing is EqualUnmodifiableListView) return _typing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_typing);
}

/// An app joined to the seat shows the chat.
@override@JsonKey() final  bool open;
/// There is more before the first message.
@override@JsonKey() final  bool hasMore;
/// The relay is fetching earlier messages.
@override@JsonKey() final  bool loading;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatStateCopyWith<_ChatState> get copyWith => __$ChatStateCopyWithImpl<_ChatState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatState&&const DeepCollectionEquality().equals(other.messages, _messages)&&(identical(other.unread, unread) || other.unread == unread)&&const DeepCollectionEquality().equals(other.typing, _typing)&&(identical(other.open, open) || other.open == open)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loading, loading) || other.loading == loading));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),unread,const DeepCollectionEquality().hash(_typing),open,hasMore,loading);
}

@override
String toString() {
    return 'ChatState(messages: $messages, unread: $unread, typing: $typing, open: $open, hasMore: $hasMore, loading: $loading)';
}


}

/// @nodoc
abstract mixin class _$ChatStateCopyWith<$Res> implements $ChatStateCopyWith<$Res> {
  factory _$ChatStateCopyWith(_ChatState value, $Res Function(_ChatState) _then) = __$ChatStateCopyWithImpl;
@override @useResult
$Res call({
 List<ChatMessage> messages, int unread, List<String> typing, bool open, bool hasMore, bool loading
});




}
/// @nodoc
class __$ChatStateCopyWithImpl<$Res>
    implements _$ChatStateCopyWith<$Res> {
  __$ChatStateCopyWithImpl(this._self, this._then);

  final _ChatState _self;
  final $Res Function(_ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? unread = null,Object? typing = null,Object? open = null,Object? hasMore = null,Object? loading = null,}) {
  return _then(_ChatState(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as int,typing: null == typing ? _self._typing : typing // ignore: cast_nullable_to_non_nullable
as List<String>,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ChatMessage {

 String get id;/// The sender, while they are in the game.
 int? get peerId;/// The name the message carries; null for the game's own.
 String? get name; String get text; String? get imageUrl;/// The game's own message, not a player's.
 bool get system; int get at;/// This player's.
 bool get own;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.peerId, _this.peerId) || other.peerId == _this.peerId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.system, _this.system) || other.system == _this.system)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.own, _this.own) || other.own == _this.own));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatMessage;
  return Object.hash(runtimeType,_this.id,_this.peerId,_this.name,_this.text,_this.imageUrl,_this.system,_this.at,_this.own);
}

@override
String toString() {
  final _this = this as ChatMessage;
  return 'ChatMessage(id: ${_this.id}, peerId: ${_this.peerId}, name: ${_this.name}, text: ${_this.text}, imageUrl: ${_this.imageUrl}, system: ${_this.system}, at: ${_this.at}, own: ${_this.own})';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, int? peerId, String? name, String text, String? imageUrl, bool system, int at, bool own
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? peerId = freezed,Object? name = freezed,Object? text = null,Object? imageUrl = freezed,Object? system = null,Object? at = null,Object? own = null,}) {
  return _then(ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as bool,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,own: null == own ? _self.own : own // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int? peerId,  String? name,  String text,  String? imageUrl,  bool system,  int at,  bool own)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.peerId,_that.name,_that.text,_that.imageUrl,_that.system,_that.at,_that.own);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int? peerId,  String? name,  String text,  String? imageUrl,  bool system,  int at,  bool own)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.peerId,_that.name,_that.text,_that.imageUrl,_that.system,_that.at,_that.own);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int? peerId,  String? name,  String text,  String? imageUrl,  bool system,  int at,  bool own)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.peerId,_that.name,_that.text,_that.imageUrl,_that.system,_that.at,_that.own);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, this.peerId, this.name, this.text = '', this.imageUrl, this.system = false, this.at = 0, this.own = false});
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  String id;
/// The sender, while they are in the game.
@override final  int? peerId;
/// The name the message carries; null for the game's own.
@override final  String? name;
@override@JsonKey() final  String text;
@override final  String? imageUrl;
/// The game's own message, not a player's.
@override@JsonKey() final  bool system;
@override@JsonKey() final  int at;
/// This player's.
@override@JsonKey() final  bool own;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.text, text) || other.text == text)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.system, system) || other.system == system)&&(identical(other.at, at) || other.at == at)&&(identical(other.own, own) || other.own == own));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,peerId,name,text,imageUrl,system,at,own);
}

@override
String toString() {
    return 'ChatMessage(id: $id, peerId: $peerId, name: $name, text: $text, imageUrl: $imageUrl, system: $system, at: $at, own: $own)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, int? peerId, String? name, String text, String? imageUrl, bool system, int at, bool own
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? peerId = freezed,Object? name = freezed,Object? text = null,Object? imageUrl = freezed,Object? system = null,Object? at = null,Object? own = null,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as bool,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,own: null == own ? _self.own : own // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
