/// Application-wide constants for FishCash POS
library;

/// Unit conversion factors (base unit: kg)
class UnitConstants {
  UnitConstants._();

  static const String kg = 'kg';
  static const String yen = 'yến'; // 10 kg
  static const String ta = 'tạ'; // 100 kg
  static const String ton = 'tấn'; // 1000 kg
  static const String piece = 'con';
  static const String tray = 'khay';

  /// Conversion factors to base unit (kg)
  static const Map<String, double> conversionToKg = {
    kg: 1.0,
    yen: 10.0,
    ta: 100.0,
    ton: 1000.0,
  };

  /// Units that can be converted to kg (weight-based)
  static const List<String> convertibleUnits = [kg, yen, ta, ton];

  /// All available units
  static const List<String> allUnits = [kg, yen, ta, ton, piece, tray];

  /// Get display label for unit
  static String label(String unit) {
    switch (unit) {
      case kg:
        return 'Kilogram (kg)';
      case yen:
        return 'Yến (10 kg)';
      case ta:
        return 'Tạ (100 kg)';
      case ton:
        return 'Tấn (1.000 kg)';
      case piece:
        return 'Con';
      case tray:
        return 'Khay';
      default:
        return unit;
    }
  }
}

/// Currency and number formatting
class FormatConstants {
  FormatConstants._();

  static const String currencySymbol = 'đ';
  static const String currencyLocale = 'vi_VN';
  static const int currencyDecimalDigits = 0;
  static const int quantityDecimalDigits = 3;
}

/// App metadata
class AppConstants {
  AppConstants._();

  static const String appName = 'FishCash POS';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Quản lý cửa hàng hải sản chuyên nghiệp';
}
