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

    test('Accepts sequences and any non-empty number', () {
      expect(PhoneValidator.isValidSouthAfricanMobile('123456789'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('9876543210'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('+919876543210'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('+12025550123'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('0111234567'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('08212345'), isTrue);
      expect(PhoneValidator.isValidSouthAfricanMobile('082123456789'), isTrue);
    });

    test('Empty numbers rejected when required, accepted when optional', () {
      expect(PhoneValidator.isValidSouthAfricanMobile('', isRequired: true), isFalse);
      expect(PhoneValidator.isValidSouthAfricanMobile('   ', isRequired: true), isFalse);
      expect(PhoneValidator.isValidSouthAfricanMobile(null, isRequired: true), isFalse);

      expect(PhoneValidator.validateSouthAfricanMobile('', isRequired: true), isNotNull);
      expect(PhoneValidator.validateSouthAfricanMobile('   ', isRequired: true), isNotNull);
      expect(PhoneValidator.validateSouthAfricanMobile(null, isRequired: true), isNotNull);

      expect(PhoneValidator.validateSouthAfricanMobile('', isRequired: false), isNull);
      expect(PhoneValidator.validateSouthAfricanMobile('   ', isRequired: false), isNull);
      expect(PhoneValidator.validateSouthAfricanMobile(null, isRequired: false), isNull);
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
