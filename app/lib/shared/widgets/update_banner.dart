import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/update_providers.dart';
import '../theme/fz_theme.dart';
import 'fz.dart';
import 'fz_toast.dart';

/// Offers the newer APK on the home screen, once, until it is waved away.
///
/// Shows nothing at all when there is nothing to offer — which is every web
/// build, every development build, and every Android build that is already
/// current (`core/update/app_version.dart`). It is a `SizedBox.shrink` in
/// those cases rather than a conditional at the call site, so the home screen
/// does not have to know any of that.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fz = FzTheme.of(context);
    // An automatic check that failed or is still running is not worth a
    // placeholder: there is nothing to say yet.
    final status = ref.watch(availableUpdateProvider).value;
    final release = status?.release;
    if (release == null || status!.dismissed) return const SizedBox.shrink();

    final size = release.sizeLabel;

    // At the top of the home screen, above its title. The button sits under
    // the words, so large text or a narrow phone never squeezes either.
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: FzPanel.tone(
        FzColors.ac,
        radius: 16,
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FzEyebrow(
                    size == null ? 'New version' : 'New version · $size',
                    color: FzColors.ac,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trivia Relay ${release.version} is out.',
                    style: fz.h(14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  FzButton(
                    key: const Key('updateDownloadButton'),
                    label: 'Get it',
                    expand: false,
                    height: 44,
                    fontSize: 16,
                    radius: 14,
                    onPressed: () => _download(context, ref),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('updateDismissButton'),
              tooltip: 'Not now',
              onPressed: () =>
                  ref.read(availableUpdateProvider.notifier).dismiss(),
              icon: const Icon(Icons.close, size: 20),
              color: FzColors.dim,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final opened = await ref.read(availableUpdateProvider.notifier).download();
    if (!opened && context.mounted) {
      showFzToast(context, 'Could not open the download.');
    }
  }
}
