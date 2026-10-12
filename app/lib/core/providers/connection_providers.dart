import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/relay_api.dart';
import '../connection/phoenix_seat_connection.dart';
import '../connection/seat_connection.dart';
import '../models/models.dart';
import '../time/server_clock.dart';
import 'account_providers.dart';
import 'config_providers.dart';

part 'connection_providers.g.dart';

@Riverpod(keepAlive: true)
RelayApi relayApi(Ref ref) {
  final api = RelayApi(baseUrl: ref.watch(serverBaseUrlProvider));
  ref.onDispose(api.close);
  return api;
}

/// The seat the signed-in player is in, kept on the device so a closed app can
/// go back to it. Null when they aren't in one, or nobody is signed in.
@Riverpod(keepAlive: true)
class CurrentSeat extends _$CurrentSeat {
  /// How long [leave] waits for the relay before giving up on saying so.
  static const leaveTimeout = Duration(seconds: 8);

  @override
  Future<SeatTicket?> build() async {
    final account = await ref.watch(accountProvider.future);
    return ref.read(appStoreProvider).seat(account?.playerId);
  }

  Future<void> set(SeatTicket? seat) async {
    final playerId = ref.read(accountProvider).value?.playerId;
    await ref.read(appStoreProvider).saveSeat(seat, playerId: playerId);
    state = AsyncData(playerId == null ? null : seat);
  }

  /// Leaves the held seat from outside the game, attaching to it to say so,
  /// then forgets it. Best effort: if the relay can't be reached, the seat
  /// ends anyway when its hold runs out.
  Future<void> leave() async {
    final seat = await future;
    if (seat != null) {
      ref.invalidate(seatConnectionProvider);
      final connection = ref.read(seatConnectionProvider);
      try {
        await connection.attach(seat).timeout(leaveTimeout);
        await connection.leave();
      } on Object {
        // Gone already, or unreachable: either way the seat ends.
      }
      ref.invalidate(seatConnectionProvider);
    }
    await set(null);
  }
}

/// The connection for the current seat. The only place that names a transport;
/// everything else depends on [SeatConnection]. Invalidate it to start again;
/// disposing it only stops listening, and the relay keeps the seat.
@Riverpod(keepAlive: true)
SeatConnection seatConnection(Ref ref) {
  final connection = PhoenixSeatConnection(
    baseUrl: ref.watch(serverBaseUrlProvider),
  );
  ref.onDispose(() => unawaited(connection.dispose()));
  return connection;
}

@Riverpod(keepAlive: true)
Stream<SeatState> seatState(Ref ref) => ref.watch(seatConnectionProvider).state;

@Riverpod(keepAlive: true)
Stream<ConnectionStatus> connectionStatus(Ref ref) =>
    ref.watch(seatConnectionProvider).status;

/// Why the current seat ended, or null while it is going.
///
/// A plain value rather than an `AsyncValue`, as in FazouraParty: an
/// `AsyncValue` keeps its last data while it refreshes, which would hand a new
/// seat the previous one's ending on its first frame.
@Riverpod(keepAlive: true)
class SeatClosed extends _$SeatClosed {
  @override
  SeatClosedReason? build() {
    final connection = ref.watch(seatConnectionProvider);
    var current = true;
    ref.onDispose(() => current = false);
    unawaited(
      connection.closed.then((reason) {
        if (current) state = reason;
      }, onError: (Object _) {}),
    );
    return null;
  }
}

/// `server_time - local_now`, recomputed whenever a snapshot arrives.
@Riverpod(keepAlive: true)
int serverClockOffset(Ref ref) {
  final snapshot = ref.watch(seatStateProvider).value;
  if (snapshot == null) return 0;
  final now = ref.watch(clockProvider)();
  return clockOffsetMs(
    serverTime: snapshot.serverTime,
    localNowMs: now.millisecondsSinceEpoch,
  );
}

/// Whether the player can act in the game now: the relay is in it (`live`),
/// and this app is connected to the relay. While the relay is joining or has
/// lost the game, or this app is reconnecting, intents would only be refused.
@Riverpod(keepAlive: true)
bool seatInteractive(Ref ref) {
  final state = ref.watch(seatStateProvider).value;
  final status = ref.watch(connectionStatusProvider).value;
  return state?.status == SeatStatus.live &&
      status == ConnectionStatus.connected;
}

/// Intents sent and not yet shown by a snapshot, by a key each screen picks
/// ("answer", "judge:3"), with the value sent where a screen shows it ahead of
/// the relay (a mark, an option).
///
/// A button with its intent here shows it is waiting rather than taking a
/// second press: an answer tapped twice used to come back "You already
/// answered". A refusal clears the key at once; an acceptance clears it with
/// the next snapshot, which is what shows the change, or after
/// [settleAfter] for an intent that changed nothing and so brings none.
@Riverpod(keepAlive: true)
class PendingIntents extends _$PendingIntents {
  static const settleAfter = Duration(seconds: 2);

  final Set<String> _accepted = {};
  Timer? _timer;

  @override
  Map<String, Object?> build() {
    ref.watch(seatConnectionProvider);
    _accepted.clear();
    _timer?.cancel();
    _timer = null;
    ref
      ..listen(seatStateProvider, (_, next) {
        if (next.hasValue) _settle();
      })
      ..onDispose(() => _timer?.cancel());
    return const {};
  }

  /// Sends [intent] as [key], with [value] shown meanwhile. Rethrows a
  /// refusal.
  Future<void> run(
    String key,
    Future<void> Function() intent, {
    Object? value,
  }) async {
    _accepted.remove(key);
    state = {...state, key: value};
    try {
      await intent();
    } on Object {
      if (state.containsKey(key)) state = {...state}..remove(key);
      rethrow;
    }
    _accepted.add(key);
    _timer?.cancel();
    _timer = Timer(settleAfter, _settle);
  }

  void _settle() {
    if (_accepted.isEmpty) return;
    state = {
      for (final entry in state.entries)
        if (!_accepted.contains(entry.key)) entry.key: entry.value,
    };
    _accepted.clear();
  }
}
