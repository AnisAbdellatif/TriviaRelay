import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';
import '../../shared/widgets/fz_toast.dart';

/// "Name other players see": the handle unless the player chose another, which
/// Sporcle is asked about first, as its own app asks (protocol/PROTOCOL.md
/// §3.7). Kept on this device, and used from the next game on.
class DisplayNameField extends ConsumerStatefulWidget {
  const DisplayNameField({super.key});

  /// As long as the relay passes on.
  static const maxLength = 40;

  @override
  ConsumerState<DisplayNameField> createState() => _DisplayNameFieldState();
}

class _DisplayNameFieldState extends ConsumerState<DisplayNameField> {
  late final _name = TextEditingController(
    text: ref.read(accountProvider).value?.shownName ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final account = ref.read(accountProvider).value;
    if (account == null || _saving) return;
    final typed = _name.text.trim();
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      if (typed.isEmpty || typed == account.handle) {
        await ref.read(accountProvider.notifier).setDisplayName(null);
        _name.text = account.handle;
        if (mounted) showFzToast(context, 'Others see your handle.');
        return;
      }
      final check = await ref.read(relayApiProvider).checkName(account, typed);
      if (!mounted) return;
      if (!check.allowed) {
        showFzToast(context, "Sporcle won't show that name. Try another.");
        return;
      }
      await ref.read(accountProvider.notifier).setDisplayName(check.name);
      _name.text = check.name;
      if (mounted) {
        showFzToast(context, 'Saved. Others see it from your next game.');
      }
    } on Object catch (error) {
      if (mounted) showError(context, ref, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final account = ref.watch(accountProvider).value;
    final changed = account != null && _name.text.trim() != account.shownName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FzEyebrow('Name other players see'),
        const SizedBox(height: 8),
        FzDirection(
          text: _name.text,
          child: TextField(
            key: const Key('displayNameField'),
            controller: _name,
            maxLength: DisplayNameField.maxLength,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: account?.handle ?? 'Your name',
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => changed ? _save() : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your Sporcle handle unless you choose another. It shows from the '
          'next game you join or host.',
          style: fz.m(12, color: FzColors.faint, height: 1.5),
        ),
        const SizedBox(height: 10),
        FzButton(
          key: const Key('saveNameButton'),
          label: _saving ? 'Saving…' : 'Save the name',
          kind: FzButtonKind.outline,
          height: 48,
          fontSize: 15,
          busy: _saving,
          onPressed: changed ? _save : null,
        ),
      ],
    );
  }
}

/// Sound, and on a phone vibration, for the game's moments.
class GameFeedbackSwitches extends ConsumerWidget {
  const GameFeedbackSwitches({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fz = FzTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);

    Widget toggle(
      Key key,
      String title,
      String subtitle,
      bool value,
      AppSettings Function(bool on) change,
    ) => MergeSemantics(
      child: SwitchListTile(
        key: key,
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: (on) => notifier.change((_) => change(on)),
        title: Text(title, style: fz.m(15, weight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: fz.m(12, color: FzColors.dim, height: 1.4),
        ),
      ),
    );

    return Column(
      children: [
        toggle(
          const Key('soundSwitch'),
          'Sounds',
          'A question opening, your answer in, right or wrong, the last '
              'seconds.',
          settings.sound,
          (on) => settings.copyWith(sound: on),
        ),
        // A browser has no buzz to give.
        if (!kIsWeb)
          toggle(
            const Key('hapticsSwitch'),
            'Vibration',
            'A buzz with the same moments.',
            settings.haptics,
            (on) => settings.copyWith(haptics: on),
          ),
      ],
    );
  }
}
