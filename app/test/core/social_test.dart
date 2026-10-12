import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_relay/core/game/social.dart';
import 'package:trivia_relay/core/models/models.dart';

import '../support/protocol_fixtures.dart';

void main() {
  final before = ProtocolFixtures.snapshot('reveal_judged_player');
  final honked = ProtocolFixtures.snapshot('reveal_reactions_player');

  group('reactions', () {
    test('a new one is new once', () {
      expect(newReactions(before, honked).map((r) => r.id), [1]);
      expect(newReactions(honked, honked), isEmpty);
    });

    test('coming in brings none: that is where the player came in', () {
      expect(newReactions(null, honked), isEmpty);
      expect(
        newReactions(before.copyWith(gameCode: '1111'), honked),
        isEmpty,
        reason: 'another game',
      );
    });

    test('one after the last shown is new, however many came before', () {
      const next = Reaction(id: 2, peerId: 1, type: 'clap', until: 0);
      final later = honked.copyWith(reactions: [...honked.reactions, next]);
      expect(newReactions(honked, later), [next]);
    });

    test('every sound a player may receive has a file of this app\'s own', () {
      for (final type in GameRules.reactionSounds) {
        final asset = reactionSoundAsset(type);
        expect(asset, 'sounds/reaction_$type.wav');
        expect(File('assets/$asset').existsSync(), isTrue, reason: asset);
        expect(reactionWords(type), isNot('sent you a sound'), reason: type);
      }
      expect(reactionSoundAsset('kazoo'), 'sounds/reaction_goose.wav');
      expect(reactionWords('kazoo'), 'sent you a sound');
    });

    test('a name keeps its own direction inside the app\'s sentence', () {
      expect(isolate('مرحبا'), '\u2068مرحبا\u2069');
    });
  });

  group('the chat is offered', () {
    test('in the lobby, after answering, at the reveal and the scores', () {
      for (final name in [
        'lobby_host',
        'question_host_answered',
        'reveal_host',
        'final_wager_player',
        'final_scores_host',
      ]) {
        expect(
          chatOffered(ProtocolFixtures.snapshot(name)),
          isTrue,
          reason: name,
        );
      }
    });

    test('not while a question waits for this player, nor a final vote', () {
      expect(
        chatOffered(ProtocolFixtures.snapshot('question_player')),
        isFalse,
      );
      final vote = ProtocolFixtures.snapshot('final_vote_player');
      expect(
        chatOffered(
          vote.copyWith(finalRound: vote.finalRound!.copyWith(vote: null)),
        ),
        isFalse,
      );
      expect(
        chatOffered(
          vote.copyWith(finalRound: vote.finalRound!.copyWith(vote: 'easy')),
        ),
        isTrue,
      );
    });

    test('always to a host who watches', () {
      expect(
        chatOffered(ProtocolFixtures.snapshot('question_spectator_host')),
        isTrue,
      );
    });
  });
}
