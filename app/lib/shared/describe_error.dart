import '../core/models/models.dart';
import '../core/providers/update_providers.dart';

/// Words for an error a person has to read (protocol/PROTOCOL.md §3, §4).
String describeError(Object error) {
  if (error is UpdateCheckFailed) {
    return 'Could not check for updates. Try again when you have a connection.';
  }
  if (error is! GameError) return 'Something went wrong.';
  return switch (error.code) {
    'login_failed' => "That email and password don't match a Sporcle account.",
    'sporcle_auth' => 'Your Sporcle sign-in has expired. Sign in again.',
    'sporcle_unavailable' => "Sporcle didn't answer. Try again in a moment.",
    'game_refused' =>
      error.message ?? "Sporcle wouldn't seat you in that game.",
    'invalid_code' => 'A game code is 4 to 8 digits.',
    'invalid_player' => 'Sign in to Sporcle first.',
    'pack_not_found' => "That pack doesn't exist any more.",
    'seat_not_found' || 'invalid_token' => 'That game has ended for you.',
    'version_mismatch' => 'This app and the relay no longer speak the same version. Update the app.',
    'not_host' => 'Only the host can do that.',
    'wrong_phase' => "That can't be done right now.",
    'not_live' => 'Still connecting to the game.',
    'already_answered' => 'You already answered.',
    'already_voted' => 'You already voted.',
    'already_wagered' => 'You already wagered.',
    'invalid_wager' => "That wager isn't available.",
    'invalid_options' => "Those game options aren't allowed.",
    'rate_limited' => 'Too many tries. Wait a moment and try again.',
    GameError.connectionFailed => 'Could not reach the relay.',
    GameError.timeout => 'The relay did not answer.',
    _ => error.message ?? 'Something went wrong (${error.code}).',
  };
}
