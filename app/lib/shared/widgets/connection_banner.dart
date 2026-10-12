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
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          margin: const EdgeInsets.fromLTRB(22, 8, 22, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: FzColors.ac2.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              FzBlink(
                period: const Duration(milliseconds: 500),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: FzColors.ac2,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FzEyebrow(text, color: FzColors.ac2, maxLines: 1),
              ),
              if (status == ConnectionStatus.disconnected &&
                  onReconnect != null)
                TextButton(
                  key: const Key('reconnectButton'),
                  onPressed: onReconnect,
                  style: TextButton.styleFrom(foregroundColor: FzColors.ac2),
                  child: const Text('Reconnect'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
