/// Utility for converting between measurement units.
///
/// All conversions go through the base unit (kg) as intermediary
/// to ensure accuracy in all cases.
library;

import 'package:decimal/decimal.dart';
import 'package:fishcash_pos/core/constants/app_constants.dart';

class UnitConverter {
  UnitConverter._();

  /// Check if a unit can be converted (has a kg conversion factor)
  static bool isConvertible(String unit) {
    return UnitConstants.conversionToKg.containsKey(unit);
  }

  /// Get conversion factor from [unit] to kg.
  /// Returns null if unit is not convertible.
  static Decimal? getFactorToKg(String unit) {
    final factor = UnitConstants.conversionToKg[unit];
    if (factor == null) return null;
    return Decimal.parse(factor.toString());
  }

  /// Convert quantity from [fromUnit] to [toUnit].
  /// Returns null if either unit is not convertible.
  ///
  /// Example: convertQuantity(4.2, 'tấn', 'kg') => 4200
  static Decimal? convertQuantity(
    Decimal quantity,
    String fromUnit,
    String toUnit,
  ) {
    if (fromUnit == toUnit) return quantity;

    final fromFactor = getFactorToKg(fromUnit);
    final toFactor = getFactorToKg(toUnit);

    if (fromFactor == null || toFactor == null) return null;

    // Convert: fromUnit → kg → toUnit
    // quantity_kg = quantity * fromFactor
    // quantity_to = quantity_kg / toFactor
    final quantityInKg = quantity * fromFactor;
    return (quantityInKg / toFactor).toDecimal();
  }

  /// Convert unit price from [fromUnit] to [toUnit].
  /// Price conversion is inverse of quantity conversion.
  ///
  /// Example: convertPrice(100000000, 'tấn', 'kg') => 100000
  static Decimal? convertPrice(
    Decimal price,
    String fromUnit,
    String toUnit,
  ) {
    if (fromUnit == toUnit) return price;

    final fromFactor = getFactorToKg(fromUnit);
    final toFactor = getFactorToKg(toUnit);

    if (fromFactor == null || toFactor == null) return null;

    // Price conversion is inverse: price_to = price * toFactor / fromFactor
    return (price * toFactor / fromFactor).toDecimal();
  }

  /// Convert quantity to base unit (kg)
  static Decimal? toBaseUnit(Decimal quantity, String fromUnit) {
    return convertQuantity(quantity, fromUnit, UnitConstants.kg);
  }

  /// Convert price to base unit price (per kg)
  static Decimal? toBaseUnitPrice(Decimal price, String fromUnit) {
    return convertPrice(price, fromUnit, UnitConstants.kg);
  }
}
