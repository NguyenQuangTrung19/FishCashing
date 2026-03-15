/// Weighted Average Price calculator for merging same products.
///
/// When the same product is added multiple times (potentially with
/// different units and prices), the system automatically:
/// 1. Converts all to base unit
/// 2. Accumulates quantity
/// 3. Calculates weighted average price
library;

import 'package:decimal/decimal.dart';

class PriceCalculator {
  PriceCalculator._();

  /// Calculate weighted average price when merging two entries.
  ///
  /// Formula: (oldQty × oldPrice + newQty × newPrice) / (oldQty + newQty)
  ///
  /// All quantities and prices must be in the same unit.
  static Decimal weightedAveragePrice({
    required Decimal oldQuantity,
    required Decimal oldPrice,
    required Decimal newQuantity,
    required Decimal newPrice,
  }) {
    final totalValue = (oldQuantity * oldPrice) + (newQuantity * newPrice);
    final totalQuantity = oldQuantity + newQuantity;

    if (totalQuantity == Decimal.zero) return Decimal.zero;

    return (totalValue / totalQuantity).toDecimal(
      scaleOnInfinitePrecision: 2,
    );
  }

  /// Calculate line total for an order item.
  /// line_total = quantity × unit_price
  static Decimal lineTotal(Decimal quantity, Decimal unitPrice) {
    return quantity * unitPrice;
  }

  /// Calculate order subtotal = sum of all line totals
  static Decimal orderSubtotal(List<Decimal> lineTotals) {
    return lineTotals.fold(Decimal.zero, (sum, item) => sum + item);
  }

  /// Calculate session profit = total sell - total buy
  static Decimal sessionProfit(Decimal totalSell, Decimal totalBuy) {
    return totalSell - totalBuy;
  }
}
