/// Shared input validators.
///
/// `_emailRe` requires a local part, an `@`, a domain, and a dot-separated TLD
/// — so values like `a@a` (which PayMongo rejects as
/// "billing.email format is invalid") are caught before they reach checkout.
final RegExp _emailRe = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

/// True when [v] looks like a valid email address.
bool isValidEmail(String v) => _emailRe.hasMatch(v.trim());

/// `TextFormField.validator` for a required email field: returns `null` when
/// valid, otherwise a short, user-facing message.
String? emailFieldValidator(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Required';
  return isValidEmail(s) ? null : 'Enter a valid email (e.g. you@example.com)';
}

/// Firebase requires passwords of at least 6 characters. Catch it client-side
/// with a clear message instead of a round-trip + `weak-password` error.
String? passwordFieldValidator(String? v) {
  final s = v ?? '';
  if (s.isEmpty) return 'Required';
  return s.length >= 6 ? null : 'At least 6 characters';
}
