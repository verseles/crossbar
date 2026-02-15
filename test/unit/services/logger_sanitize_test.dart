import 'package:crossbar/services/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoggerService.sanitize', () {
    test('redacts long alphanumeric tokens after = or :', () {
      final input = 'key=AAAABBBBCCCCDDDDEEEEFFFFGGGG';
      final result = LoggerService.sanitize(input);
      expect(result, contains('[REDACTED]'));
      expect(result, isNot(contains('AAAABBBBCCCCDDDDEEEEFFFFGGGG')));
    });

    test('redacts tokens in quoted strings', () {
      final input = 'token="XXXX_YYYY_ZZZZ_1111_2222_3333"';
      final result = LoggerService.sanitize(input);
      expect(result, contains('[REDACTED]'));
    });

    test('preserves short strings (less than 20 chars)', () {
      final input = 'key=short_value';
      final result = LoggerService.sanitize(input);
      expect(result, equals('key=short_value'));
    });

    test('preserves normal log messages without tokens', () {
      final input = '[2026-02-15] INFO Plugin started';
      final result = LoggerService.sanitize(input);
      expect(result, equals(input));
    });

    test('redacts multiple tokens in same line', () {
      final input =
          'api_key=AAAABBBBCCCCDDDDEEEEFFFFGGGG secret=HHHH1111JJJJ2222KKKK3333LLLL';
      final result = LoggerService.sanitize(input);
      expect(result, isNot(contains('AAAABBBBCCCCDDDDEEEEFFFFGGGG')));
      expect(result, isNot(contains('HHHH1111JJJJ2222KKKK3333LLLL')));
    });

    test('keeps first 4 chars of redacted token for debugging', () {
      final input = 'key=QQQQRRRRSSSSTTTTUUUUVVVVWWWW';
      final result = LoggerService.sanitize(input);
      expect(result, contains('QQQQ...[REDACTED]'));
    });
  });
}
