import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/navigation.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import 'pack_tile.dart';

/// Browsing Sporcle's pack catalog, as the official app's pack screen does:
/// its lists (popular, fresh, bookmarked, …), searched or not, a page at a
/// time as the list scrolls (protocol/PROTOCOL.md §3.2). Tapping a pack picks
/// it.
class PackBrowserScreen extends ConsumerStatefulWidget {
  const PackBrowserScreen({super.key, this.selectedId});

  /// The pack already chosen, marked in the list.
  final int? selectedId;

  /// Opens the browser; the pack tapped, or null if none was.
  static Future<PackSummary?> pick(BuildContext context, {int? selectedId}) =>
      Navigator.of(context).push<PackSummary>(
        FzPageRoute(builder: (_) => PackBrowserScreen(selectedId: selectedId)),
      );

  @override
  ConsumerState<PackBrowserScreen> createState() => _PackBrowserScreenState();
}

class _PackBrowserScreenState extends ConsumerState<PackBrowserScreen> {
  // Within this distance of the end of the list, the next page is fetched.
  static const _preload = 800.0;

  final _query = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  PackList _list = PackList.popular;
  String _search = '';
  final List<PackSummary> _packs = [];
  final Set<int> _ids = {};
  int? _nextPage = 0;
  bool _loading = false;
  Object? _error;
  // Bumped on every new list or search, so a page that was on its way for the
  // old one is dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onQuery(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = text.trim();
      // One letter matches everything; wait for a second.
      if (query.length == 1 || query == _search) return;
      _search = query;
      _restart();
    });
  }

  void _choose(PackList list) {
    if (list == _list) return;
    _list = list;
    _restart();
  }

  void _restart() {
    setState(() {
      _generation++;
      _packs.clear();
      _ids.clear();
      _nextPage = 0;
      _loading = false;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    unawaited(_load());
  }

  void _maybeLoadMore() {
    if (_scroll.hasClients && _scroll.position.extentAfter < _preload) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final page = _nextPage;
    if (_loading || page == null || _error != null) return;
    final generation = _generation;
    setState(() => _loading = true);
    try {
      final account = await ref.read(accountProvider.future);
      if (account == null) throw const GameError(code: 'invalid_player');
      final result = await ref
          .read(relayApiProvider)
          .searchPacks(account, query: _search, list: _list, page: page);
      if (!mounted || generation != _generation) return;
      final before = _packs.length;
      setState(() {
        for (final pack in result.packs) {
          if (_ids.add(pack.id)) _packs.add(pack);
        }
        // A page with nothing new is the end too: lists can shift under
        // paging, and this never asks for the same packs forever.
        _nextPage = _packs.length == before ? null : result.nextPage;
        _loading = false;
      });
      // A short first page may not fill the screen, so nothing would scroll.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeLoadMore();
      });
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _retry() {
    setState(() => _error = null);
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
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
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                    child: Row(
                      children: [
                        FzCircleButton(
                          icon: Icons.arrow_back,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Pick a pack', style: fz.t(28))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                    child: TextField(
                      key: const Key('packSearchField'),
                      controller: _query,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search ${_label(_list).toLowerCase()} packs',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: FzColors.dim,
                        ),
                        suffixIcon: _query.text.isEmpty
                            ? null
                            : IconButton(
                                key: const Key('clearSearchButton'),
                                tooltip: 'Clear',
                                icon: const Icon(
                                  Icons.close,
                                  color: FzColors.dim,
                                ),
                                onPressed: () {
                                  _query.clear();
                                  _onQuery('');
                                  setState(() {});
                                },
                              ),
                      ),
                      onChanged: (text) {
                        setState(() {});
                        _onQuery(text);
                      },
                      onSubmitted: _onQuery,
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      children: [
                        for (final list in PackList.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              key: Key('packList-${list.name}'),
                              label: Text(_label(list), style: fz.m(13)),
                              selected: list == _list,
                              onSelected: (_) => _choose(list),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      key: const Key('packList'),
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 22),
                      itemCount: _packs.length + 1,
                      itemBuilder: (context, i) {
                        if (i == _packs.length) return _footer(fz);
                        final pack = _packs[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PackTile(
                            pack: pack,
                            selected: pack.id == widget.selectedId,
                            onTap: () => Navigator.of(context).pop(pack),
                          ),
                        );
                      },
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

  /// Below the last pack: more coming, the end, nothing at all, or a failure.
  Widget _footer(FzTheme fz) {
    final Widget child;
    if (_error != null) {
      child = Column(
        children: [
          Text("Couldn't load packs.", style: fz.m(13, color: FzColors.dim)),
          const SizedBox(height: 10),
          FzButton(
            key: const Key('retryPacksButton'),
            label: 'Try again',
            kind: FzButtonKind.outline,
            height: 44,
            onPressed: _retry,
          ),
        ],
      );
    } else if (_loading || _nextPage != null) {
      child = const SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_packs.isEmpty) {
      child = Text(
        _empty,
        key: const Key('noPacks'),
        textAlign: TextAlign.center,
        style: fz.m(13, color: FzColors.dim, height: 1.5),
      );
    } else {
      child = Text(
        _packs.length == 1 ? '1 pack' : '${_packs.length} packs',
        style: fz.m(12, color: FzColors.faint),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(child: child),
    );
  }

  String get _empty {
    if (_search.isNotEmpty) {
      return 'No ${_label(_list).toLowerCase()} packs match "$_search".';
    }
    return switch (_list) {
      PackList.bookmarked =>
        'Packs you bookmark in Sporcle Party show up here.',
      PackList.created => 'Packs you make in Sporcle Party show up here.',
      PackList.friends => "Your friends' packs show up here.",
      PackList.purchased => 'Packs you have bought show up here.',
      _ => 'No packs here.',
    };
  }

  static String _label(PackList list) => switch (list) {
    PackList.popular => 'Popular',
    PackList.fresh => 'Fresh',
    PackList.bookmarked => 'Bookmarked',
    PackList.created => 'Created',
    PackList.friends => 'Friends',
    PackList.purchased => 'Purchased',
    PackList.free => 'Free',
    PackList.all => 'All',
  };
}
