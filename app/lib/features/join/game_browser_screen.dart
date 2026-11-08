import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../shared/navigation.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';
import '../../shared/widgets/fz_toast.dart';
import '../host/pack_tile.dart';

/// The games the player could join, as the official app's join screen lists
/// them: games they were invited to, their friends', then public ones
/// (protocol/PROTOCOL.md §3.4). The list refreshes while it's open, and can be
/// searched by pack, host or code. Tapping a game picks it.
class GameBrowserScreen extends ConsumerStatefulWidget {
  const GameBrowserScreen({super.key});

  /// How often the open list asks again: games fill, start and end quickly.
  static const refreshEvery = Duration(seconds: 15);

  /// Opens the browser; the game tapped, or null if none was.
  static Future<JoinableGame?> pick(BuildContext context) => Navigator.of(
    context,
  ).push<JoinableGame>(FzPageRoute(builder: (_) => const GameBrowserScreen()));

  @override
  ConsumerState<GameBrowserScreen> createState() => _GameBrowserScreenState();
}

class _GameBrowserScreenState extends ConsumerState<GameBrowserScreen> {
  List<JoinableGame>? _games;
  bool _loading = false;
  Object? _error;
  Timer? _timer;
  final _query = TextEditingController();

  /// A finger is on the list: a refresh waits until it lifts, so nothing
  /// moves under it.
  bool _touching = false;
  bool _refreshDue = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _timer = Timer.periodic(GameBrowserScreen.refreshEvery, (_) {
      if (_touching) {
        _refreshDue = true;
      } else {
        unawaited(_load(keepPlaces: true));
      }
    });
  }

  void _touch(bool down) {
    _touching = down;
    if (!down && _refreshDue) {
      _refreshDue = false;
      unawaited(_load(keepPlaces: true));
    }
  }

  /// Joining a game that has started seats the player mid-game, and joining
  /// one with pictures costs a Party Popper, so either is asked first; a lobby
  /// without pictures is joined at once.
  Future<void> _pick(JoinableGame game) async {
    if (!game.inLobby || game.hasImages) {
      final poppers = ref.read(poppersProvider).value?.poppers;
      final join = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            game.inLobby ? 'Spend a Party Popper?' : 'Join a game in progress?',
          ),
          content: Text(
            [
              if (!game.inLobby)
                'It has already started (${gameStage(game)}). You join it '
                    'where it is now.',
              if (game.hasImages) popperCost(poppers),
            ].join('\n\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            TextButton(
              key: const Key('confirmJoinButton'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Join'),
            ),
          ],
        ),
      );
      if (join != true) return;
    }
    if (mounted) Navigator.of(context).pop(game);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _query.dispose();
    super.dispose();
  }

  /// Asks the relay again. The automatic refresh [keepPlaces]: games already
  /// listed stay where they were, so the list doesn't reshuffle under a
  /// reader every 15 seconds; asking by hand takes the relay's order.
  Future<void> _load({bool keepPlaces = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final account = await ref.read(accountProvider.future);
      if (account == null) throw const GameError(code: 'invalid_player');
      final fresh = await ref.read(relayApiProvider).joinableGames(account);
      if (!mounted) return;
      final before = _games;
      final games = keepPlaces && before != null
          ? keepOrder(before, fresh)
          : fresh;
      setState(() {
        _games = games;
        _error = null;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      // A failed refresh keeps the list it had.
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final all = _games;
    final search = _query.text.trim();
    final games = all == null
        ? null
        : [
            for (final game in all)
              if (matchesSearch(game, search)) game,
          ];
    return Scaffold(
      body: FzBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: FzHeaderRow(
                      title: 'Find a game',
                      actions: [
                        FzCircleButton(
                          key: const Key('refreshGamesButton'),
                          icon: Icons.refresh,
                          tooltip: 'Refresh',
                          onPressed: _loading ? null : _load,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                    child: TextField(
                      key: const Key('gameSearchField'),
                      controller: _query,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search by pack, host or code',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: FzColors.dim,
                        ),
                        suffixIcon: _query.text.isEmpty
                            ? null
                            : IconButton(
                                key: const Key('clearGameSearchButton'),
                                tooltip: 'Clear',
                                icon: const Icon(
                                  Icons.close,
                                  color: FzColors.dim,
                                ),
                                onPressed: () => setState(_query.clear),
                              ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Expanded(
                    child: Listener(
                      onPointerDown: (_) => _touch(true),
                      onPointerUp: (_) => _touch(false),
                      onPointerCancel: (_) => _touch(false),
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          key: const Key('gameList'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
                          children: [
                            // Only where it matters: a game here has pictures.
                            if (all?.any((game) => game.hasImages) ?? false)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: PoppersPanel(),
                              ),
                            if (games != null)
                              for (final list in GameList.values)
                                ..._section(fz, list, games),
                            _footer(fz, games, search),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _section(FzTheme fz, GameList list, List<JoinableGame> games) {
    final listed = [
      for (final game in games)
        if (game.list == list) game,
    ];
    if (listed.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: FzEyebrow(_label(list)),
      ),
      for (final game in listed)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GameTile(game: game, onTap: () => _pick(game)),
        ),
    ];
  }

  /// Below the games: loading, a failure, nothing to join, or how many.
  Widget _footer(FzTheme fz, List<JoinableGame>? games, String search) {
    final Widget child;
    if (_error != null) {
      child = FzNotice(
        icon: Icons.cloud_off_outlined,
        title: games == null
            ? "Couldn't load games."
            : "Couldn't refresh the games.",
        detail: 'Your seat and your place are fine.',
        action: FzButton(
          key: const Key('retryGamesButton'),
          label: 'Try again',
          kind: FzButtonKind.outline,
          expand: false,
          height: 48,
          fontSize: 16,
          radius: 14,
          onPressed: _loading ? null : _load,
        ),
      );
    } else if (games == null) {
      child = const FzSkeletonRows();
    } else if (games.isEmpty && search.isNotEmpty) {
      child = FzNotice(
        key: const Key('noGames'),
        icon: Icons.search_off,
        title: 'No games match "$search".',
        detail: 'Try a pack name, a host or a game code.',
      );
    } else if (games.isEmpty) {
      child = const FzNotice(
        key: Key('noGames'),
        icon: Icons.inbox_outlined,
        title: 'No games to join right now',
        detail:
            "Games hosted for anyone, your friends' games and games you're "
            'invited to show up here.',
      );
    } else {
      child = Center(
        child: Text(
          games.length == 1 ? '1 game' : '${games.length} games',
          style: fz.small(),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: child,
    );
  }

  static String _label(GameList list) => switch (list) {
    GameList.invited => 'Invited',
    GameList.friends => "Friends' games",
    GameList.public => 'Public games',
  };
}

/// One game to join: its pack, its host, where it is and how full.
class GameTile extends StatelessWidget {
  const GameTile({super.key, required this.game, required this.onTap});

  final JoinableGame game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final name = game.pack?.name.trim() ?? '';
    final host = game.host?.trim() ?? '';
    final facts = gameFacts(game);
    return FzTile(
      key: Key('game-${game.code}'),
      onTap: onTap,
      framed: true,
      child: Row(
        children: [
          PackImage(url: game.pack?.imageUrl, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FzDirection(
                  text: name,
                  child: Text(
                    name.isEmpty ? 'Game ${game.code}' : name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: fz.h(16, weight: FontWeight.w700, height: 1.2),
                  ),
                ),
                if (host.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  // The words are the app's; only the name takes its own
                  // direction.
                  Row(
                    children: [
                      Text('Hosted by ', style: fz.small(13)),
                      Flexible(
                        child: FzDirection(
                          text: host,
                          child: Text(
                            host,
                            key: const Key('gameHost'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: fz.small(13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    FzTag(
                      gameStage(game),
                      color: game.inLobby ? FzColors.ac : FzColors.ac2,
                    ),
                    if (facts.isNotEmpty) FzTag(facts),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right, color: FzColors.dim),
        ],
      ),
    );
  }
}

/// [fresh] in [before]'s order: games still open keep their places, games
/// that ended drop out, and new ones follow in the relay's order.
List<JoinableGame> keepOrder(
  List<JoinableGame> before,
  List<JoinableGame> fresh,
) {
  final byCode = {for (final game in fresh) game.code: game};
  return [
    for (final game in before) ?byCode.remove(game.code),
    ...byCode.values,
  ];
}

/// Whether [game]'s pack, host or code has [search] in it, ignoring case.
bool matchesSearch(JoinableGame game, String search) {
  final needle = search.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return [
    game.code,
    game.pack?.name,
    game.pack?.description,
    game.host,
  ].any((field) => field != null && field.toLowerCase().contains(needle));
}

/// "Lobby", "Question 8", "Final question", "Playing".
String gameStage(JoinableGame game) => switch (game.stage) {
  GameStage.lobby => 'Lobby',
  GameStage.question =>
    game.questionNumber == null ? 'Playing' : 'Question ${game.questionNumber}',
  GameStage.finalRound => 'Final question',
  GameStage.playing => 'Playing',
};

/// "4 players · photos · 1 popper".
String gameFacts(JoinableGame game) => [
  if (game.playerCount != null)
    game.playerCount == 1 ? '1 player' : '${game.playerCount} players',
  if (game.hasImages) 'photos · 1 popper',
].join(' · ');

/// What joining a game with pictures costs, and what the player has when the
/// app knows.
String popperCost(int? poppers) {
  final have = switch (poppers) {
    null => '',
    0 => ' You have none left.',
    1 => ' You have 1.',
    _ => ' You have $poppers.',
  };
  return 'This game has pictures: joining it takes 1 Party Popper.$have '
      'The host plays free.';
}

/// The player's Party Poppers, and claiming the free ones Sporcle gives back
/// (protocol/PROTOCOL.md §3.5). Buying more is for Sporcle Party's own app.
class PoppersPanel extends ConsumerStatefulWidget {
  const PoppersPanel({super.key});

  @override
  ConsumerState<PoppersPanel> createState() => _PoppersPanelState();
}

class _PoppersPanelState extends ConsumerState<PoppersPanel> {
  bool _claiming = false;

  Future<void> _claim() async {
    if (_claiming) return;
    final before = ref.read(poppersProvider).value?.poppers;
    setState(() => _claiming = true);
    try {
      final balance = await ref.read(poppersProvider.notifier).claim();
      if (!mounted) return;
      final now = balance.poppers;
      showFzToast(
        context,
        now == null
            ? 'Claimed.'
            : now == before
            ? 'None to claim yet: one comes back every 4 hours, up to 5.'
            : 'You have ${now == 1 ? '1 Party Popper' : '$now Party Poppers'}.',
      );
    } on Object catch (error) {
      if (mounted) showError(context, ref, error);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final poppers = ref.watch(poppersProvider).value?.poppers;
    return FzPanel.tone(
      FzColors.ac,
      key: const Key('poppersPanel'),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FzEyebrow(
                  poppers == null
                      ? 'Party Poppers'
                      : 'Party Poppers · $poppers',
                  color: FzColors.ac,
                ),
                const SizedBox(height: 4),
                Text(
                  poppers == null
                      ? 'A game with pictures costs 1 to join, except for its '
                            'host.'
                      : 'You have $poppers. A game with pictures costs 1 to '
                            'join, except for its host.',
                  key: const Key('popperBalance'),
                  style: fz.small(13.5, FzColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FzButton(
            key: const Key('claimPoppersButton'),
            label: 'Claim',
            kind: FzButtonKind.outline,
            expand: false,
            height: 48,
            fontSize: 16,
            radius: 14,
            busy: _claiming,
            onPressed: _claim,
          ),
        ],
      ),
    );
  }
}
