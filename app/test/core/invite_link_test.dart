import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_relay/core/invite/invite_link.dart';

void main() {
  test('an invite link carries a game code, and nothing else counts', () {
    expect(
      inviteCode(Uri.parse('https://relay.example/join/624949')),
      '624949',
    );
    expect(inviteCode(Uri.parse('https://relay.example/join/1234/')), '1234');
    expect(inviteCode(Uri.parse('https://x/join/12345678?utm=1')), '12345678');

    for (final link in [
      'https://relay.example/',
      'https://relay.example/join/',
      'https://relay.example/join/123',
      'https://relay.example/join/123456789',
      'https://relay.example/join/12a4',
      'https://relay.example/join/1234/more',
      'https://relay.example/other/1234',
      'https://relay.example/join/%EF%BC%91%EF%BC%92%EF%BC%93%EF%BC%94',
    ]) {
      expect(inviteCode(Uri.parse(link)), isNull, reason: link);
    }
  });

  test('a route as a platform hands it over reads the same way', () {
    expect(inviteCodeFromRoute('/join/1234'), '1234');
    expect(inviteCodeFromRoute('/join/1234?x=1'), '1234');
    expect(inviteCodeFromRoute('/'), isNull);
    expect(inviteCodeFromRoute(null), isNull);
    expect(inviteCodeFromRoute('::not a uri'), isNull);
  });

  test("the link is on the relay's own address", () {
    expect(
      inviteLink('https://relay.example', '624949'),
      'https://relay.example/join/624949',
    );
    expect(
      inviteLink('https://relay.example/', '1234'),
      'https://relay.example/join/1234',
    );
    expect(
      inviteLink('http://localhost:4100', '1234'),
      'http://localhost:4100/join/1234',
    );
  });

  test("the invite speaks as this app, never as Sporcle's", () {
    final text = inviteMessage('https://relay.example/join/1234', '1234');
    expect(text, contains('https://relay.example/join/1234'));
    expect(text, contains('1234'));
    expect(text.toLowerCase(), isNot(contains('sporcle')));
  });
}
