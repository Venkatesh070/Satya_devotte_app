import 'package:flutter_test/flutter_test.dart';
import 'package:satya_devotte_app/core/utils/phone_validator.dart';

void main() {
  group('PhoneValidator - South African Mobile Validation', () {
    test('Valid standard national format (08x, 07x, 06x)', () {
      expect(PhoneValidator.isValidSouthAfricanMobile('0821234567'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('0712345678'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('0601234567'), isTrue);
    });

    test('Valid international format (+27)', () {
      expect(PhoneValidator.isValidSouthAfricanMobile('+27821234567'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('+27712345678'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('+27601234567'), isTrue);
    });

    test('Valid formatted with spaces, dashes, parentheses', () {
      expect(PhoneValidator.isValidSouthAfricanMobile('+27 82 123 4567'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('082 123 4567'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('+27 (82) 123-4567'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('(082) 123-4567'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('082.123.4567'), isTrue);
    });

    test('Valid with accidental +27 and leading 0', () {
      expect(PhoneValidator.isValidSouthAfricanMobile('+270821234567'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('+27 082 123 4567'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('0027821234567'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('27821234567'), isTrue);
    });

    test('Valid 9-digit direct format', () {
      expect(PhoneValidator.isValidSouthAfricanMobile('821234567'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('712345678'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('601234567'), isTrue);
    });

    test('Invalid numbers rejected', () {
      // Landline or invalid prefix
      expect(PhoneValidator.isValidSouthAfricanMobile('0111234567'), isFalse);
      expect(PhoneValidator.isValidSouthAfricanMobile('0211234567'), isFalse);
      expect(PhoneValidator.isValidSouthAfricanMobile('0511234567'), isFalse);

      // Foreign numbers
      expect(PhoneValidator.isValidSouthAfricanMobile('+919876543210'), isFalse);
      expect(PhoneValidator.isValidSouthAfricanMobile('+12025550123'), isFalse);

      // Too short / too long
      expect(PhoneValidator.isValidSouthAfricanMobile('08212345'), isFalse);
      expect(PhoneValidator.isValidSouthAfricanMobile('082123456789'), isFalse);

      // Random text
      expect(PhoneValidator.isValidSouthAfricanMobile('abcdefghij'), isFalse);
    });

    test('Optional validation handling', () {
      expect(PhoneValidator.validateSouthAfricanMobile('', isRequired: false), isNull);
      expect(PhoneValidator.validateSouthAfricanMobile(null, isRequired: false), isNull);
      expect(PhoneValidator.validateSouthAfricanMobile('', isRequired: true), isNotNull);
    });

    test('Normalization', () {
      expect(PhoneValidator.normalize('082 123 4567', international: false), '0821234567');
      expect(PhoneValidator.normalize('+27 82 123 4567', international: false), '0821234567');
      expect(PhoneValidator.normalize('+27 82 123 4567', international: true), '+27821234567');
      expect(PhoneValidator.normalize('0821234567', international: true), '+27821234567');
    });

    test('Country code extraction', () {
      expect(PhoneValidator.getCountryCode('+27821234567'), '+27');
      expect(PhoneValidator.getCountryCode('0821234567'), '+27');
      expect(PhoneValidator.getCountryCode('+447911123456'), '+44');
    });
  });
}
