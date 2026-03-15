/// TextInputFormatter for Vietnamese currency (VNĐ).
///
/// Automatically adds thousand separators using dots.
/// Preserves cursor position when editing in the middle.
/// Example: 100000 → 100.000, 1500000 → 1.500.000
library;

import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    final newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Count how many digits are BEFORE the cursor in the new value
    final cursorPos = newValue.selection.baseOffset;
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorPos && i < newValue.text.length; i++) {
      if (RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    // Format with dots as thousand separators
    final formatted = _formatWithDots(newDigits);

    // Calculate new cursor position: count digits in formatted string
    // until we've passed digitsBeforeCursor digits
    int newCursorPos = 0;
    int digitsSeen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (digitsSeen == digitsBeforeCursor) break;
      newCursorPos = i + 1;
      if (formatted[i] != '.') {
        digitsSeen++;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursorPos.clamp(0, formatted.length),
      ),
    );
  }

  /// Format a numeric string with dot separators.
  /// "1500000" → "1.500.000"
  static String _formatWithDots(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Parse a formatted string back to raw number string.
  /// "1.500.000" → "1500000"
  static String parseToRaw(String formatted) {
    return formatted.replaceAll('.', '');
  }

  /// Format a number value for display in input fields.
  /// 1500000 → "1.500.000"
  static String format(num value) {
    final digits = value.toInt().toString();
    return _formatWithDots(digits);
  }
}
