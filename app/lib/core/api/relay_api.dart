import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// The relay's HTTP endpoints (protocol/PROTOCOL.md §3).
///
/// Every call that reaches Sporcle carries the player's credentials, which the
/// relay uses for that one call and keeps none of. Errors arrive as
/// [GameError]s with the relay's code.
class RelayApi {
  RelayApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  /// The web build's login (§3.1): a browser may not call sporcle.com itself.
  Future<({String playerId, String token, String handle})> login(
    String email,
    String password,
    String deviceId,
  ) async {
    final body = await _send(
      _client.post(
        _uri('/api/login'),
        headers: _json,
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_id': deviceId,
        }),
      ),
    );
    return (
      playerId: body['player_id'] as String,
      token: body['token'] as String,
      handle: body['handle'] as String,
    );
  }

  /// A page of Sporcle's pack catalog (§3.2): [list] browsed, or searched for
  /// [query] (within [list], if given). `nextPage` is null at the end.
  Future<({List<PackSummary> packs, int? nextPage})> searchPacks(
    SporcleAccount account, {
    String query = '',
    PackList? list,
    int page = 0,
  }) async {
    final body = await _send(
      _client.get(
        _uri('/api/packs', {'q': query, 'list': ?list?.name, 'page': '$page'}),
        headers: account.headers,
      ),
    );
    return (
      packs: [
        for (final pack in body['packs'] as List<dynamic>)
          PackSummary.fromJson(pack as Map<String, dynamic>),
      ],
      nextPage: (body['next_page'] as num?)?.toInt(),
    );
  }

  /// Joins the Sporcle game [code] (§3.3).
  Future<SeatTicket> join(SporcleAccount account, String code) async {
    final body = await _send(
      _client.post(
        _uri('/api/seats'),
        headers: _json,
        body: jsonEncode({'code': code, 'player': account.player}),
      ),
    );
    return SeatTicket.fromJson(body);
  }

  /// Creates a game of [packId] and seats its host (§3.3).
  Future<SeatTicket> host(
    SporcleAccount account,
    int packId,
    HostOptions options,
  ) async {
    final body = await _send(
      _client.post(
        _uri('/api/seats/host'),
        headers: _json,
        body: jsonEncode({
          'pack_id': packId,
          'options': {
            'questions_per_game': options.questionsPerGame,
            'question_seconds': options.questionSeconds,
            'audience': options.audience.name,
          },
          'player': account.player,
        }),
      ),
    );
    return SeatTicket.fromJson(body);
  }

  /// The host changes the lobby's pack to [packId] (§3.3).
  Future<void> changePack(
    SporcleAccount account,
    SeatTicket seat,
    int packId,
  ) async {
    await _send(
      _client.post(
        _uri('/api/seats/pack'),
        headers: _json,
        body: jsonEncode({
          'seat_token': seat.seatToken,
          'pack_id': packId,
          'player': account.player,
        }),
      ),
    );
  }

  void close() => _client.close();

  static const _json = {'content-type': 'application/json'};

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUrl);
    var prefix = base.path;
    while (prefix.endsWith('/')) {
      prefix = prefix.substring(0, prefix.length - 1);
    }
    return base.replace(path: '$prefix$path', queryParameters: query);
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> request) async {
    final http.Response response;
    try {
      response = await request.timeout(_timeout);
    } on Object {
      throw const GameError(
        code: GameError.connectionFailed,
        message: 'Could not reach the relay.',
      );
    }

    Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      body = null;
    }
    final map = body is Map<String, dynamic> ? body : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) return map;
    // No `code`: whatever answered isn't the relay (a wrong server address).
    final code = map['code'] as String?;
    throw GameError(
      code: code ?? 'http_${response.statusCode}',
      message: code == null
          ? 'No relay answered at $baseUrl (HTTP ${response.statusCode}).'
          : map['message'] as String?,
    );
  }
}
