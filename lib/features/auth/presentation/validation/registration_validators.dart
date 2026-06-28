/// Pure validation helpers for the registration form.
class RegistrationValidators {
  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9_-]{3,30}$');
  static final DateTime _minimumBirthDate = DateTime(1900);

  const RegistrationValidators._();

  /// Returns the backend-compatible username representation.
  static String normalizeUsername(String value) => value.trim().toLowerCase();

  /// True when [value] matches the backend username contract.
  static bool isValidUsername(String value) {
    return _usernamePattern.hasMatch(normalizeUsername(value));
  }

  /// Parses a strict `YYYY-MM-DD` birth date string.
  static DateTime? parseBirthDate(String value) {
    final trimmed = value.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime(year, month, day);

    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }

    return parsed;
  }

  /// True when [value] is between 1900-01-01 and 13 years before [now].
  static bool isAllowedBirthDate(DateTime value, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final date = _dateOnly(value);
    final thirteenYearsAgo = DateTime(today.year - 13, today.month, today.day);

    return !date.isBefore(_minimumBirthDate) && !date.isAfter(thirteenYearsAgo);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
