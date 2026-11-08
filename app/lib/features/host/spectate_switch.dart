import 'package:flutter/material.dart';

import '../../shared/theme/fz_theme.dart';

/// The host's choice to run the game without playing, as the official app's
/// "Host this game as a spectator": no answers, votes or wagers, just the
/// reveals and the marks. Offered when creating the game and in the lobby.
class SpectateSwitch extends StatelessWidget {
  const SpectateSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Text(
        'Host as a spectator',
        style: fz.h(16, weight: FontWeight.w700),
      ),
      subtitle: Text(
        'Run the game without playing: you reveal and mark, the others answer.',
        style: fz.small(13),
      ),
    );
  }
}
