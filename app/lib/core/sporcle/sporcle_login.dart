import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// A Sporcle email and password, exchanged for Party credentials on this device,
/// the way the official app does it (confirmed by capturing it — the relay's
/// `TriviaRelay.Sporcle.Login` does the same, `sporcle_scraper/RE/find_connect.py`):
///
///  1. `GET www.sporcle.com/login/?party_udid=<device id>` — primes the session
///  2. `POST www.sporcle.com/auth/ajax/login.php {email, passwd, remember}`
///     → `{success, logged_in, user_id, handle, token}`, where `user_id` is the
///     player id (X-SPORCLE-PLAYER) and `token` is X-SPORCLE-TOKEN.
///
/// Without step 1 the login returns only `{success, logged_in}` and no token. The
/// token is bound to the udid, so the same device id must be sent as X-UDID later.
///
/// The Android app runs this on the device, so the password goes to sporcle.com and
/// nowhere else. The web build can't call sporcle.com cross-origin, so it asks the
/// relay to run the same flow. Nothing here keeps the password.
class SporcleLogin {
  SporcleLogin({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _site = Uri.parse('https://www.sporcle.com');
  // The Party app's own user agent: the party-token login flow (and its _spmob
  // session cookie) is gated on it — a desktop UA gets an ordinary web login
  // with no token. Matches the relay's Identity.user_agent_api/0.
  static const _userAgent =
      'party/1.5.15.297 Mozilla/5.0 (Linux; Android 17) Mobile Safari/537.36';

  static const _timeout = Duration(seconds: 25);

  Future<({String playerId, String token, String handle})> login(
    String email,
    String password,
    String deviceId,
  ) async {
    final cookies = await _prime(deviceId);
    return _login(email, password, cookies);
  }

  /// Loads the party login page with the udid so the login POST returns the token.
  Future<String> _prime(String deviceId) async {
    final response = await _call(
      _client.get(
        _site.replace(
          path: '/login/',
          queryParameters: {'party_udid': deviceId},
        ),
        headers: {'user-agent': _userAgent},
      ),
    );
    return cookieHeader(response.headers['set-cookie']);
  }

  Future<({String playerId, String token, String handle})> _login(
    String email,
    String password,
    String cookies,
  ) async {
    final response = await _call(
      _client.post(
        _site.replace(path: '/auth/ajax/login.php'),
        headers: {'user-agent': _userAgent, 'cookie': cookies},
        body: {'email': email, 'passwd': password, 'remember': '1'},
      ),
    );
    final body = _json(response.body);
    if (body['success'] != true || body['logged_in'] != true) {
      throw const GameError(
        code: 'login_failed',
        message: "That email and password don't match a Sporcle account.",
      );
    }
    final player = body['user_id'];
    final token = body['token'];
    if (player is! String || token is! String) throw _unavailable;
    return (
      playerId: player,
      token: token,
      handle: body['handle'] as String? ?? email.split('@').first,
    );
  }

  /// A `Cookie` header from `Set-Cookie`, which `package:http` hands over as one
  /// comma-joined string: split where a new `name=` begins, keep each name=value.
  static String cookieHeader(String? setCookie) {
    if (setCookie == null || setCookie.isEmpty) return '';
    return setCookie
        .split(RegExp(r',(?=\s*[^;,\s]+=)'))
        .map((cookie) => cookie.split(';').first.trim())
        .where((pair) => pair.contains('='))
        .join('; ');
  }

  void close() => _client.close();

  static const _unavailable = GameError(
    code: 'sporcle_unavailable',
    message: "Sporcle didn't answer. Try again in a moment.",
  );

  Future<http.Response> _call(Future<http.Response> request) async {
    final http.Response response;
    try {
      response = await request.timeout(_timeout);
    } on Object {
      throw _unavailable;
    }
    if (response.statusCode != 200) throw _unavailable;
    return response;
  }

  static Map<String, dynamic> _json(String text) {
    try {
      final value = jsonDecode(text);
      return value is Map<String, dynamic> ? value : const {};
    } on FormatException {
      return const {};
    }
  }
}
