import 'dart:convert';
import 'dart:io';

import 'package:trivia_relay/core/models/models.dart';

/// The shared contract fixtures in `<repo>/protocol/fixtures`, read from disk
/// rather than copied: the relay's tests produce and check the same files
/// (protocol/PROTOCOL.md §7). `flutter test` runs in `app/`, so `../protocol` is
/// the repo's protocol folder.
class ProtocolFixtures {
  static final Directory dir = Directory('../protocol/fixtures');

  static Map<String, dynamic> load(String relative) {
    final file = File('${dir.path}/$relative');
    if (!file.existsSync()) {
      throw StateError('missing protocol fixture: ${file.path}');
    }
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  /// A snapshot the relay sends at a moment of the recorded game.
  static SeatState snapshot(String name) =>
      SeatState.fromJson(load('snapshots/$name.json'));

  static List<String> snapshotNames() {
    final names =
        Directory('${dir.path}/snapshots')
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
            .toList()
          ..sort();
    return names;
  }
}
