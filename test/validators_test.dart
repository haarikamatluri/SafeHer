import 'package:flutter_test/flutter_test.dart';
import 'package:safeher/utils/validators.dart';

void main() {
  group('AppValidators Tests', () {
    test('validateName accepts valid names and rejects invalid names', () {
      expect(AppValidators.validateName('A'), isNotNull);
      expect(AppValidators.validateName(''), isNotNull);
      expect(AppValidators.validateName('   '), isNotNull);
      expect(AppValidators.validateName('Sarah Connor'), isNull);
      expect(AppValidators.validateName('Priya'), isNull);
    });

    test(
      'validatePhone validates valid formats and rejects malformed numbers',
      () {
        expect(AppValidators.validatePhone('+919876543210'), isNull);
        expect(AppValidators.validatePhone('+1 800 555 0199'), isNull);
        expect(AppValidators.validatePhone('9876543210'), isNull);
        expect(AppValidators.validatePhone('123'), isNotNull);
        expect(AppValidators.validatePhone('abcdefgh'), isNotNull);
        expect(AppValidators.validatePhone(''), isNotNull);
      },
    );

    test('validateEmail allows empty/null (optional) and checks format', () {
      expect(AppValidators.validateEmail(null), isNull);
      expect(AppValidators.validateEmail(''), isNull);
      expect(AppValidators.validateEmail('user@example.com'), isNull);
      expect(AppValidators.validateEmail('invalid-email'), isNotNull);
      expect(AppValidators.validateEmail('test@test'), isNotNull);
    });

    test('normalizePhone strips whitespace, dashes, and plus signs', () {
      expect(AppValidators.normalizePhone('+91 98765-43210'), '919876543210');
      expect(AppValidators.normalizePhone('(555) 123-4567'), '5551234567');
    });

    test('validateCheckinMinutes enforces boundary conditions', () {
      expect(AppValidators.validateCheckinMinutes(0), isNotNull);
      expect(AppValidators.validateCheckinMinutes(-5), isNotNull);
      expect(AppValidators.validateCheckinMinutes(15), isNull);
      expect(AppValidators.validateCheckinMinutes(1440), isNull);
      expect(AppValidators.validateCheckinMinutes(1500), isNotNull);
    });
  });
}
