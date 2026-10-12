import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/navigation.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';
import '../../shared/widgets/fz_toast.dart';
import 'pack_tile.dart';

/// One pack up close (protocol/PROTOCOL.md §3.2): what it is, choosing it, and
/// what the player can do to it in Sporcle's catalog — bookmark it, be told
/// when somebody hosts it, report it.
///
/// Whether the player bookmarked it is asked of the relay as the sheet opens:
/// the lists everybody sees don't say.
class PackSheet extends ConsumerStatefulWidget {
  const PackSheet({super.key, required this.pack, this.chooseLabel});

  final PackSummary pack;

  /// The main button's words ("Choose this pack"), or no main button.
  final String? chooseLabel;

  /// Shows [pack]; true when the person chose it.
  static Future<bool> show(
    BuildContext context,
    PackSummary pack, {
    String? chooseLabel = 'Choose this pack',
  }) async {
    final chosen = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PackSheet(pack: pack, chooseLabel: chooseLabel),
    );
    return chosen ?? false;
  }

  @override
  ConsumerState<PackSheet> createState() => _PackSheetState();
}

class _PackSheetState extends ConsumerState<PackSheet> {
  late PackSummary _pack = widget.pack;
  bool _loaded = false;
  bool _bookmarking = false;
  bool _subscribing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final account = await ref.read(accountProvider.future);
      if (account == null) return;
      final pack = await ref.read(relayApiProvider).pack(account, _pack.id);
      if (mounted) setState(() => _pack = pack);
    } on Object {
      // The pack as the list had it is still worth showing.
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _bookmark() async {
    final account = ref.read(accountProvider).value;
    if (account == null || _bookmarking) return;
    final on = !(_pack.bookmarked ?? false);
    setState(() => _bookmarking = true);
    try {
      final now = await ref
          .read(relayApiProvider)
          .setBookmarked(account, _pack.id, on);
      if (!mounted) return;
      setState(() => _pack = _pack.copyWith(bookmarked: now));
      showFzToast(context, now ? 'Bookmarked.' : 'Bookmark removed.');
    } on Object catch (error) {
      if (mounted) {
        showError(
          context,
          ref,
          error is GameError && error.code == 'sporcle_refused'
              ? const GameError(
                  code: 'bookmarks_full',
                  message:
                      "Sporcle wouldn't bookmark it: you may have as many "
                      'bookmarks as it allows.',
                )
              : error,
        );
      }
    } finally {
      if (mounted) setState(() => _bookmarking = false);
    }
  }

  Future<void> _subscribe(bool on) async {
    final account = ref.read(accountProvider).value;
    if (account == null || _subscribing) return;
    setState(() => _subscribing = true);
    try {
      final now = await ref
          .read(relayApiProvider)
          .setSubscribed(account, _pack.id, on);
      if (mounted) setState(() => _pack = _pack.copyWith(subscribed: now));
    } on Object catch (error) {
      if (mounted) showError(context, ref, error);
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  Future<void> _report() async {
    final sent = await Navigator.of(context)
        .push<bool>(FzPageRoute(builder: (_) => ReportPackScreen(pack: _pack)));
    if (sent == true && mounted) {
      showFzToast(context, 'Report sent. Thank you.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final pack = _pack;
    final description = pack.description?.trim() ?? '';
    final bookmarked = pack.bookmarked ?? false;
    return SingleChildScrollView(
      key: const Key('packSheet'),
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PackImage(url: pack.imageUrl, size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FzDirection(
                      text: pack.name,
                      child: Text(
                        pack.name.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: fz.h(20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FzTag(packFacts(pack)),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            FzDirection(
              text: description,
              child: Text(
                description,
                style: fz.m(13, color: FzColors.dim, height: 1.5),
              ),
            ),
          ],
          if (widget.chooseLabel != null) ...[
            const SizedBox(height: 18),
            FzButton(
              key: const Key('choosePackSheetButton'),
              label: widget.chooseLabel!,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
          const SizedBox(height: 11),
          FzButton(
            key: const Key('bookmarkPackButton'),
            label: bookmarked ? 'Bookmarked' : 'Bookmark',
            trailing: bookmarked ? 'tap to remove' : null,
            kind: FzButtonKind.outline,
            height: 48,
            fontSize: 15,
            busy: _bookmarking || !_loaded,
            onPressed: _loaded ? _bookmark : null,
          ),
          const SizedBox(height: 6),
          MergeSemantics(
            child: SwitchListTile(
              key: const Key('subscribePackSwitch'),
              contentPadding: EdgeInsets.zero,
              value: pack.subscribed ?? false,
              onChanged: _loaded && !_subscribing ? _subscribe : null,
              title: Text(
                'Tell me when someone hosts it',
                style: fz.m(14, weight: FontWeight.w600),
              ),
              subtitle: Text(
                "Sporcle Party's own app sends the notice, if you have it.",
                style: fz.m(12, color: FzColors.dim, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('reportPackButton'),
              style: TextButton.styleFrom(foregroundColor: FzColors.ac2),
              onPressed: _report,
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Report this pack'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reporting a pack to Sporcle: a reason from those it offers, and what is
/// wrong, in the player's words; sent only once they confirm. Pops true once
/// it has gone.
class ReportPackScreen extends ConsumerStatefulWidget {
  const ReportPackScreen({super.key, required this.pack});

  final PackSummary pack;

  /// As many characters as Sporcle's own form takes.
  static const maxDetails = 200;

  @override
  ConsumerState<ReportPackScreen> createState() => _ReportPackScreenState();
}

class _ReportPackScreenState extends ConsumerState<ReportPackScreen> {
  final _details = TextEditingController();
  ReportReason? _reason;
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  bool get _ready => _reason != null && _details.text.trim().isNotEmpty;

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || !_ready || _sending) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send this report?'),
        content: const Text(
          'It goes to Sporcle, who look at reported packs and may take one '
          'down. Send it only for a real problem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            key: const Key('confirmReportButton'),
            style: TextButton.styleFrom(foregroundColor: FzColors.ac2),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final account = ref.read(accountProvider).value;
    if (account == null) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(relayApiProvider)
          .reportPack(account, widget.pack.id, reason, _details.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) showError(context, ref, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    return Scaffold(
      body: FzPage(
        header: Row(
          children: [
            FzCircleButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 12),
            const Expanded(child: FzEyebrow('Report a pack')),
          ],
        ),
        footer: FzButton(
          key: const Key('sendReportButton'),
          label: _sending ? 'Sending…' : 'Send report',
          kind: FzButtonKind.pink,
          busy: _sending,
          onPressed: _ready ? _send : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            FzDirection(
              text: widget.pack.name,
              child: Text(widget.pack.name.trim(), style: fz.h(20)),
            ),
            const SizedBox(height: 18),
            const FzEyebrow("What's wrong with it"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final reason in ReportReason.values)
                  ChoiceChip(
                    key: Key('reportReason-${reason.name}'),
                    label: Text(reasonLabel(reason), style: fz.m(13)),
                    selected: reason == _reason,
                    onSelected: (_) => setState(() => _reason = reason),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const FzEyebrow('Tell Sporcle more'),
            const SizedBox(height: 8),
            TextField(
              key: const Key('reportDetailsField'),
              controller: _details,
              minLines: 3,
              maxLines: 6,
              maxLength: ReportPackScreen.maxDetails,
              inputFormatters: [
                LengthLimitingTextInputFormatter(ReportPackScreen.maxDetails),
              ],
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Which question, and what is wrong with it',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}

/// The words for a reason, as the official app puts them.
String reasonLabel(ReportReason reason) => switch (reason) {
  ReportReason.harassment => 'Harassment or bullying',
  ReportReason.offensive => 'Offensive or inappropriate',
  ReportReason.spam => 'Spam',
  ReportReason.inaccurate => 'Wildly inaccurate',
  ReportReason.other => 'Other',
};
