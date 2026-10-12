import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';
import '../host/pack_browser_screen.dart';
import '../host/pack_tile.dart';
import 'game_screen.dart';

/// The lobby's pack votes, as in the official app: players vote for up to
/// [GameRules.maxPackVotes] packs a game, from the catalog or among those
/// already voted for, and the host sees the tallies and can switch to one.
class PackVotesPanel extends ConsumerWidget {
  const PackVotesPanel({super.key, required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fz = FzTheme.of(context);
    final canAct = ref.watch(seatInteractiveProvider);
    final pending = ref.watch(pendingIntentsProvider);
    final host = state.you.host;
    final votes = state.packVotes;
    final mine = votes.where((v) => v.you).length;
    final left = GameRules.maxPackVotes - mine;

    if (host && votes.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const Key('packVotes'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        FzEyebrow(
          votes.isEmpty ? 'Pack votes' : 'Pack votes · ${votes.length}',
        ),
        const SizedBox(height: 4),
        Text(
          host
              ? 'Tap a pack to play it instead.'
              : 'Vote for up to ${GameRules.maxPackVotes} packs you’d rather '
                    'play; the host sees them. Tap one to take your vote back.',
          style: fz.m(12, color: FzColors.dim, height: 1.4),
        ),
        const SizedBox(height: 8),
        for (final vote in votes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _VoteTile(
              vote: vote,
              current: vote.pack.id == state.pack?.id,
              busy: pending.containsKey('packVote:${vote.pack.id}'),
              hint: host
                  ? 'play this pack'
                  : vote.you
                  ? 'take your vote back'
                  : 'vote for it',
              onTap: !canAct || (!host && !vote.you && left <= 0)
                  ? null
                  : host
                  ? () => _play(context, ref, vote.pack)
                  : () => act(
                      context,
                      ref,
                      (c) => c.packVote(vote.pack.id, vote: !vote.you),
                      pending: 'packVote:${vote.pack.id}',
                    ),
            ),
          ),
        if (!host)
          FzButton(
            key: const Key('votePackButton'),
            label: 'Vote for a pack',
            trailing: '$left of ${GameRules.maxPackVotes} left',
            kind: FzButtonKind.outline,
            height: 48,
            fontSize: 15,
            busy: pending.containsKey('packVote'),
            onPressed: canAct && left > 0 ? () => _pick(context, ref) : null,
          ),
      ],
    );
  }

  /// The host plays a voted pack: the usual change of pack.
  Future<void> _play(BuildContext context, WidgetRef ref, Pack pack) async {
    if (pack.id == state.pack?.id) return;
    await _choose(context, ref, pack.id, 'packVote:${pack.id}');
  }

  /// A player picks a pack from the catalog to vote for.
  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final pack = await PackBrowserScreen.pick(context);
    if (pack == null || !context.mounted) return;
    for (final vote in state.packVotes) {
      if (vote.pack.id != pack.id) continue;
      if (vote.you) return;
      await act(
        context,
        ref,
        (c) => c.packVote(pack.id, vote: true),
        pending: 'packVote:${pack.id}',
      );
      return;
    }
    if (!context.mounted) return;
    await _choose(context, ref, pack.id, 'packVote');
  }

  /// Choosing a pack over HTTP (protocol/PROTOCOL.md §3.3): the relay fetches
  /// it whole with the player's credentials, then the host's changes the
  /// game's pack and anybody else's is a vote.
  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    int packId,
    String key,
  ) async {
    try {
      final account = await ref.read(accountProvider.future);
      final seat = await ref.read(currentSeatProvider.future);
      if (account == null || seat == null) return;
      await ref
          .read(pendingIntentsProvider.notifier)
          .run(
            key,
            () => ref.read(relayApiProvider).changePack(account, seat, packId),
          );
    } on Object catch (error) {
      if (context.mounted) showError(context, ref, error);
    }
  }
}

class _VoteTile extends StatelessWidget {
  const _VoteTile({
    required this.vote,
    required this.current,
    required this.busy,
    required this.hint,
    required this.onTap,
  });

  final PackVote vote;

  /// The pack the game is on now.
  final bool current;
  final bool busy;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final pack = vote.pack;
    return Semantics(
      key: Key('packVote-${pack.id}'),
      selected: vote.you,
      onTapHint: hint,
      child: FzTile(
        onTap: busy ? null : onTap,
        radius: 14,
        child: FzPanel(
          borderColor: vote.you ? FzColors.ac : FzColors.edge,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PackImage(url: pack.imageUrl, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FzDirection(
                      text: pack.name,
                      child: Text(
                        pack.name.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: fz.h(15, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        FzTag(
                          '${vote.votes} vote${vote.votes == 1 ? '' : 's'}',
                          color: FzColors.ac,
                        ),
                        if (vote.you) const FzTag('your vote'),
                        if (current) const FzTag('playing now'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  vote.you ? Icons.how_to_vote : Icons.how_to_vote_outlined,
                  color: vote.you ? FzColors.ac : FzColors.dim,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
