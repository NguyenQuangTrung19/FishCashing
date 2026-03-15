/// Cart item model for POS and Trading order creation.
///
/// Represents a product in the cart with quantity, unit, and price.
/// Supports weighted average merging and unit conversion.
library;

import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:fishcash_pos/core/utils/price_calculator.dart';
import 'package:fishcash_pos/core/utils/unit_converter.dart';
import 'package:fishcash_pos/domain/models/product_model.dart';

/// A single item in the cart
class CartItem extends Equatable {
  final String productId;
  final String productName;
  final String categoryName;
  final Decimal quantity; // in current display unit
  final String unit; // current display unit
  final Decimal unitPrice; // price per current display unit
  final String baseUnit; // product's default unit
  final Decimal baseQuantity; // quantity in base unit
  final Decimal baseUnitPrice; // price per base unit

  const CartItem({
    required this.productId,
    required this.productName,
    this.categoryName = '',
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.baseUnit,
    required this.baseQuantity,
    required this.baseUnitPrice,
  });

  /// Create a cart item from a product with specified quantity and price
  factory CartItem.fromProduct({
    required ProductModel product,
    required Decimal quantity,
    required String unit,
    required Decimal unitPrice,
  }) {
    // Convert to base unit
    final baseQty = UnitConverter.convertQuantity(quantity, unit, product.unit);
    final basePrice = UnitConverter.convertPrice(unitPrice, unit, product.unit);

    return CartItem(
      productId: product.id,
      productName: product.name,
      categoryName: product.categoryName,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      baseUnit: product.unit,
      baseQuantity: baseQty ?? quantity,
      baseUnitPrice: basePrice ?? unitPrice,
    );
  }

  /// Line total = quantity × unitPrice
  Decimal get lineTotal => PriceCalculator.lineTotal(quantity, unitPrice);

  /// Merge with another cart item (same product) using weighted average
  CartItem mergeWith(CartItem other) {
    assert(productId == other.productId);

    // Merge in base unit
    final newBasePrice = PriceCalculator.weightedAveragePrice(
      oldQuantity: baseQuantity,
      oldPrice: baseUnitPrice,
      newQuantity: other.baseQuantity,
      newPrice: other.baseUnitPrice,
    );
    final newBaseQty = baseQuantity + other.baseQuantity;

    // Convert back to display unit
    final displayQty =
        UnitConverter.convertQuantity(newBaseQty, baseUnit, unit) ?? newBaseQty;
    final displayPrice =
        UnitConverter.convertPrice(newBasePrice, baseUnit, unit) ?? newBasePrice;

    return CartItem(
      productId: productId,
      productName: productName,
      categoryName: categoryName,
      quantity: displayQty,
      unit: unit,
      unitPrice: displayPrice,
      baseUnit: baseUnit,
      baseQuantity: newBaseQty,
      baseUnitPrice: newBasePrice,
    );
  }

  /// Convert display to a different unit
  CartItem convertTo(String newUnit) {
    if (newUnit == unit) return this;

    final newQty =
        UnitConverter.convertQuantity(baseQuantity, baseUnit, newUnit) ??
            baseQuantity;
    final newPrice =
        UnitConverter.convertPrice(baseUnitPrice, baseUnit, newUnit) ??
            baseUnitPrice;

    return CartItem(
      productId: productId,
      productName: productName,
      categoryName: categoryName,
      quantity: newQty,
      unit: newUnit,
      unitPrice: newPrice,
      baseUnit: baseUnit,
      baseQuantity: baseQuantity,
      baseUnitPrice: baseUnitPrice,
    );
  }

  /// Create a copy with updated quantity (keeps same unit and price)
  CartItem withQuantity(Decimal newQuantity) {
    final newBaseQty =
        UnitConverter.convertQuantity(newQuantity, unit, baseUnit) ??
            newQuantity;
    return CartItem(
      productId: productId,
      productName: productName,
      categoryName: categoryName,
      quantity: newQuantity,
      unit: unit,
      unitPrice: unitPrice,
      baseUnit: baseUnit,
      baseQuantity: newBaseQty,
      baseUnitPrice: baseUnitPrice,
    );
  }

  @override
  List<Object?> get props => [productId, quantity, unit, unitPrice];
}

/// The entire cart state
class Cart extends Equatable {
  final List<CartItem> items;
  final String displayUnit; // Current display unit for conversions

  const Cart({
    this.items = const [],
    this.displayUnit = 'kg',
  });

  /// Total price of all items
  Decimal get total {
    return items.fold(Decimal.zero, (sum, item) => sum + item.lineTotal);
  }

  /// Number of items
  int get itemCount => items.length;

  /// Is cart empty
  bool get isEmpty => items.isEmpty;

  /// Add item to cart (merges if same product exists)
  Cart addItem(CartItem newItem) {
    final existingIndex =
        items.indexWhere((i) => i.productId == newItem.productId);

    if (existingIndex >= 0) {
      // Merge with existing item
      final updated = List<CartItem>.from(items);
      updated[existingIndex] = updated[existingIndex].mergeWith(newItem);
      return Cart(items: updated, displayUnit: displayUnit);
    } else {
      return Cart(
        items: [...items, newItem],
        displayUnit: displayUnit,
      );
    }
  }

  /// Remove item at index
  Cart removeAt(int index) {
    final updated = List<CartItem>.from(items)..removeAt(index);
    return Cart(items: updated, displayUnit: displayUnit);
  }

  /// Remove item by product ID
  Cart removeByProductId(String productId) {
    final updated = items.where((i) => i.productId != productId).toList();
    return Cart(items: updated, displayUnit: displayUnit);
  }

  /// Update item quantity at index
  Cart updateQuantityAt(int index, Decimal newQuantity) {
    final updated = List<CartItem>.from(items);
    updated[index] = updated[index].withQuantity(newQuantity);
    return Cart(items: updated, displayUnit: displayUnit);
  }

  /// Convert all items to a different display unit
  Cart convertAllTo(String newUnit) {
    return Cart(
      items: items.map((i) => i.convertTo(newUnit)).toList(),
      displayUnit: newUnit,
    );
  }

  /// Clear the cart
  Cart clear() => const Cart();

  @override
  List<Object?> get props => [items, displayUnit];
}
