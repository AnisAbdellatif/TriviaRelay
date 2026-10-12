import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Offers [text] to the browser's share sheet (the Web Share API, on phones
/// mostly). False when the browser has none, so the caller copies it instead.
/// The person closing the sheet counts as done: nothing is copied behind
/// their back.
Future<bool> platformShare(String text) async {
  final navigator = web.window.navigator;
  if (!(navigator as JSObject).has('share')) return false;
  try {
    await navigator.share(web.ShareData(text: text)).toDart;
    return true;
  } on Object catch (error) {
    return error.toString().contains('AbortError');
  }
}

/// The path the page was opened at (`/join/1234` for an invite link), as the
/// relay served the app there.
String? launchRoute() {
  final path = web.window.location.pathname;
  return path.isEmpty || path == '/' ? null : path;
}
