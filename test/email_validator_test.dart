import 'package:flutter_test/flutter_test.dart';
import 'package:uts_mobile/core/utils/email_validator.dart';

void main() {
  group('isValidEmail', () {
    test('accepts common valid emails', () {
      expect(isValidEmail('user@mail.com'), isTrue);
      expect(isValidEmail('user.name+tag@mail.co.id'), isTrue);
      expect(isValidEmail('USER@Mail.COM'), isTrue);
    });

    test('rejects clearly invalid emails', () {
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('user@mail'), isFalse);
      expect(isValidEmail('@mail.com'), isFalse);
      expect(isValidEmail('user@@mail.com'), isFalse);
      expect(isValidEmail('user.mail.com'), isFalse);
    });
  });
}
