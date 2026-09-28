// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(relayApi)
final relayApiProvider = RelayApiProvider._();

final class RelayApiProvider
    extends $FunctionalProvider<RelayApi, RelayApi, RelayApi>
    with $Provider<RelayApi> {
  RelayApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'relayApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$relayApiHash();

  @$internal
  @override
  $ProviderElement<RelayApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RelayApi create(Ref ref) {
    return relayApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RelayApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RelayApi>(value),
    );
  }
}

String _$relayApiHash() => r'a6b752c8e4eaa5c13980e328e3efa95f3c41cdc4';

/// The seat the app is in, kept on the device so a closed app can go back to
/// it. Null when it isn't in one.

@ProviderFor(CurrentSeat)
final currentSeatProvider = CurrentSeatProvider._();

/// The seat the app is in, kept on the device so a closed app can go back to
/// it. Null when it isn't in one.
final class CurrentSeatProvider
    extends $AsyncNotifierProvider<CurrentSeat, SeatTicket?> {
  /// The seat the app is in, kept on the device so a closed app can go back to
  /// it. Null when it isn't in one.
  CurrentSeatProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentSeatProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentSeatHash();

  @$internal
  @override
  CurrentSeat create() => CurrentSeat();
}

String _$currentSeatHash() => r'c6f88884e20a8451ccbac3d1176fa713fb56363d';

/// The seat the app is in, kept on the device so a closed app can go back to
/// it. Null when it isn't in one.

abstract class _$CurrentSeat extends $AsyncNotifier<SeatTicket?> {
  FutureOr<SeatTicket?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SeatTicket?>, SeatTicket?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SeatTicket?>, SeatTicket?>,
              AsyncValue<SeatTicket?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The connection for the current seat. The only place that names a transport;
/// everything else depends on [SeatConnection]. Invalidate it to start again;
/// disposing it only stops listening, and the relay keeps the seat.

@ProviderFor(seatConnection)
final seatConnectionProvider = SeatConnectionProvider._();

/// The connection for the current seat. The only place that names a transport;
/// everything else depends on [SeatConnection]. Invalidate it to start again;
/// disposing it only stops listening, and the relay keeps the seat.

final class SeatConnectionProvider
    extends $FunctionalProvider<SeatConnection, SeatConnection, SeatConnection>
    with $Provider<SeatConnection> {
  /// The connection for the current seat. The only place that names a transport;
  /// everything else depends on [SeatConnection]. Invalidate it to start again;
  /// disposing it only stops listening, and the relay keeps the seat.
  SeatConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seatConnectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seatConnectionHash();

  @$internal
  @override
  $ProviderElement<SeatConnection> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SeatConnection create(Ref ref) {
    return seatConnection(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeatConnection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeatConnection>(value),
    );
  }
}

String _$seatConnectionHash() => r'304fcad4cd172bcc37515d8e24dd78d06d718891';

@ProviderFor(seatState)
final seatStateProvider = SeatStateProvider._();

final class SeatStateProvider
    extends
        $FunctionalProvider<AsyncValue<SeatState>, SeatState, Stream<SeatState>>
    with $FutureModifier<SeatState>, $StreamProvider<SeatState> {
  SeatStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seatStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seatStateHash();

  @$internal
  @override
  $StreamProviderElement<SeatState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<SeatState> create(Ref ref) {
    return seatState(ref);
  }
}

String _$seatStateHash() => r'370c0cea0676900ecfaa20e51b416b8bb3ecc204';

@ProviderFor(connectionStatus)
final connectionStatusProvider = ConnectionStatusProvider._();

final class ConnectionStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<ConnectionStatus>,
          ConnectionStatus,
          Stream<ConnectionStatus>
        >
    with $FutureModifier<ConnectionStatus>, $StreamProvider<ConnectionStatus> {
  ConnectionStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectionStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectionStatusHash();

  @$internal
  @override
  $StreamProviderElement<ConnectionStatus> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ConnectionStatus> create(Ref ref) {
    return connectionStatus(ref);
  }
}

String _$connectionStatusHash() => r'1bd608bc13002f23d50b6366d9aca217b441cf49';

/// Why the current seat ended, or null while it is going.
///
/// A plain value rather than an `AsyncValue`, as in FazouraParty: an
/// `AsyncValue` keeps its last data while it refreshes, which would hand a new
/// seat the previous one's ending on its first frame.

@ProviderFor(SeatClosed)
final seatClosedProvider = SeatClosedProvider._();

/// Why the current seat ended, or null while it is going.
///
/// A plain value rather than an `AsyncValue`, as in FazouraParty: an
/// `AsyncValue` keeps its last data while it refreshes, which would hand a new
/// seat the previous one's ending on its first frame.
final class SeatClosedProvider
    extends $NotifierProvider<SeatClosed, SeatClosedReason?> {
  /// Why the current seat ended, or null while it is going.
  ///
  /// A plain value rather than an `AsyncValue`, as in FazouraParty: an
  /// `AsyncValue` keeps its last data while it refreshes, which would hand a new
  /// seat the previous one's ending on its first frame.
  SeatClosedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seatClosedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seatClosedHash();

  @$internal
  @override
  SeatClosed create() => SeatClosed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeatClosedReason? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeatClosedReason?>(value),
    );
  }
}

String _$seatClosedHash() => r'e71c35e73ea9ef3e1a202a98775c236601d7512a';

/// Why the current seat ended, or null while it is going.
///
/// A plain value rather than an `AsyncValue`, as in FazouraParty: an
/// `AsyncValue` keeps its last data while it refreshes, which would hand a new
/// seat the previous one's ending on its first frame.

abstract class _$SeatClosed extends $Notifier<SeatClosedReason?> {
  SeatClosedReason? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SeatClosedReason?, SeatClosedReason?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SeatClosedReason?, SeatClosedReason?>,
              SeatClosedReason?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// `server_time - local_now`, recomputed whenever a snapshot arrives.

@ProviderFor(serverClockOffset)
final serverClockOffsetProvider = ServerClockOffsetProvider._();

/// `server_time - local_now`, recomputed whenever a snapshot arrives.

final class ServerClockOffsetProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// `server_time - local_now`, recomputed whenever a snapshot arrives.
  ServerClockOffsetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverClockOffsetProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverClockOffsetHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return serverClockOffset(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$serverClockOffsetHash() => r'fc2d621fbdba2fe446e1c293bae8b1cd04f1246a';
