import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connection/seat_connection.dart';
import '../../core/providers/connection_providers.dart';
import '../theme/fz_theme.dart';
import 'fz.dart';

/// A rounded Flare strip under the top bar while the socket is reconnecting
/// or lost. Lost for good ([ConnectionStatus.disconnected]: the relay turned
/// a rejoin down), it offers [onReconnect] rather than leaving the last
/// snapshot on screen as if it were live.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key, this.onReconnect});

  final VoidCallback? onReconnect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider).value;
    final text = switch (status) {
      ConnectionStatus.reconnecting => 'Reconnecting…',
      ConnectionStatus.disconnected => 'Disconnected',
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: FzBanner(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          leading: FzBanner.dot(FzColors.ac2, pulse: true),
          title: Text(text),
          trailing:
              status == ConnectionStatus.disconnected && onReconnect != null
              ? FzButton(
                  key: const Key('reconnectButton'),
                  label: 'Reconnect',
                  onPressed: onReconnect,
                  kind: FzButtonKind.outline,
                  expand: false,
                  height: 44,
                  fontSize: 14,
                  radius: 14,
                )
              : null,
        ),
      ),
    );
  }
}
