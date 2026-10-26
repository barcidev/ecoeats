import 'package:ecoeats/features/auth/application/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('is required', () {
      expect(Validators.email(''), FieldIssue.required);
      expect(Validators.email('   '), FieldIssue.required);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('jorge'), FieldIssue.invalid);
      expect(Validators.email('jorge@'), FieldIssue.invalid);
      expect(Validators.email('@gmail.com'), FieldIssue.invalid);
      expect(Validators.email('jorge@gmail'), FieldIssue.invalid);
      expect(Validators.email('jorge@gmail..com'), FieldIssue.invalid);
      expect(Validators.email('jor ge@gmail.com'), FieldIssue.invalid);
      expect(Validators.email('jorge@@gmail.com'), FieldIssue.invalid);
    });

    test('accepts well formed addresses, ignoring surrounding spaces', () {
      expect(Validators.email('jorge@gmail.com'), isNull);
      expect(Validators.email('jorge.palacio+eco@mail.co'), isNull);
      expect(Validators.email('  Jorge@Gmail.com '), isNull);
    });

    test('allows at most 150 characters', () {
      final atLimit = '${'a' * 140}@gmail.com';
      expect(atLimit.length, 150);
      expect(Validators.email(atLimit), isNull);
      expect(Validators.email('a$atLimit'), FieldIssue.tooLong);
    });

    test('normalizes to the trimmed lowercase address', () {
      expect(
        Validators.normalizeEmail('  Jorge@Gmail.COM '),
        'jorge@gmail.com',
      );
    });
  });

  group('names', () {
    test('are required', () {
      expect(Validators.names(''), FieldIssue.required);
      expect(Validators.names('  '), FieldIssue.required);
    });

    test('allow at most 100 characters, trimmed', () {
      expect(Validators.names('a' * 100), isNull);
      expect(Validators.names(' ${'a' * 100} '), isNull);
      expect(Validators.names('a' * 101), FieldIssue.tooLong);
    });

    test('accept accents and compound names', () {
      expect(Validators.names('José Ángel'), isNull);
      expect(Validators.names('Núñez de Balboa'), isNull);
    });
  });

  group('document', () {
    test('is required', () {
      expect(Validators.document(''), FieldIssue.required);
      expect(Validators.document(' '), FieldIssue.required);
    });

    test('allows at most 30 characters, trimmed', () {
      expect(Validators.document('1032456789'), isNull);
      expect(Validators.document('1' * 30), isNull);
      expect(Validators.document(' ${'1' * 30} '), isNull);
      expect(Validators.document('1' * 31), FieldIssue.tooLong);
    });
  });

  group('login password', () {
    test('is only required', () {
      expect(Validators.loginPassword(''), FieldIssue.required);
      expect(Validators.loginPassword('   '), FieldIssue.required);
      expect(Validators.loginPassword('a'), isNull);
    });
  });

  group('new password', () {
    test('is required', () {
      expect(Validators.newPassword(''), FieldIssue.required);
      expect(Validators.newPassword('      '), FieldIssue.required);
    });

    test('needs at least 6 characters', () {
      expect(Validators.newPassword('12345'), FieldIssue.tooShort);
      expect(Validators.newPassword('123456'), isNull);
    });

    test('keeps spaces as part of the password', () {
      expect(Validators.newPassword(' 1234'), FieldIssue.tooShort);
      expect(Validators.newPassword(' 12345'), isNull);
    });

    test('fits in 72 bytes of UTF-8, not 72 characters', () {
      expect(Validators.newPassword('a' * 72), isNull);
      expect(Validators.newPassword('a' * 73), FieldIssue.tooManyBytes);
      // «ñ» takes two bytes: 36 of them fill the limit, 40 exceed it.
      expect(Validators.newPassword('ñ' * 36), isNull);
      expect(Validators.newPassword('ñ' * 40), FieldIssue.tooManyBytes);
      // Each emoji takes four bytes: 30 of them are 120 bytes.
      expect(Validators.newPassword('😀' * 30), FieldIssue.tooManyBytes);
    });
  });

  group('password checklist', () {
    test('starts with the length rule failing and the byte rule passing', () {
      final checklist = PasswordChecklist.of('');
      expect(checklist.hasMinLength, isFalse);
      expect(checklist.fitsInBytes, isTrue);
      expect(checklist.bytes, 0);
      expect(checklist.passes, isFalse);
    });

    test('reports each rule on its own', () {
      final long = PasswordChecklist.of('ñ' * 40);
      expect(long.hasMinLength, isTrue);
      expect(long.fitsInBytes, isFalse);
      expect(long.bytes, 80);
      expect(long.passes, isFalse);

      final good = PasswordChecklist.of('Ejemplo123!');
      expect(good.hasMinLength, isTrue);
      expect(good.fitsInBytes, isTrue);
      expect(good.bytes, 11);
      expect(good.passes, isTrue);
    });

    test('agrees with the new password validator', () {
      for (final password in ['', '12345', '123456', 'a' * 73, 'ñ' * 36]) {
        expect(
          PasswordChecklist.of(password).passes,
          Validators.newPassword(password) == null,
          reason: password,
        );
      }
    });
  });

  group('confirmation', () {
    test('is required', () {
      expect(Validators.confirmation('Ejemplo123!', ''), FieldIssue.required);
    });

    test('must match the password exactly', () {
      expect(
        Validators.confirmation('Ejemplo123!', 'ejemplo123!'),
        FieldIssue.mismatch,
      );
      expect(
        Validators.confirmation('Ejemplo123!', 'Ejemplo123! '),
        FieldIssue.mismatch,
      );
      expect(Validators.confirmation('Ejemplo123!', 'Ejemplo123!'), isNull);
    });
  });

  group('code', () {
    test('is required', () {
      expect(Validators.code(''), FieldIssue.required);
    });

    test('is exactly six ASCII digits', () {
      expect(Validators.code('123456'), isNull);
      expect(Validators.code('012345'), isNull);
      expect(Validators.code('12345'), FieldIssue.invalid);
      expect(Validators.code('1234567'), FieldIssue.invalid);
      expect(Validators.code('12a456'), FieldIssue.invalid);
      expect(Validators.code('123 456'), FieldIssue.invalid);
      // Arabic-Indic digits are digits, but the API only takes ASCII ones.
      expect(Validators.code('١٢٣٤٥٦'), FieldIssue.invalid);
    });
  });
}
