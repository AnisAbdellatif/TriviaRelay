import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/config_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../core/time/server_clock.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';
import '../../shared/widgets/fz_motion.dart';

/// A snapshot's notice (protocol/PROTOCOL.md §5.1), as a banner under the top
/// bar until its time is up or the player closes it: the host sent everyone
/// back to the lobby, handed over the game, or the game itself has something
/// to say. The official app shows the same things in a banner from the top.
class NoticeBanner extends ConsumerStatefulWidget {
  const NoticeBanner({super.key, required this.notice});

  final Notice? notice;

  @override
  ConsumerState<NoticeBanner> createState() => _NoticeBannerState();
}

class _NoticeBannerState extends ConsumerState<NoticeBanner> {
  Timer? _timer;

  /// The notice the player closed, so the next snapshot doesn't bring it
  /// back.
  Notice? _closed;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(NoticeBanner old) {
    super.didUpdateWidget(old);
    if (old.notice != widget.notice) _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _left(Notice notice) => remainingMs(
    deadline: notice.until,
    offsetMs: ref.read(serverClockOffsetProvider),
    localNowMs: ref.read(clockProvider)().millisecondsSinceEpoch,
  );

  /// Rebuilds once the notice's time is up, which takes it away.
  void _schedule() {
    _timer?.cancel();
    final notice = widget.notice;
    if (notice == null) return;
    _timer = Timer(Duration(milliseconds: _left(notice) + 1), () {
      if (mounted) setState(() {});
    });
  }

  static (String, String) words(Notice notice) => switch (notice.kind) {
    Notice.toLobby => (
      'Back to the lobby',
      'The host returned everyone to the lobby.',
    ),
    Notice.promoted => ("You're the host now", 'The host handed you the game.'),
    Notice.hostLeft => (
      "You're the host now",
      'The host left the game, so it’s yours to run.',
    ),
    Notice.popperSpent => (
      'Popper spent',
      'Joining this game with pictures used 1 of your Party Poppers.',
    ),
    _ => (notice.title?.trim() ?? '', notice.message?.trim() ?? ''),
  };

  @override
  Widget build(BuildContext context) {
    final notice = widget.notice;
    // A kind this app doesn't know shows only with words of its own.
    final show =
        notice != null &&
        notice != _closed &&
        _left(notice) > 0 &&
        words(notice) != ('', '');
    final quick = reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    Widget banner() {
      final (title, message) = words(notice!);
      // Flare for a warning or an error, as the official banner's border;
      // Signal otherwise.
      final tone = switch (notice.level) {
        'warn' || 'error' => FzColors.ac2,
        'success' => FzColors.ok,
        _ => FzColors.ac,
      };
      return Semantics(
        liveRegion: true,
        child: FzBanner(
          key: const Key('noticeBanner'),
          tone: tone,
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          title: title.isEmpty
              ? const SizedBox.shrink()
              : FzDirection(text: title, child: Text(title)),
          detail: message.isEmpty ? null : message,
          trailing: IconButton(
            key: const Key('closeNoticeButton'),
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: FzColors.dim, size: 20),
            onPressed: () => setState(() => _closed = notice),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AnimatedSize(
          duration: quick,
          alignment: Alignment.topCenter,
          child: show ? banner() : const SizedBox(width: double.infinity),
        ),
      ),
    );
  }
}
