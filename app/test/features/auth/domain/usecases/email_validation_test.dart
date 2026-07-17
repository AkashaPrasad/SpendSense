import 'package:flutter_test/flutter_test.dart';
import 'package:spendsense/features/auth/domain/usecases/email_validation.dart';

void main() {
  group('validateEmailPassword', () {
    test('rejects an empty email', () {
      expect(validateEmailPassword(email: '', password: 'abcdef'), isNotNull);
    });

    test('rejects a malformed email', () {
      expect(
        validateEmailPassword(email: 'not-an-email', password: 'abcdef'),
        isNotNull,
      );
    });

    test('rejects an empty password', () {
      expect(validateEmailPassword(email: 'a@b.com', password: ''), isNotNull);
    });

    test('rejects a password shorter than 6 characters', () {
      expect(
        validateEmailPassword(email: 'a@b.com', password: '12345'),
        isNotNull,
      );
    });

    test('accepts a valid email and password', () {
      expect(
        validateEmailPassword(email: 'user@example.com', password: 'secret1'),
        isNull,
      );
    });

    test('trims whitespace before validating the email', () {
      expect(
        validateEmailPassword(
          email: '  user@example.com  ',
          password: 'secret1',
        ),
        isNull,
      );
    });
  });
}
