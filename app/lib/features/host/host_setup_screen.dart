import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import 'pack_browser_screen.dart';
import 'pack_tile.dart';
import 'spectate_switch.dart';

/// Choosing a pack from Sporcle's catalog and the game's options, then
/// creating the game (protocol/PROTOCOL.md §3.3). Invite-only unless the host
/// says otherwise: a game open to anyone draws strangers within seconds.
class HostSetupScreen extends ConsumerStatefulWidget {
  const HostSetupScreen({super.key});

  @override
  ConsumerState<HostSetupScreen> createState() => _HostSetupScreenState();
}

class _HostSetupScreenState extends ConsumerState<HostSetupScreen> {
  PackSummary? _pack;
  HostOptions _options = const HostOptions();
  bool _creating = false;

  Future<void> _create() async {
    final account = ref.read(accountProvider).value;
    final pack = _pack;
    if (account == null || pack == null || _creating) return;
    setState(() => _creating = true);
    try {
      await openSeat(
        context,
        ref,
        () => ref.read(relayApiProvider).host(account, pack.id, _options),
      );
    } on Object catch (error) {
      if (mounted) showError(context, ref, error);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _choosePack() async {
    final pack = await PackBrowserScreen.pick(context, selectedId: _pack?.id);
    if (pack != null && mounted) setState(() => _pack = pack);
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    return Scaffold(
      body: FzPage(
        header: const FzHeaderRow(title: 'Host a game', eyebrow: true),
        footer: FzButton(
          key: const Key('createGameButton'),
          label: _creating
              ? 'Creating…'
              : _pack == null
              ? 'Choose a pack'
              : 'Create the game',
          trailing: _pack == null ? null : _summary(_options),
          busy: _creating,
          onPressed: _creating
              ? null
              : _pack == null
              ? _choosePack
              : _create,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            Text('Set up tonight’s game', style: fz.display(34)),
            const SizedBox(height: 12),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: FzAccentBars(),
            ),
            const SizedBox(height: 22),
            const FzEyebrow('Pack'),
            const SizedBox(height: 8),
            _PackChoice(pack: _pack, onTap: _choosePack),
            const SizedBox(height: 20),
            const FzEyebrow('Questions'),
            const SizedBox(height: 8),
            _Choices<int>(
              keyPrefix: 'questions',
              values: HostOptions.questionsPerGameChoices,
              selected: _options.questionsPerGame,
              label: (n) => '$n',
              onSelected: (n) => setState(
                () => _options = _options.copyWith(questionsPerGame: n),
              ),
            ),
            const SizedBox(height: 20),
            const FzEyebrow('Seconds per question'),
            const SizedBox(height: 8),
            _Choices<int>(
              keyPrefix: 'seconds',
              values: HostOptions.questionSecondsChoices,
              selected: _options.questionSeconds,
              label: (n) => '${n}s',
              onSelected: (n) => setState(
                () => _options = _options.copyWith(questionSeconds: n),
              ),
            ),
            const SizedBox(height: 20),
            const FzEyebrow('Who can join'),
            const SizedBox(height: 8),
            _Choices<Audience>(
              keyPrefix: 'audience',
              values: Audience.values,
              selected: _options.audience,
              label: audienceLabel,
              // Open to anyone is the one with stakes: strangers come.
              accent: (a) => a == Audience.anyone ? FzColors.ac2 : FzColors.ac,
              onSelected: (a) =>
                  setState(() => _options = _options.copyWith(audience: a)),
            ),
            if (_options.audience == Audience.anyone) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: FzColors.ac2,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Listed publicly: strangers join within seconds.',
                      style: fz.small(13.5, FzColors.ac2),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            const FzEyebrow('Host only'),
            const SizedBox(height: 4),
            SpectateSwitch(
              key: const Key('spectateSwitch'),
              value: _options.spectate,
              onChanged: (spectate) => setState(
                () => _options = _options.copyWith(spectate: spectate),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static String _summary(HostOptions o) =>
      '${o.questionsPerGame} × ${o.questionSeconds}s'
      '${o.spectate ? ' · watching' : ''}';
}

String audienceLabel(Audience audience) => switch (audience) {
  Audience.private => 'Invite only',
  Audience.friends => 'Friends',
  Audience.anyone => 'Anyone',
};

/// The pack for the game: a way into the browser until one is chosen, then the
/// pack itself, tappable to choose another.
class _PackChoice extends StatelessWidget {
  const _PackChoice({required this.pack, required this.onTap});

  final PackSummary? pack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final pack = this.pack;
    if (pack != null) {
      return Row(
        children: [
          Expanded(
            child: PackTile(pack: pack, onTap: onTap, selected: true),
          ),
          const SizedBox(width: 8),
          FzButton(
            label: 'Change',
            kind: FzButtonKind.outline,
            expand: false,
            height: 64,
            fontSize: 16,
            radius: 14,
            onPressed: onTap,
          ),
        ],
      );
    }
    return FzTile(
      key: const Key('choosePackButton'),
      onTap: onTap,
      framed: true,
      child: Row(
        children: [
          const PackImage(url: null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose a pack', style: fz.h(16, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  'Browse popular and fresh packs, or search',
                  style: fz.small(13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: FzColors.dim),
        ],
      ),
    );
  }
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.keyPrefix,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.accent,
  });

  final Color Function(T)? accent;
  final String keyPrefix;
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          fzChoiceChip(
            key: Key('$keyPrefix-$value'),
            label: label(value),
            accent: accent?.call(value) ?? FzColors.ac,
            selected: value == selected,
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}
