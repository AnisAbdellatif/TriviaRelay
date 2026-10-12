import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';
import '../../shared/widgets/fz_toast.dart';

/// The player's Sporcle friends, to invite to the game they are in, one or
/// all (protocol/PROTOCOL.md §3.6). Sporcle tells each one, in its own app.
class InviteFriendsSheet extends ConsumerStatefulWidget {
  const InviteFriendsSheet({super.key, required this.packId, this.scroll});

  /// The game's pack, which the invitation names.
  final int packId;

  /// The sheet's, as it is dragged taller.
  final ScrollController? scroll;

  static Future<void> show(BuildContext context, {required int packId}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .7,
          minChildSize: .4,
          maxChildSize: 1,
          builder: (context, scroll) => InviteFriendsSheet(
            key: const Key('inviteFriendsSheet'),
            packId: packId,
            scroll: scroll,
          ),
        ),
      );

  @override
  ConsumerState<InviteFriendsSheet> createState() => _InviteFriendsState();
}

class _InviteFriendsState extends ConsumerState<InviteFriendsSheet> {
  final List<Friend> _friends = [];
  int? _nextPage = 0;
  bool _loading = false;
  Object? _error;
  final Set<String> _invited = {};
  final Set<String> _sending = {};
  bool _invitedAll = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final page = _nextPage;
    if (_loading || page == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final account = await ref.read(accountProvider.future);
      if (account == null) throw const GameError(code: 'invalid_player');
      final result = await ref
          .read(relayApiProvider)
          .friends(account, page: page);
      if (!mounted) return;
      final known = {for (final friend in _friends) friend.id};
      final fresh = [
        for (final friend in result.friends)
          if (!known.contains(friend.id)) friend,
      ];
      setState(() {
        _friends.addAll(fresh);
        // A page with nothing new ends the list, however it shifted.
        _nextPage = fresh.isEmpty ? null : result.nextPage;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  /// Invites [friend], or everybody when null.
  Future<void> _invite(Friend? friend) async {
    final key = friend?.id ?? '*';
    if (_sending.contains(key)) return;
    setState(() => _sending.add(key));
    try {
      final account = await ref.read(accountProvider.future);
      final seat = await ref.read(currentSeatProvider.future);
      if (account == null || seat == null) {
        throw const GameError(code: 'seat_not_found');
      }
      await ref
          .read(relayApiProvider)
          .invite(account, seat, packId: widget.packId, friendId: friend?.id);
      if (!mounted) return;
      setState(() {
        if (friend == null) {
          _invitedAll = true;
        } else {
          _invited.add(friend.id);
        }
      });
      showFzToast(
        context,
        friend == null ? 'Invited all your friends.' : 'Invited.',
      );
    } on Object catch (error) {
      if (mounted) showError(context, ref, error);
    } finally {
      if (mounted) setState(() => _sending.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      children: [
        Text('Invite friends', style: fz.t(26)),
        const SizedBox(height: 8),
        Text(
          'Sporcle tells them, in Sporcle Party, that you are in this game.',
          style: fz.m(13, color: FzColors.dim, height: 1.5),
        ),
        const SizedBox(height: 14),
        FzButton(
          key: const Key('inviteAllButton'),
          label: _invitedAll ? 'All invited' : 'Invite all',
          kind: FzButtonKind.outline,
          height: 48,
          fontSize: 15,
          selected: _invitedAll,
          busy: _sending.contains('*'),
          onPressed: _friends.isEmpty ? null : () => _invite(null),
        ),
        const SizedBox(height: 10),
        for (final friend in _friends) _row(fz, friend),
        _footer(fz),
      ],
    );
  }

  Widget _row(FzTheme fz, Friend friend) {
    final invited = _invitedAll || _invited.contains(friend.id);
    final handle = friend.handle;
    return Padding(
      key: Key('friend-${friend.id}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FzDirection(
                  text: friend.name,
                  child: Text(
                    friend.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: fz.h(16, weight: FontWeight.w700),
                  ),
                ),
                if (handle != null && handle != friend.name)
                  FzDirection(
                    text: handle,
                    child: Text(
                      '@$handle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fz.m(12, color: FzColors.dim),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FzButton(
            key: Key('inviteFriend-${friend.id}'),
            label: invited ? 'Invited' : 'Invite',
            kind: FzButtonKind.outline,
            expand: false,
            height: 48,
            fontSize: 14,
            selected: invited,
            busy: _sending.contains(friend.id),
            onPressed: () => _invite(friend),
          ),
        ],
      ),
    );
  }

  Widget _footer(FzTheme fz) {
    final Widget child;
    if (_error != null) {
      child = Column(
        children: [
          Text(
            "Couldn't load your friends.",
            style: fz.m(13, color: FzColors.dim),
          ),
          const SizedBox(height: 10),
          FzButton(
            key: const Key('retryFriendsButton'),
            label: 'Try again',
            kind: FzButtonKind.outline,
            height: 48,
            onPressed: _load,
          ),
        ],
      );
    } else if (_loading) {
      child = const SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_nextPage != null) {
      child = FzButton(
        key: const Key('moreFriendsButton'),
        label: 'More friends',
        kind: FzButtonKind.outline,
        height: 48,
        onPressed: _load,
      );
    } else if (_friends.isEmpty) {
      child = Text(
        'No friends yet. Friends you add in Sporcle Party show up here.',
        key: const Key('noFriends'),
        textAlign: TextAlign.center,
        style: fz.m(13, color: FzColors.dim, height: 1.5),
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(child: child),
    );
  }
}
