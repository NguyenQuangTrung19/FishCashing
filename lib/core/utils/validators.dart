/// Shared input validators for forms.
library;

/// Common validators for form fields.
class AppValidators {
  AppValidators._();

  /// Returns true if [value] starts with a symbol (not letter or digit).
  static bool startsWithSymbol(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    // Allow letters (any language) and digits at the start
    return !RegExp(r'^[\p{L}\d]', unicode: true).hasMatch(trimmed);
  }

  /// Validate a name field (not empty, not starting with symbol).
  static String? validateName(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldLabel';
    }
    if (startsWithSymbol(value)) {
      return 'Tên không được bắt đầu bằng ký hiệu';
    }
    return null;
  }
}
