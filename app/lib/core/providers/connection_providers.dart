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

/// The seat the app is in, kept on the device so a closed app can go back to
/// it. Null when it isn't in one.
@Riverpod(keepAlive: true)
class CurrentSeat extends _$CurrentSeat {
  @override
  Future<SeatTicket?> build() => ref.watch(appStoreProvider).seat();

  Future<void> set(SeatTicket? seat) async {
    await ref.read(appStoreProvider).saveSeat(seat);
    state = AsyncData(seat);
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
