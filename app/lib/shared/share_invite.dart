import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/invite/invite_link.dart';
import '../core/providers/config_providers.dart';
import 'platform/platform.dart';
import 'widgets/fz_toast.dart';

/// Hands an invite to game [code] to the platform's share sheet: a link on the
/// relay's own address (`/join/<code>`) that opens the app, or its web page,
/// and offers to join. Where there is no share sheet (a desktop browser), the
/// invite goes on the clipboard instead, ready to paste into any chat.
Future<void> shareInvite(
  BuildContext context,
  WidgetRef ref,
  String code,
) async {
  final link = inviteLink(ref.read(serverBaseUrlProvider), code);
  final text = inviteMessage(link, code);
  if (await platformShare(text)) return;
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    showFzToast(context, 'Invite copied. Paste it to your friends.');
  }
}
