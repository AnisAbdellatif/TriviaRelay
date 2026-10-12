import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'served_origin.dart';

part 'config_providers.g.dart';

const _serverUrlOverrideKey = 'trivia_relay.debug_server_url';

/// Local wall clock; overridable in tests.
typedef Clock = DateTime Function();

/// Server base URL.
///
/// On the web the app is normally served by the relay itself, so its own origin
/// is the right answer and nothing needs configuring per deployment. Override with
/// `--dart-define=SERVER_URL=https://example.com` when the app is hosted
/// somewhere else, and for Android, which has no origin: `scripts/ci.sh apk`
/// always sets it (and only to an https address). A release build left without
/// one has no relay ([relayConfigured] is false) and says so rather than trying
/// somewhere.
@Riverpod(keepAlive: true)
class ServerBaseUrl extends _$ServerBaseUrl {
  @override
  String build() {
    final fallback = configuredServerUrl() ?? _noRelay;
    if (kDebugMode) unawaited(_loadOverride(fallback));
    return fallback;
  }

  Future<void> _loadOverride(String fallback) async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString(_serverUrlOverrideKey);
    if (override != null && override.isNotEmpty && state == fallback) {
      state = override;
    }
  }

  Future<void> setDebugOverride(String? value) async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      await prefs.remove(_serverUrlOverrideKey);
      state = configuredServerUrl() ?? _noRelay;
    } else {
      await prefs.setString(_serverUrlOverrideKey, trimmed);
      state = trimmed;
    }
  }
}

/// Whether this build knows its relay. False only for a release build that is
/// neither served by a relay nor built with SERVER_URL, which the app shows as
/// a broken build (main.dart) instead of quietly talking to localhost.
@Riverpod(keepAlive: true)
bool relayConfigured(Ref ref) => configuredServerUrl() != null;

/// The relay a development build talks to: `mix phx.server` in `server/`.
/// Debug builds only.
const _devRelay = 'http://localhost:4100';

/// What [ServerBaseUrl] holds when there is no relay: an address that can
/// never resolve (`.invalid`, RFC 2606), so nothing is ever sent anywhere.
const _noRelay = 'https://relay.invalid';

/// The relay this build was made for or is served by, or null when it has
/// none.
String? configuredServerUrl() {
  const configured = String.fromEnvironment('SERVER_URL');
  if (configured.isNotEmpty) return configured;
  // A debug web build is served by `flutter run`'s own server, which is never
  // the relay, so its origin is the wrong answer there.
  if (kDebugMode) return _devRelay;
  return servedOrigin();
}

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => DateTime.now;
