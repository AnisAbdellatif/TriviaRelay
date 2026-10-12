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

  /// The games the player could join (§3.4): invited, friends', then public.
  Future<List<JoinableGame>> joinableGames(SporcleAccount account) async {
    final body = await _send(
      _client.get(_uri('/api/games'), headers: account.headers),
    );
    return [
      for (final game in body['games'] as List<dynamic>)
        JoinableGame.fromJson(game as Map<String, dynamic>),
    ];
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
            'spectate': options.spectate,
          },
          'player': account.player,
        }),
      ),
    );
    return SeatTicket.fromJson(body);
  }

  /// Chooses [packId] in the lobby (§3.3): the host changes the game's pack
  /// to it, anybody else votes for it.
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

  /// One pack, with what the player did to it (§3.2).
  Future<PackSummary> pack(SporcleAccount account, int packId) async {
    final body = await _send(
      _client.get(_uri('/api/packs/$packId'), headers: account.headers),
    );
    return PackSummary.fromJson(body['pack'] as Map<String, dynamic>);
  }

  /// Whatever pack the catalog picks this time (§3.2).
  Future<PackSummary> randomPack(SporcleAccount account) async {
    final body = await _send(
      _client.get(_uri('/api/packs/random'), headers: account.headers),
    );
    return PackSummary.fromJson(body['pack'] as Map<String, dynamic>);
  }

  /// Bookmarks the pack, or stops (§3.2). What it is now.
  Future<bool> setBookmarked(
    SporcleAccount account,
    int packId,
    bool bookmarked,
  ) async {
    final body = await _post(account, '/api/packs/$packId/bookmark', {
      'bookmarked': bookmarked,
    });
    return body['bookmarked'] as bool? ?? bookmarked;
  }

  /// Asks to be told when somebody hosts the pack, or stops (§3.2).
  Future<bool> setSubscribed(
    SporcleAccount account,
    int packId,
    bool subscribed,
  ) async {
    final body = await _post(account, '/api/packs/$packId/subscribe', {
      'subscribed': subscribed,
    });
    return body['subscribed'] as bool? ?? subscribed;
  }

  /// Reports the pack to Sporcle (§3.2).
  Future<void> reportPack(
    SporcleAccount account,
    int packId,
    ReportReason reason,
    String details,
  ) => _post(account, '/api/packs/$packId/report', {
    'reason': reason.name,
    'details': details,
  });

  /// Claims the Party Poppers Sporcle has given back, and says how many the
  /// player has (§3.5).
  Future<PopperBalance> claimPoppers(SporcleAccount account) async =>
      PopperBalance.fromJson(
        await _post(account, '/api/poppers/claim', const {}),
      );

  /// A page of the player's friends (§3.6). `nextPage` is null at the end.
  Future<({List<Friend> friends, int? nextPage})> friends(
    SporcleAccount account, {
    int page = 0,
  }) async {
    final body = await _send(
      _client.get(
        _uri('/api/friends', {'page': '$page'}),
        headers: account.headers,
      ),
    );
    return (
      friends: [
        for (final friend in body['friends'] as List<dynamic>)
          Friend.fromJson(friend as Map<String, dynamic>),
      ],
      nextPage: (body['next_page'] as num?)?.toInt(),
    );
  }

  /// Invites [friendId], or every friend when it is null, to the game [seat]
  /// is in (§3.6).
  Future<void> invite(
    SporcleAccount account,
    SeatTicket seat, {
    required int packId,
    String? friendId,
  }) => _post(account, '/api/invites', {
    'seat_token': seat.seatToken,
    'code': seat.gameCode,
    'pack_id': packId,
    'friend_id': friendId,
  });

  /// Whether Sporcle accepts [name] as the one others see, and the name as
  /// the relay will pass it on (§3.7).
  Future<({String name, bool allowed})> checkName(
    SporcleAccount account,
    String name,
  ) async {
    final body = await _post(account, '/api/names/check', {'name': name});
    return (
      name: body['name'] as String? ?? name,
      allowed: body['allowed'] as bool? ?? false,
    );
  }

  void close() => _client.close();

  static const _json = {'content-type': 'application/json'};

  /// A POST that asks Sporcle something for the player: they go in headers.
  Future<Map<String, dynamic>> _post(
    SporcleAccount account,
    String path,
    Map<String, dynamic> body,
  ) => _send(
    _client.post(
      _uri(path),
      headers: {...account.headers, ..._json},
      body: jsonEncode(body),
    ),
  );

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
