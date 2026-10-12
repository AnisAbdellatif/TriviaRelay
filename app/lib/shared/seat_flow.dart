import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/models.dart';
import '../core/providers/account_providers.dart';
import '../core/providers/connection_providers.dart';
import '../core/providers/settings_providers.dart';
import '../features/game/game_screen.dart';
import 'describe_error.dart';
import 'navigation.dart';
import 'widgets/fz_toast.dart';

/// Takes a seat ([take] is the relay call: join or host), remembers it, and
/// opens the game.
Future<void> openSeat(
  BuildContext context,
  WidgetRef ref,
  Future<SeatTicket> Function() take,
) async {
  final ticket = await take();
  unawaited(ref.read(poppersProvider.notifier).heard(ticket.poppers));
  await ref.read(currentSeatProvider.notifier).set(ticket);
  if (!context.mounted) return;
  await attachSeat(context, ref, ticket);
}

/// Attaches to a seat the relay holds, and opens the game. A seat that has
/// ended meanwhile is forgotten.
Future<void> attachSeat(
  BuildContext context,
  WidgetRef ref,
  SeatTicket ticket,
) async {
  ref.invalidate(seatConnectionProvider);
  try {
    await ref.read(seatConnectionProvider).attach(ticket);
  } on GameError catch (error) {
    if (error.code == 'seat_not_found' || error.code == 'invalid_token') {
      await ref.read(currentSeatProvider.notifier).set(null);
    }
    rethrow;
  }
  if (!context.mounted) return;
  await Navigator.of(context)
      .push(FzPageRoute<void>(builder: (_) => const GameScreen()));
}

/// Takes a new seat in game [code] from the game screen, in place of the one
/// this app was in (the relay lost the game, or the seat ended), and attaches
/// to it there: the screen stays, and fills in with the new seat.
///
/// The old seat is let go of first, so its ending isn't mistaken for the new
/// one's. A new seat for the same player ends the old one anyway, and in the
/// same game keeps what it had spent (protocol/PROTOCOL.md §3.3). If joining
/// fails, the old seat, still held, is attached again.
Future<void> rejoinSeat(WidgetRef ref, String code) async {
  final account = await ref.read(accountProvider.future);
  if (account == null) throw const GameError(code: 'invalid_player');
  final previous = ref.read(currentSeatProvider).value;
  ref.invalidate(seatConnectionProvider);
  final SeatTicket ticket;
  try {
    ticket = await ref.read(relayApiProvider).join(account, code);
  } on Object {
    if (previous != null) {
      unawaited(
        ref
            .read(seatConnectionProvider)
            .attach(previous)
            .catchError((Object _) {}),
      );
    }
    rethrow;
  }
  await ref.read(currentSeatProvider.notifier).set(ticket);
  ref.invalidate(seatConnectionProvider);
  await ref.read(seatConnectionProvider).attach(ticket);
}

/// Shows [error] to the person. An expired Sporcle sign-in signs out, which
/// brings back the sign-in screen; it keeps the seat, so a game in progress
/// goes on and the same player can sign in and go back to it.
void showError(BuildContext context, WidgetRef ref, Object error) {
  if (error is GameError && error.code == 'sporcle_auth') {
    ref.read(accountProvider.notifier).expire();
  }
  showFzToast(context, describeError(error));
}
