import 'dart:convert';

typedef JwtClaims = ({
  String subject,
  String email,
  String role,
  DateTime expiresAt,
});

/// Reads the payload of the API's HS256 token. The signature is not checked:
/// only the server holds the key, and it rejects a forged token anyway.
JwtClaims? decodeJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  final Object? payload;
  try {
    payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
  } on FormatException {
    return null;
  }
  if (payload case {'sub': final String subject, 'exp': final int exp}) {
    return (
      subject: subject,
      email: payload['email'] as String? ?? '',
      role: payload['role'] as String? ?? '',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true),
    );
  }
  return null;
}
