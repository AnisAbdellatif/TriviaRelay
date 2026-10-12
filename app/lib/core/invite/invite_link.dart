/// Invite links: `https://<relay>/join/<code>` (protocol/PROTOCOL.md §3.8).
///
/// The relay serves its web app there, and the released Android app opens
/// them itself. Only a game code as games have them counts: anything else is
/// no invite, and nothing ever joins without the person saying so.
library;

final _code = RegExp(r'^\d{4,8}$');

/// Whether [code] is a game code: 4 to 8 digits.
bool isGameCode(String code) => _code.hasMatch(code);

/// The game code an invite link carries, or null when [uri] isn't one.
///
/// Reads the path only (`/join/<code>`, a trailing slash allowed), whatever
/// the host: on the web the app is served by its relay, whatever its name,
/// and on Android the manifest only lets the relay's own links through.
String? inviteCode(Uri uri) {
  final segments = [
    for (final segment in uri.pathSegments)
      if (segment.isNotEmpty) segment,
  ];
  if (segments.length != 2 || segments.first != 'join') return null;
  final code = segments.last;
  return isGameCode(code) ? code : null;
}

/// The same, from a route name as a platform hands one over (`/join/1234`,
/// perhaps with a query), or null.
String? inviteCodeFromRoute(String? route) {
  if (route == null || route.isEmpty) return null;
  final uri = Uri.tryParse(route);
  return uri == null ? null : inviteCode(uri);
}

/// The link to game [code] on the relay at [relay] (its base URL).
String inviteLink(String relay, String code) {
  final base = Uri.parse(relay);
  var prefix = base.path;
  while (prefix.endsWith('/')) {
    prefix = prefix.substring(0, prefix.length - 1);
  }
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: '$prefix/join/$code',
  ).toString();
}

/// What an invite says: the app's own words, never presented as Sporcle's.
String inviteMessage(String link, String code) =>
    'Join my Trivia Relay game: $link (code $code)';
