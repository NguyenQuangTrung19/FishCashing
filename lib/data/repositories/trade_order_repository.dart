/// Repository for Trade Order operations.
library;

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/database/daos/trading_session_dao.dart';
import 'package:fishcash_pos/core/utils/unit_converter.dart';
import 'package:fishcash_pos/domain/models/cart_model.dart';

class TradeOrderRepository {
  final TradeOrderDao _orderDao;
  final TradingSessionDao _sessionDao;
  static const _uuid = Uuid();

  TradeOrderRepository(this._orderDao, this._sessionDao);

  /// Convert cents (integer) back to Decimal currency value
  static Decimal _centsToDecimal(int cents) {
    return (Decimal.fromInt(cents) / Decimal.fromInt(100)).toDecimal();
  }

  /// Convert Decimal currency value to cents (integer)
  static int _decimalToCents(Decimal value) {
    return (value * Decimal.fromInt(100)).toBigInt().toInt();
  }

  /// Convert grams (integer) to Decimal quantity
  static Decimal _gramsToDecimal(int grams) {
    return (Decimal.fromInt(grams) / Decimal.fromInt(1000)).toDecimal(
      scaleOnInfinitePrecision: 3,
    );
  }

  /// Convert Decimal quantity to grams (integer)
  static int _decimalToGrams(Decimal value) {
    return (value * Decimal.fromInt(1000)).toBigInt().toInt();
  }

  /// Create a POS order (no session, no partner)
  Future<String> createPosOrder({
    required Cart cart,
    String paymentMethod = 'cash',
  }) async {
    final orderId = _uuid.v4();
    final subtotal = _decimalToCents(cart.total);

    final orderCompanion = TradeOrdersCompanion(
      id: Value(orderId),
      sessionId: const Value.absent(),
      partnerId: const Value.absent(),
      orderType: const Value('pos'),
      subtotalInCents: Value(subtotal),
      note: Value('POS - $paymentMethod'),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    final itemCompanions = cart.items.map((item) {
      return OrderItemsCompanion(
        id: Value(_uuid.v4()),
        orderId: Value(orderId),
        productId: Value(item.productId),
        quantityInGrams: Value(_decimalToGrams(item.baseQuantity)),
        unit: Value(item.unit),
        unitPriceInCents: Value(_decimalToCents(item.unitPrice)),
        lineTotalInCents: Value(_decimalToCents(item.lineTotal)),
      );
    }).toList();

    await _orderDao.insertOrderWithItems(orderCompanion, itemCompanions);
    return orderId;
  }

  /// Create a trade order (buy or sell) within a session
  Future<String> createTradeOrder({
    required String sessionId,
    required String? partnerId,
    required String orderType, // 'buy' or 'sell'
    required Cart cart,
    String note = '',
  }) async {
    final orderId = _uuid.v4();
    final subtotal = _decimalToCents(cart.total);

    final orderCompanion = TradeOrdersCompanion(
      id: Value(orderId),
      sessionId: Value(sessionId),
      partnerId: partnerId != null ? Value(partnerId) : const Value.absent(),
      orderType: Value(orderType),
      subtotalInCents: Value(subtotal),
      note: Value(note),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    final itemCompanions = cart.items.map((item) {
      return OrderItemsCompanion(
        id: Value(_uuid.v4()),
        orderId: Value(orderId),
        productId: Value(item.productId),
        quantityInGrams: Value(_decimalToGrams(item.baseQuantity)),
        unit: Value(item.unit),
        unitPriceInCents: Value(_decimalToCents(item.unitPrice)),
        lineTotalInCents: Value(_decimalToCents(item.lineTotal)),
      );
    }).toList();

    await _orderDao.insertOrderWithItems(orderCompanion, itemCompanions);

    // Recalculate session totals
    await _sessionDao.recalculateTotals(sessionId);

    return orderId;
  }

  /// Update a trade order with new cart items
  Future<void> updateTradeOrder({
    required String orderId,
    required Cart cart,
    String? sessionId,
    String note = '',
  }) async {
    final subtotal = _decimalToCents(cart.total);

    final orderCompanion = TradeOrdersCompanion(
      id: Value(orderId),
      subtotalInCents: Value(subtotal),
      note: Value(note),
      updatedAt: Value(DateTime.now()),
    );

    final itemCompanions = cart.items.map((item) {
      return OrderItemsCompanion(
        id: Value(_uuid.v4()),
        orderId: Value(orderId),
        productId: Value(item.productId),
        quantityInGrams: Value(_decimalToGrams(item.baseQuantity)),
        unit: Value(item.unit),
        unitPriceInCents: Value(_decimalToCents(item.unitPrice)),
        lineTotalInCents: Value(_decimalToCents(item.lineTotal)),
      );
    }).toList();

    await _orderDao.updateOrderWithItems(orderCompanion, itemCompanions);

    if (sessionId != null) {
      await _sessionDao.recalculateTotals(sessionId);
    }
  }

  /// Delete an order
  Future<void> deleteOrder(String orderId, {String? sessionId}) async {
    await _orderDao.deleteOrder(orderId);
    if (sessionId != null) {
      await _sessionDao.recalculateTotals(sessionId);
    }
  }

  /// Get orders by session
  Future<List<TradeOrderWithDetails>> getOrdersBySession(
      String sessionId) async {
    return _orderDao.getOrdersBySession(sessionId);
  }

  /// Get recent orders
  Future<List<TradeOrderWithDetails>> getRecentOrders({int limit = 8}) async {
    return _orderDao.getRecentOrders(limit: limit);
  }

  /// Get order with details
  Future<TradeOrderWithDetails?> getOrderWithDetails(String orderId) async {
    return _orderDao.getOrderWithDetails(orderId);
  }

  /// Load cart from existing order (for editing)
  Future<Cart> loadCartFromOrder(String orderId) async {
    final orderDetails = await _orderDao.getOrderWithDetails(orderId);
    if (orderDetails == null) return const Cart();

    final items = orderDetails.items.map((oip) {
      final displayUnit = oip.item.unit; // e.g. "tấn"
      final baseUnit = oip.productUnit; // e.g. "kg"

      // quantityInGrams → base quantity in kg
      final baseQty = _gramsToDecimal(oip.item.quantityInGrams);

      // unitPriceInCents → price per DISPLAY unit
      final displayPrice = _centsToDecimal(oip.item.unitPriceInCents);

      // Convert base qty (kg) → display unit qty
      // e.g. 10000 kg → 10 tấn
      final displayQty = UnitConverter.convertQuantity(
            baseQty, baseUnit, displayUnit,
          ) ??
          baseQty;

      // Convert display price → base unit price
      // e.g. 100,000,000 đ/tấn → 100,000 đ/kg
      final basePrice = UnitConverter.convertPrice(
            displayPrice, displayUnit, baseUnit,
          ) ??
          displayPrice;

      return CartItem(
        productId: oip.item.productId,
        productName: oip.productName,
        quantity: displayQty,
        unit: displayUnit,
        unitPrice: displayPrice,
        baseUnit: baseUnit,
        baseQuantity: baseQty,
        baseUnitPrice: basePrice,
      );
    }).toList();

    return Cart(items: items);
  }
}
