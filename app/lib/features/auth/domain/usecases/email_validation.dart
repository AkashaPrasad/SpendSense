final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Shared client-side validation for email/password use cases. Keeps the
/// same pure-Dart rules testable without touching Firebase, and gives
/// instant feedback before a network round-trip.
String? validateEmailPassword({
  required String email,
  required String password,
}) {
  final trimmedEmail = email.trim();
  if (trimmedEmail.isEmpty) {
    return 'Enter your email address.';
  }
  if (!_emailPattern.hasMatch(trimmedEmail)) {
    return 'Enter a valid email address.';
  }
  if (password.isEmpty) {
    return 'Enter your password.';
  }
  if (password.length < 6) {
    return 'Password must be at least 6 characters.';
  }
  return null;
}
