import '../models/models.dart';

/// Reactions in [after] that [before] didn't have: each is played and shown
/// once (protocol/PROTOCOL.md §6.7). Ids grow with each reaction, so anything
/// past the highest [before] had is new.
///
/// The first snapshot of a seat ([before] null, or another game's) is where the
/// player came in, and brings nothing to play, as with the game's cues.
List<Reaction> newReactions(SeatState? before, SeatState after) {
  if (before == null || before.gameCode != after.gameCode) return const [];
  var seen = 0;
  for (final r in before.reactions) {
    if (r.id > seen) seen = r.id;
  }
  return [
    for (final r in after.reactions)
      if (r.id > seen) r,
  ];
}

/// Whether the chat is offered now, where the official app offers it: not
/// while this player has a question to answer, nor while they have a final
/// vote to cast; a spectating host always has it (protocol/PROTOCOL.md §6.6).
bool chatOffered(SeatState state) {
  if (state.you.spectating) return true;
  if (state.phase.isOpenQuestion) return state.you.answer != null;
  if (state.phase == Phase.finalVote) return state.finalRound?.vote != null;
  return true;
}

/// What sending [type] does, for "Hosta honked at you": the verb after the
/// sender's name.
String reactionWords(String type) => switch (type) {
  'goose' => 'honked at you',
  'cow' => 'mooed at you',
  'donkey' => 'hee-hawed at you',
  'goat' => 'bleated at you',
  'rooster' => 'crowed at you',
  'sheep' => 'baaed at you',
  'soccer_cheer' => 'cheered you',
  'aww' => 'went “aww”',
  'clap' => 'clapped for you',
  'ooh' => 'went “ooh”',
  'laugh' => 'laughed',
  'accordion' => 'played you the accordion',
  'rim_shot' => 'played you a rim shot',
  'trombone' => 'played you a sad trombone',
  'trumpet' => 'played you a fanfare',
  'tuba' => 'played you the tuba',
  _ => 'sent you a sound',
};

/// The sound file for a reaction of [type]: its own when this app has one
/// ([GameRules.reactionSounds]), the goose's otherwise.
String reactionSoundAsset(String type) =>
    GameRules.reactionSounds.contains(type)
    ? 'sounds/reaction_$type.wav'
    : 'sounds/reaction_goose.wav';

/// [text] kept in its own direction inside a sentence of the app's: a name
/// written right to left can't turn the words around it.
String isolate(String text) => '\u2068$text\u2069';
