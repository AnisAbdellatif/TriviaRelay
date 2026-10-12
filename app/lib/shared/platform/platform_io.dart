import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// MainActivity.kt answers it with Android's own share sheet.
const _share = MethodChannel('trivia_relay/share');

/// Offers [text] to the platform's share sheet. False when there is none to
/// offer it to, so the caller copies it instead.
Future<bool> platformShare(String text) async {
  if (defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    // The sheet opens at once; a platform that never answers (a test, a
    // build without MainActivity's channel) mustn't leave the person waiting.
    return await _share
            .invokeMethod<bool>('share', {'text': text})
            .timeout(const Duration(seconds: 2)) ??
        false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  } on TimeoutException {
    return false;
  }
}

/// The route the app was opened at: on Android, the path of the link that
/// opened it (`/join/1234`), which Flutter hands over as the initial route.
String? launchRoute() {
  final route = PlatformDispatcher.instance.defaultRouteName;
  return route == '/' ? null : route;
}
