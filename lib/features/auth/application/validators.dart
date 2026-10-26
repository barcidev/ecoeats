import 'dart:convert';

/// Why a field is rejected. Screens turn each reason into a translated
/// message, so validators never carry text.
enum FieldIssue { required, invalid, tooLong, tooShort, tooManyBytes, mismatch }

/// The rules the API enforces on each field, checked before sending so a
/// request the server would answer with 400 never leaves the device.
abstract final class Validators {
  static const maxEmailLength = 150;
  static const maxNameLength = 100;
  static const maxDocumentLength = 30;
  static const minPasswordLength = 6;

  /// bcrypt only reads the first 72 bytes, so the API rejects anything longer.
  static const maxPasswordBytes = 72;
  static const codeLength = 6;

  // Stricter than the server's check, which accepts a domain without a dot;
  // no customer address looks like that.
  static final _email = RegExp(r'^[^\s@]+@[^\s@.]+(\.[^\s@.]+)+$');
  static final _code = RegExp('^[0-9]{$codeLength}\$');

  static FieldIssue? email(String value) {
    final email = value.trim();
    if (email.isEmpty) return .required;
    if (email.length > maxEmailLength) return .tooLong;
    if (!_email.hasMatch(email)) return .invalid;
    return null;
  }

  /// The address as the API stores it.
  static String normalizeEmail(String value) => value.trim().toLowerCase();

  /// First names and last names share their rules.
  static FieldIssue? names(String value) =>
      _requiredText(value, maxLength: maxNameLength);

  static FieldIssue? document(String value) =>
      _requiredText(value, maxLength: maxDocumentLength);

  /// Only presence: an account created under older rules must still sign in.
  static FieldIssue? loginPassword(String value) =>
      value.trim().isEmpty ? .required : null;

  static FieldIssue? newPassword(String value) {
    if (value.trim().isEmpty) return .required;
    final checklist = PasswordChecklist.of(value);
    if (!checklist.hasMinLength) return .tooShort;
    if (!checklist.fitsInBytes) return .tooManyBytes;
    return null;
  }

  static FieldIssue? confirmation(String password, String confirmation) {
    if (confirmation.isEmpty) return .required;
    return confirmation == password ? null : .mismatch;
  }

  static FieldIssue? code(String value) {
    if (value.isEmpty) return .required;
    return _code.hasMatch(value) ? null : .invalid;
  }

  static FieldIssue? _requiredText(String value, {required int maxLength}) {
    final text = value.trim();
    if (text.isEmpty) return .required;
    return text.length > maxLength ? .tooLong : null;
  }
}

/// The live checklist under a new password, where each rule passes on its
/// own while the user types.
final class PasswordChecklist {
  factory of(String password) => PasswordChecklist._(
    length: password.length,
    bytes: utf8.encode(password).length,
  );

  const new _({required this.length, required this.bytes});

  /// UTF-16 code units, the same count the API's `@Size` uses.
  final int length;
  final int bytes;

  bool get hasMinLength => length >= Validators.minPasswordLength;
  bool get fitsInBytes => bytes <= Validators.maxPasswordBytes;
  bool get passes => hasMinLength && fitsInBytes;
}
