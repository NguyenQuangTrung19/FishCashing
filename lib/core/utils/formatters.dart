/// Formatting utilities for currency, quantity, and chart labels.
library;

import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static final _quantityFormat = NumberFormat('#,##0.###', 'vi_VN');

  /// Format currency value: 1500000 => "1.500.000đ"
  static String currency(Decimal value) {
    return _currencyFormat.format(value.toDouble());
  }

  /// Format currency from double (for chart/display only)
  static String currencyFromDouble(double value) {
    return _currencyFormat.format(value);
  }

  /// Format quantity: 4200.5 => "4.200,5"
  static String quantity(Decimal value) {
    return _quantityFormat.format(value.toDouble());
  }

  /// Format quantity with unit: "4.200,5 kg"
  static String quantityWithUnit(Decimal value, String unit) {
    return '${quantity(value)} $unit';
  }

  /// Smart chart label formatting:
  /// >= 1,000,000,000 => "Xtỷ"
  /// >= 1,000,000     => "Xtr"
  /// >= 1,000         => "Xk"
  static String chartLabel(double value) {
    final absValue = value.abs();
    final sign = value < 0 ? '-' : '';

    if (absValue >= 1000000000) {
      final v = absValue / 1000000000;
      return '$sign${_formatCompact(v)}tỷ';
    } else if (absValue >= 1000000) {
      final v = absValue / 1000000;
      return '$sign${_formatCompact(v)}tr';
    } else if (absValue >= 1000) {
      final v = absValue / 1000;
      return '$sign${_formatCompact(v)}k';
    } else {
      return '$sign${absValue.toStringAsFixed(0)}';
    }
  }

  static String _formatCompact(double v) {
    if (v == v.roundToDouble()) {
      return v.toStringAsFixed(0);
    }
    return v.toStringAsFixed(1);
  }

  /// Format date: "15/03/2026"
  static String date(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  /// Format date time: "15/03/2026 14:30"
  static String dateTime(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  /// Format relative date for chart labels
  static String chartDateLabel(DateTime dt, {String mode = '7d'}) {
    switch (mode) {
      case '7d':
        return DateFormat('dd/MM').format(dt);
      case '12m':
        return DateFormat('MM/yyyy').format(dt);
      case '5y':
        return DateFormat('yyyy').format(dt);
      default:
        return DateFormat('dd/MM').format(dt);
    }
  }
}
