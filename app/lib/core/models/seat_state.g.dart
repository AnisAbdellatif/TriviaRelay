// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seat_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SeatState _$SeatStateFromJson(Map<String, dynamic> json) => _SeatState(
  protocolVersion: (json['protocol_version'] as num).toInt(),
  protocolMinor: (json['protocol_minor'] as num?)?.toInt() ?? 0,
  serverTime: (json['server_time'] as num).toInt(),
  gameCode: json['game_code'] as String,
  status: $enumDecode(_$SeatStatusEnumMap, json['status']),
  phase: $enumDecode(_$PhaseEnumMap, json['phase']),
  pack: json['pack'] == null
      ? null
      : Pack.fromJson(json['pack'] as Map<String, dynamic>),
  options: GameOptions.fromJson(json['options'] as Map<String, dynamic>),
  rounds:
      (json['rounds'] as List<dynamic>?)
          ?.map((e) => RoundInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <RoundInfo>[],
  question: json['question'] == null
      ? null
      : Question.fromJson(json['question'] as Map<String, dynamic>),
  deadline: (json['deadline'] as num?)?.toInt(),
  players:
      (json['players'] as List<dynamic>?)
          ?.map((e) => PlayerView.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PlayerView>[],
  you: You.fromJson(json['you'] as Map<String, dynamic>),
  reveal: json['reveal'] == null
      ? null
      : Reveal.fromJson(json['reveal'] as Map<String, dynamic>),
  finalRound: json['final'] == null
      ? null
      : FinalRound.fromJson(json['final'] as Map<String, dynamic>),
  notice: json['notice'] == null
      ? null
      : Notice.fromJson(json['notice'] as Map<String, dynamic>),
  countdown: json['countdown'] == null
      ? null
      : StartCountdown.fromJson(json['countdown'] as Map<String, dynamic>),
  packVotes:
      (json['pack_votes'] as List<dynamic>?)
          ?.map((e) => PackVote.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PackVote>[],
  chat: json['chat'] == null
      ? const ChatState()
      : ChatState.fromJson(json['chat'] as Map<String, dynamic>),
  reactions:
      (json['reactions'] as List<dynamic>?)
          ?.map((e) => Reaction.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Reaction>[],
);

Map<String, dynamic> _$SeatStateToJson(_SeatState instance) =>
    <String, dynamic>{
      'protocol_version': instance.protocolVersion,
      'protocol_minor': instance.protocolMinor,
      'server_time': instance.serverTime,
      'game_code': instance.gameCode,
      'status': _$SeatStatusEnumMap[instance.status]!,
      'phase': _$PhaseEnumMap[instance.phase]!,
      'pack': instance.pack?.toJson(),
      'options': instance.options.toJson(),
      'rounds': instance.rounds.map((e) => e.toJson()).toList(),
      'question': instance.question?.toJson(),
      'deadline': instance.deadline,
      'players': instance.players.map((e) => e.toJson()).toList(),
      'you': instance.you.toJson(),
      'reveal': instance.reveal?.toJson(),
      'final': instance.finalRound?.toJson(),
      'notice': instance.notice?.toJson(),
      'countdown': instance.countdown?.toJson(),
      'pack_votes': instance.packVotes.map((e) => e.toJson()).toList(),
      'chat': instance.chat.toJson(),
      'reactions': instance.reactions.map((e) => e.toJson()).toList(),
    };

const _$SeatStatusEnumMap = {
  SeatStatus.connecting: 'connecting',
  SeatStatus.live: 'live',
  SeatStatus.lost: 'lost',
  SeatStatus.removed: 'removed',
};

const _$PhaseEnumMap = {
  Phase.lobby: 'lobby',
  Phase.question: 'question',
  Phase.reveal: 'reveal',
  Phase.finalVote: 'final_vote',
  Phase.finalWager: 'final_wager',
  Phase.finalQuestion: 'final_question',
  Phase.finalReveal: 'final_reveal',
  Phase.finalScores: 'final_scores',
};

_Pack _$PackFromJson(Map<String, dynamic> json) => _Pack(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  imageUrl: json['image_url'] as String?,
  numQuestions: (json['num_questions'] as num?)?.toInt(),
  hasImages: json['has_images'] as bool? ?? false,
);

Map<String, dynamic> _$PackToJson(_Pack instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'image_url': instance.imageUrl,
  'num_questions': instance.numQuestions,
  'has_images': instance.hasImages,
};

_GameOptions _$GameOptionsFromJson(Map<String, dynamic> json) => _GameOptions(
  questionsPerGame: (json['questions_per_game'] as num).toInt(),
  questionSeconds: (json['question_seconds'] as num).toInt(),
);

Map<String, dynamic> _$GameOptionsToJson(_GameOptions instance) =>
    <String, dynamic>{
      'questions_per_game': instance.questionsPerGame,
      'question_seconds': instance.questionSeconds,
    };

_RoundInfo _$RoundInfoFromJson(Map<String, dynamic> json) => _RoundInfo(
  index: (json['index'] as num).toInt(),
  percent: (json['percent'] as num?)?.toInt(),
);

Map<String, dynamic> _$RoundInfoToJson(_RoundInfo instance) =>
    <String, dynamic>{'index': instance.index, 'percent': instance.percent};

_Question _$QuestionFromJson(Map<String, dynamic> json) => _Question(
  index: (json['index'] as num).toInt(),
  text: json['text'] as String,
  category: json['category'] as String?,
  difficulty: json['difficulty'] as String?,
  imageUrl: json['image_url'] as String?,
  isFinal: json['is_final'] as bool? ?? false,
);

Map<String, dynamic> _$QuestionToJson(_Question instance) => <String, dynamic>{
  'index': instance.index,
  'text': instance.text,
  'category': instance.category,
  'difficulty': instance.difficulty,
  'image_url': instance.imageUrl,
  'is_final': instance.isFinal,
};

_PlayerView _$PlayerViewFromJson(Map<String, dynamic> json) => _PlayerView(
  peerId: (json['peer_id'] as num).toInt(),
  name: json['name'] as String,
  host: json['host'] as bool? ?? false,
  connected: json['connected'] as bool? ?? true,
  ready: json['ready'] as bool? ?? false,
  readyForNextGame: json['ready_for_next_game'] as bool? ?? false,
  spectating: json['spectating'] as bool? ?? false,
  score: (json['score'] as num?)?.toInt() ?? 0,
  answered: json['answered'] as bool? ?? false,
  guess: json['guess'] as String?,
  finalWagered: json['final_wagered'] as bool? ?? false,
  reactions: json['reactions'] == null
      ? const PlayerReactions()
      : PlayerReactions.fromJson(json['reactions'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlayerViewToJson(_PlayerView instance) =>
    <String, dynamic>{
      'peer_id': instance.peerId,
      'name': instance.name,
      'host': instance.host,
      'connected': instance.connected,
      'ready': instance.ready,
      'ready_for_next_game': instance.readyForNextGame,
      'spectating': instance.spectating,
      'score': instance.score,
      'answered': instance.answered,
      'guess': instance.guess,
      'final_wagered': instance.finalWagered,
      'reactions': instance.reactions.toJson(),
    };

_You _$YouFromJson(Map<String, dynamic> json) => _You(
  peerId: (json['peer_id'] as num?)?.toInt(),
  host: json['host'] as bool? ?? false,
  canReveal: json['can_reveal'] as bool? ?? true,
  answer: json['answer'] == null
      ? null
      : OwnAnswer.fromJson(json['answer'] as Map<String, dynamic>),
  wagerChoices:
      (json['wager_choices'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  judgements:
      (json['judgements'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const <String, bool>{},
  judged: json['judged'] as bool? ?? false,
  playedAgain: json['played_again'] as bool? ?? false,
  spectating: json['spectating'] as bool? ?? false,
  canRate: json['can_rate'] as bool? ?? false,
  rating: (json['rating'] as num?)?.toInt() ?? 0,
  reported: json['reported'] as bool? ?? false,
  poppers: (json['poppers'] as num?)?.toInt(),
);

Map<String, dynamic> _$YouToJson(_You instance) => <String, dynamic>{
  'peer_id': instance.peerId,
  'host': instance.host,
  'can_reveal': instance.canReveal,
  'answer': instance.answer?.toJson(),
  'wager_choices': instance.wagerChoices,
  'judgements': instance.judgements,
  'judged': instance.judged,
  'played_again': instance.playedAgain,
  'spectating': instance.spectating,
  'can_rate': instance.canRate,
  'rating': instance.rating,
  'reported': instance.reported,
  'poppers': instance.poppers,
};

_OwnAnswer _$OwnAnswerFromJson(Map<String, dynamic> json) => _OwnAnswer(
  text: json['text'] as String,
  wager: (json['wager'] as num).toInt(),
);

Map<String, dynamic> _$OwnAnswerToJson(_OwnAnswer instance) =>
    <String, dynamic>{'text': instance.text, 'wager': instance.wager};

_Reveal _$RevealFromJson(Map<String, dynamic> json) => _Reveal(
  answer: json['answer'] as String?,
  answers:
      (json['answers'] as List<dynamic>?)
          ?.map((e) => RevealAnswer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <RevealAnswer>[],
);

Map<String, dynamic> _$RevealToJson(_Reveal instance) => <String, dynamic>{
  'answer': instance.answer,
  'answers': instance.answers.map((e) => e.toJson()).toList(),
};

_RevealAnswer _$RevealAnswerFromJson(Map<String, dynamic> json) =>
    _RevealAnswer(
      peerId: (json['peer_id'] as num).toInt(),
      text: json['text'] as String?,
      wager: (json['wager'] as num?)?.toInt() ?? 0,
      correct: json['correct'] as bool? ?? false,
      score: (json['score'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RevealAnswerToJson(_RevealAnswer instance) =>
    <String, dynamic>{
      'peer_id': instance.peerId,
      'text': instance.text,
      'wager': instance.wager,
      'correct': instance.correct,
      'score': instance.score,
    };

_FinalRound _$FinalRoundFromJson(Map<String, dynamic> json) => _FinalRound(
  votes:
      (json['votes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const <String, int>{},
  picked: json['picked'] as String?,
  vote: json['vote'] as String?,
  nextGameCode: json['next_game_code'] as String?,
  wager: (json['wager'] as num?)?.toInt(),
  wagers:
      (json['wagers'] as List<dynamic>?)
          ?.map((e) => FinalWager.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <FinalWager>[],
);

Map<String, dynamic> _$FinalRoundToJson(_FinalRound instance) =>
    <String, dynamic>{
      'votes': instance.votes,
      'picked': instance.picked,
      'vote': instance.vote,
      'next_game_code': instance.nextGameCode,
      'wager': instance.wager,
      'wagers': instance.wagers.map((e) => e.toJson()).toList(),
    };

_Notice _$NoticeFromJson(Map<String, dynamic> json) => _Notice(
  kind: json['kind'] as String,
  level: json['level'] as String? ?? 'info',
  title: json['title'] as String?,
  message: json['message'] as String?,
  until: (json['until'] as num).toInt(),
);

Map<String, dynamic> _$NoticeToJson(_Notice instance) => <String, dynamic>{
  'kind': instance.kind,
  'level': instance.level,
  'title': instance.title,
  'message': instance.message,
  'until': instance.until,
};

_StartCountdown _$StartCountdownFromJson(Map<String, dynamic> json) =>
    _StartCountdown(
      kind: json['kind'] as String,
      until: (json['until'] as num).toInt(),
    );

Map<String, dynamic> _$StartCountdownToJson(_StartCountdown instance) =>
    <String, dynamic>{'kind': instance.kind, 'until': instance.until};

_PackVote _$PackVoteFromJson(Map<String, dynamic> json) => _PackVote(
  pack: Pack.fromJson(json['pack'] as Map<String, dynamic>),
  votes: (json['votes'] as num?)?.toInt() ?? 0,
  voters:
      (json['voters'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  you: json['you'] as bool? ?? false,
);

Map<String, dynamic> _$PackVoteToJson(_PackVote instance) => <String, dynamic>{
  'pack': instance.pack.toJson(),
  'votes': instance.votes,
  'voters': instance.voters,
  'you': instance.you,
};

_FinalWager _$FinalWagerFromJson(Map<String, dynamic> json) => _FinalWager(
  peerId: (json['peer_id'] as num).toInt(),
  wager: (json['wager'] as num).toInt(),
);

Map<String, dynamic> _$FinalWagerToJson(_FinalWager instance) =>
    <String, dynamic>{'peer_id': instance.peerId, 'wager': instance.wager};

_PlayerReactions _$PlayerReactionsFromJson(Map<String, dynamic> json) =>
    _PlayerReactions(
      total: (json['total'] as num?)?.toInt() ?? 0,
      recent:
          (json['recent'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$PlayerReactionsToJson(_PlayerReactions instance) =>
    <String, dynamic>{'total': instance.total, 'recent': instance.recent};

_Reaction _$ReactionFromJson(Map<String, dynamic> json) => _Reaction(
  id: (json['id'] as num).toInt(),
  peerId: (json['peer_id'] as num?)?.toInt(),
  type: json['type'] as String,
  until: (json['until'] as num).toInt(),
);

Map<String, dynamic> _$ReactionToJson(_Reaction instance) => <String, dynamic>{
  'id': instance.id,
  'peer_id': instance.peerId,
  'type': instance.type,
  'until': instance.until,
};

_ChatState _$ChatStateFromJson(Map<String, dynamic> json) => _ChatState(
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ChatMessage>[],
  unread: (json['unread'] as num?)?.toInt() ?? 0,
  typing:
      (json['typing'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  open: json['open'] as bool? ?? false,
  hasMore: json['has_more'] as bool? ?? false,
  loading: json['loading'] as bool? ?? false,
);

Map<String, dynamic> _$ChatStateToJson(_ChatState instance) =>
    <String, dynamic>{
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'unread': instance.unread,
      'typing': instance.typing,
      'open': instance.open,
      'has_more': instance.hasMore,
      'loading': instance.loading,
    };

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: json['id'] as String,
  peerId: (json['peer_id'] as num?)?.toInt(),
  name: json['name'] as String?,
  text: json['text'] as String? ?? '',
  imageUrl: json['image_url'] as String?,
  system: json['system'] as bool? ?? false,
  at: (json['at'] as num?)?.toInt() ?? 0,
  own: json['own'] as bool? ?? false,
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'peer_id': instance.peerId,
      'name': instance.name,
      'text': instance.text,
      'image_url': instance.imageUrl,
      'system': instance.system,
      'at': instance.at,
      'own': instance.own,
    };
