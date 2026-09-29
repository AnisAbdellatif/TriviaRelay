import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:trivia_relay/shared/describe_error.dart';

void main() {
  String words(String code) => describeError(GameError(code: code));

  test('the relay codes of protocol 1.2 read as sentences', () {
    expect(
      words('seats_full'),
      'The relay is full right now. Try again in a few minutes.',
    );
    for (final code in [
      'relay_busy',
      'forbidden_origin',
      'invalid_request',
      'rate_limited',
      'not_everyone_answered',
    ]) {
      final text = words(code);
      expect(text, isNot(contains(code)), reason: code);
      expect(text, endsWith('.'), reason: code);
    }
  });

  test('an unknown code falls back to the relay message, then the code', () {
    expect(
      describeError(const GameError(code: 'someday', message: 'Soon.')),
      'Soon.',
    );
    expect(words('someday'), contains('someday'));
  });
}
