import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/account_providers.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';

/// Signing in with a Sporcle account. Sporcle seats only signed-in players, so
/// there is nothing to do before this.
///
/// The password is used for the login and forgotten (protocol/PROTOCOL.md
/// §3.1): on Android it goes straight to sporcle.com; a browser may not call
/// sporcle.com, so the web build passes it through the relay, which keeps none
/// of it.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _complete =>
      _email.text.trim().contains('@') && _password.text.isNotEmpty;

  Future<void> _signIn() async {
    if (!_complete || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(accountProvider.notifier)
          .signIn(_email.text, _password.text);
    } on Object catch (error) {
      if (mounted) showError(context, ref, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    return Scaffold(
      body: FzPage(
        footer: FzButton(
          key: const Key('signInButton'),
          label: _busy ? 'Signing in…' : 'Sign in with Sporcle',
          onPressed: _complete && !_busy ? _signIn : null,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The mark's box has air on its left; pull it back to the edge.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Transform.translate(
                  offset: const Offset(-10, 0),
                  child: const FzMark(),
                ),
              ),
              const SizedBox(height: 14),
              Text('Trivia Relay', style: fz.t(44)),
              const SizedBox(height: 16),
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: FzAccentBars(),
              ),
              const SizedBox(height: 18),
              Text(
                'Sporcle Party games that keep your place '
                'when your phone drops.',
                style: fz.m(
                  15,
                  weight: FontWeight.w400,
                  color: FzColors.dim,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              const FzEyebrow('Your Sporcle account'),
              const SizedBox(height: 10),
              TextField(
                key: const Key('emailField'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Email'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('passwordField'),
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.go,
                decoration: const InputDecoration(hintText: 'Password'),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _signIn(),
              ),
              const SizedBox(height: 16),
              Text(
                kIsWeb
                    ? 'Your password passes through this app’s relay to '
                          'Sporcle, and is kept by neither this app nor the '
                          'relay.'
                    : 'Your password goes to Sporcle and nowhere else. The '
                          'app keeps only the sign-in Sporcle gives back.',
                style: fz.m(12, color: FzColors.faint, height: 1.5),
              ),
              const SizedBox(height: 10),
              Text(
                'Trivia Relay is not made by Sporcle. It plays Sporcle Party '
                'games with your own account.',
                style: fz.m(12, color: FzColors.faint, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
