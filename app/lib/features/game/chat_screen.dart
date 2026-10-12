import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connection/seat_connection.dart';
import '../../core/game/social.dart';
import '../../core/models/models.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/connection_banner.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';
import 'question_view.dart';

/// The game's chat (protocol/PROTOCOL.md §6.6), over the game screen: the
/// latest messages, who is typing, and a field to write in.
///
/// While it is open the relay has the chat open with the game (`chat_open`,
/// again after a reconnect), and closing it says so (`chat_close`), as the
/// official app's chat screen does. It closes itself when the game needs the
/// player (a question to answer, a final vote to cast), where the official app
/// has no chat.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  /// How long after the last key the player counts as having stopped typing.
  static const typingPause = Duration(milliseconds: 2500);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  /// The connection the chat was last opened on, to close it on leaving:
  /// a new one (the app attached again) is opened as it connects.
  late SeatConnection _connection;
  Timer? _typingTimer;
  bool _typing = false;
  bool _sending = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_typing) _say(() => _connection.chatTyping(false));
    _say(_connection.chatClose);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open() {
    _connection = ref.read(seatConnectionProvider);
    _say(_connection.chatOpen);
  }

  /// Best effort: the chat's comings and goings aren't worth an error.
  void _say(Future<void> Function() intent) {
    unawaited(intent().catchError((Object _) {}));
  }

  void _changed(String text) {
    setState(() {});
    final typing = text.trim().isNotEmpty;
    _typingTimer?.cancel();
    if (typing) {
      _typingTimer = Timer(ChatScreen.typingPause, () => _setTyping(false));
    }
    _setTyping(typing);
  }

  void _setTyping(bool typing) {
    if (typing == _typing) return;
    _typing = typing;
    _say(() => ref.read(seatConnectionProvider).chatTyping(typing));
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(seatConnectionProvider).chatSend(text);
      _text.clear();
      // Sending ends the typing, at the relay too.
      _typingTimer?.cancel();
      _typing = false;
    } on Object catch (error) {
      if (mounted) showError(context, ref, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final state = ref.watch(seatStateProvider).value;
    final interactive = ref.watch(seatInteractiveProvider);

    ref
      // Back in after a dropped connection: the relay closed the chat with it.
      ..listen(connectionStatusProvider, (before, now) {
        if (now.value == ConnectionStatus.connected &&
            before?.value != ConnectionStatus.connected) {
          _open();
        }
      })
      ..listen(seatStateProvider, (_, next) {
        final state = next.value;
        if (state != null && !chatOffered(state)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _close();
          });
        }
      })
      ..listen(seatClosedProvider, (_, reason) {
        if (reason != null) _close();
      });

    final chat = state?.chat ?? const ChatState();
    final length = _text.text.characters.length;
    final canSend =
        interactive && !_sending && _text.text.trim().isNotEmpty && !_closing;

    return Scaffold(
      body: FzBackground(
        arcs: null,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 6),
                    child: Row(
                      children: [
                        FzCircleButton(
                          key: const Key('chatBackButton'),
                          icon: Icons.arrow_back,
                          tooltip: 'Back to the game',
                          onPressed: _close,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: const FzEyebrow('Chat', maxLines: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ConnectionBanner(),
                  Expanded(
                    child: _Messages(
                      chat: chat,
                      onMore: interactive
                          ? () =>
                                _say(ref.read(seatConnectionProvider).chatMore)
                          : null,
                    ),
                  ),
                  _Typing(names: chat.typing),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FzTypingDirection(
                            controller: _text,
                            child: TextField(
                              key: const Key('chatField'),
                              controller: _text,
                              focusNode: _focus,
                              readOnly: !interactive,
                              maxLength: GameRules.chatMaxLength,
                              textInputAction: TextInputAction.send,
                              minLines: 1,
                              maxLines: 3,
                              buildCounter:
                                  (
                                    context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) => Text(
                                    '$length/${GameRules.chatMaxLength}',
                                    key: const Key('chatCounter'),
                                    semanticsLabel:
                                        '$length of '
                                        '${GameRules.chatMaxLength} characters',
                                    style: fz.m(
                                      11,
                                      color:
                                          length > GameRules.chatMaxLength - 20
                                          ? FzColors.ac2
                                          : FzColors.dim,
                                    ),
                                  ),
                              style: fz.h(16, weight: FontWeight.w500),
                              decoration: const InputDecoration(
                                hintText: 'Say something',
                              ),
                              onChanged: _changed,
                              onSubmitted: (_) {
                                if (canSend) unawaited(_send());
                                _focus.requestFocus();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: IconButton.filled(
                            key: const Key('chatSendButton'),
                            tooltip: 'Send',
                            onPressed: canSend ? _send : null,
                            style: IconButton.styleFrom(
                              backgroundColor: FzColors.ac,
                              foregroundColor: FzColors.bgDeep,
                              minimumSize: const Size(48, 48),
                            ),
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: FzColors.bgDeep,
                                    ),
                                  )
                                : const Icon(Icons.send),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The messages, the latest at the bottom, and earlier ones on asking.
class _Messages extends StatelessWidget {
  const _Messages({required this.chat, required this.onMore});

  final ChatState chat;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final messages = chat.messages.reversed.toList();
    if (messages.isEmpty && !chat.hasMore) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            chat.loading ? 'Loading…' : 'No messages yet. Say hello!',
            textAlign: TextAlign.center,
            style: fz.m(13, color: FzColors.dim),
          ),
        ),
      );
    }
    final more = chat.hasMore ? 1 : 0;
    return ListView.builder(
      key: const Key('chatMessages'),
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: messages.length + more,
      itemBuilder: (context, i) {
        if (i == messages.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: chat.loading
                  ? const FzWaiting('Loading earlier messages')
                  : TextButton(
                      key: const Key('chatMoreButton'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: onMore,
                      child: const Text('Earlier messages'),
                    ),
            ),
          );
        }
        final message = messages[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: message.system
              ? _SystemMessage(message: message)
              : _Bubble(message: message),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final own = message.own;
    final name = own ? 'You' : (message.name?.trim() ?? '');
    final shown = name.isEmpty ? 'Someone' : name;
    final text = message.text.trim();
    final image = message.imageUrl;
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: .86,
        alignment: own ? Alignment.centerRight : Alignment.centerLeft,
        child: Align(
          alignment: own ? Alignment.centerRight : Alignment.centerLeft,
          child: MergeSemantics(
            child: Container(
              key: ValueKey('chatMessage-${message.id}'),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: own
                    ? FzColors.ac.withValues(alpha: .12)
                    : FzColors.panel,
                border: Border.all(
                  color: own ? FzColors.ac : FzColors.edge,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FzDirection(
                    text: shown,
                    child: Text(
                      shown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fz.m(12, color: own ? FzColors.ac : FzColors.dim),
                    ),
                  ),
                  if (text.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    FzDirection(
                      text: text,
                      child: Text(
                        text,
                        style: fz.h(16, weight: FontWeight.w500),
                      ),
                    ),
                  ],
                  if (image != null) ...[
                    const SizedBox(height: 6),
                    Semantics(
                      image: true,
                      label: 'A picture',
                      child: QuestionImage(url: image, height: 140),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A message from the game itself, not a player.
class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final text = message.text.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: FzDirection(
        text: text,
        child: Text(
          text,
          key: ValueKey('chatMessage-${message.id}'),
          textAlign: TextAlign.center,
          style: fz.m(12, color: FzColors.dim, height: 1.4),
        ),
      ),
    );
  }
}

/// Who else is typing, as the official app says it: up to three names, then
/// how many more.
class _Typing extends StatelessWidget {
  const _Typing({required this.names});

  final List<String> names;

  static String words(List<String> names) {
    if (names.isEmpty) return '';
    final shown = [for (final n in names.take(3)) isolate(n.trim())];
    final more = names.length - shown.length;
    final who = switch ((shown.length, more)) {
      (1, _) => shown.first,
      (2, 0) => '${shown[0]} and ${shown[1]}',
      (3, 0) => '${shown[0]}, ${shown[1]} and ${shown[2]}',
      _ => '${shown.join(', ')} and $more more',
    };
    return names.length == 1 ? '$who is typing…' : '$who are typing…';
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final text = words(names);
    return Semantics(
      liveRegion: text.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 2),
        child: Text(
          text,
          key: const Key('chatTyping'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: fz.m(12, color: FzColors.dim),
        ),
      ),
    );
  }
}
