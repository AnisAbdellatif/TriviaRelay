import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/models.dart';
import '../core/providers/account_providers.dart';
import '../core/providers/connection_providers.dart';
import '../features/game/game_screen.dart';
import 'describe_error.dart';
import 'navigation.dart';

/// Takes a seat ([take] is the relay call: join or host), remembers it, and
/// opens the game.
Future<void> openSeat(
  BuildContext context,
  WidgetRef ref,
  Future<SeatTicket> Function() take,
) async {
  final ticket = await take();
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

/// Shows [error] to the person. An expired Sporcle sign-in signs out, which
/// brings back the sign-in screen.
void showError(BuildContext context, WidgetRef ref, Object error) {
  if (error is GameError && error.code == 'sporcle_auth') {
    ref.read(accountProvider.notifier).signOut();
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(describeError(error))));
}
