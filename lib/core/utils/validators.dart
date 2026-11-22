/// Field checks used by presentation code before a use case runs.
abstract final class Validators {
  static String? email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Enter an email';
    }
    final at = trimmed.indexOf('@');
    if (at <= 0 || !trimmed.substring(at).contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) {
      return 'Enter a password';
    }
    if (value.length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }
}
