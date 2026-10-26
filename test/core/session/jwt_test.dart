import 'dart:convert';

import 'package:ecoeats/core/session/jwt.dart';
import 'package:ecoeats/core/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

String _jwt(Map<String, Object?> payload) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(payload)}.signature';
}

void main() {
  group('decodeJwt', () {
    test('reads sub, email, role and exp', () {
      final claims = decodeJwt(
        _jwt({
          'sub': 'u1',
          'email': 'jorge@example.com',
          'role': 'USER',
          'exp': 1793000000,
        }),
      );
      expect(claims, (
        subject: 'u1',
        email: 'jorge@example.com',
        role: 'USER',
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          1793000000 * 1000,
          isUtc: true,
        ),
      ));
    });

    test('a token without sub or exp is not a session', () {
      expect(decodeJwt(_jwt({'email': 'jorge@example.com'})), isNull);
    });

    test('malformed tokens decode to nothing', () {
      expect(decodeJwt(''), isNull);
      expect(decodeJwt('only.two'), isNull);
      expect(decodeJwt('a.%%%.c'), isNull);
      expect(decodeJwt('a.${base64Url.encode(utf8.encode('nope'))}.c'), isNull);
    });
  });

  group('Session', () {
    final session = Session(
      token: 't',
      userId: 'u1',
      email: 'jorge@example.com',
      expiresAt: DateTime.utc(2026, 10, 25, 12),
    );

    test('expires at its exp', () {
      expect(session.isExpiredAt(DateTime.utc(2026, 10, 25, 11, 59)), isFalse);
      expect(session.isExpiredAt(DateTime.utc(2026, 10, 25, 12)), isTrue);
    });

    test('remaining time never goes below zero', () {
      expect(
        session.remainingAt(DateTime.utc(2026, 10, 24, 13)),
        const Duration(hours: 23),
      );
      expect(session.remainingAt(DateTime.utc(2026, 10, 26)), Duration.zero);
    });
  });
}
