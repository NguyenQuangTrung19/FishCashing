/// Repository for inventory (stock) management.
///
/// Computes inventory from existing OrderItems + TradeOrders data.
/// Supports time-range filtering and stock adjustments (reset/disposal).
library;

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:uuid/uuid.dart';

// === MODELS ===

/// Stock info for a single product
class InventoryItem {
  final String productId;
  final String productName;
  final String unit;
  final String categoryId;
  final bool isActive;
  final Decimal buyQuantity; // total bought (in product unit, e.g. kg)
  final Decimal sellQuantity; // total sold (in product unit)
  final Decimal adjustmentQuantity; // net adjustments (negative = removed)
  final Decimal stockQuantity; // buy - sell + adjustments

  InventoryItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.categoryId,
    required this.isActive,
    required this.buyQuantity,
    required this.sellQuantity,
    required this.adjustmentQuantity,
    required this.stockQuantity,
  });

  /// Stock status for display
  StockStatus get status {
    if (stockQuantity < Decimal.zero) return StockStatus.negative;
    if (stockQuantity == Decimal.zero) return StockStatus.empty;
    if (buyQuantity > Decimal.zero &&
        stockQuantity <= buyQuantity * Decimal.parse('0.2')) {
      return StockStatus.low;
    }
    return StockStatus.sufficient;
  }
}

enum StockStatus { sufficient, low, empty, negative }

/// Stock balance for a product within a session
class SessionBalanceItem {
  final String productId;
  final String productName;
  final String unit;
  final Decimal buyQuantity;
  final Decimal sellQuantity;
  final Decimal balance; // buy - sell (positive = surplus, negative = deficit)

  SessionBalanceItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.buyQuantity,
    required this.sellQuantity,
    required this.balance,
  });
}

/// Time period filter options
enum InventoryPeriod {
  all, // Tất cả
  thisMonth, // Tháng này
  lastMonth, // Tháng trước
  thisYear, // Năm nay
}

// === REPOSITORY ===

class InventoryRepository {
  final TradeOrderDao _dao;
  static const _uuid = Uuid();

  InventoryRepository(this._dao);

  /// Convert grams to display unit (kg by default)
  Decimal _gramsToUnit(int grams) {
    // quantityInGrams is actually quantity * 1000
    // So 1 kg = 1000 grams stored
    return (Decimal.fromInt(grams) / Decimal.fromInt(1000))
        .toDecimal(scaleOnInfinitePrecision: 3);
  }

  /// Get date range for period
  ({DateTime? from, DateTime? to}) _getDateRange(InventoryPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case InventoryPeriod.all:
        return (from: null, to: null);
      case InventoryPeriod.thisMonth:
        return (
          from: DateTime(now.year, now.month, 1),
          to: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case InventoryPeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return (
          from: lastMonth,
          to: DateTime(now.year, now.month, 0, 23, 59, 59),
        );
      case InventoryPeriod.thisYear:
        return (
          from: DateTime(now.year, 1, 1),
          to: DateTime(now.year, 12, 31, 23, 59, 59),
        );
    }
  }

  /// Get inventory summary for all products (with optional period)
  Future<List<InventoryItem>> getInventorySummary({
    InventoryPeriod period = InventoryPeriod.all,
  }) async {
    final range = _getDateRange(period);
    final rows = await _dao.getStockByProduct(from: range.from, to: range.to);

    return rows.map((row) {
      final buyQty = _gramsToUnit(row['buyGrams'] as int);
      final sellQty = _gramsToUnit(row['sellGrams'] as int);
      final adjQty = _gramsToUnit(row['adjGrams'] as int);

      return InventoryItem(
        productId: row['productId'] as String,
        productName: row['productName'] as String,
        unit: row['productUnit'] as String,
        categoryId: row['categoryId'] as String,
        isActive: row['isActive'] as bool,
        buyQuantity: buyQty,
        sellQuantity: sellQty,
        adjustmentQuantity: adjQty,
        stockQuantity: buyQty - sellQty + adjQty,
      );
    }).toList();
  }

  /// Get stock balance for a specific session
  Future<List<SessionBalanceItem>> getSessionBalance(String sessionId) async {
    final rows = await _dao.getSessionStockBalance(sessionId);

    return rows.map((row) {
      final buyQty = _gramsToUnit(row['buyGrams'] as int);
      final sellQty = _gramsToUnit(row['sellGrams'] as int);

      return SessionBalanceItem(
        productId: row['productId'] as String,
        productName: row['productName'] as String,
        unit: row['productUnit'] as String,
        buyQuantity: buyQty,
        sellQuantity: sellQty,
        balance: buyQty - sellQty,
      );
    }).toList();
  }

  /// Reset stock for a product — creates a negative adjustment to zero out balance
  Future<void> resetProductStock({
    required String productId,
    required int currentStockInGrams,
    String reason = 'Làm mới kho',
  }) async {
    if (currentStockInGrams == 0) return;

    await _dao.insertAdjustment(
      InventoryAdjustmentsCompanion.insert(
        id: _uuid.v4(),
        productId: productId,
        quantityInGrams: -currentStockInGrams, // negate to zero out
        reason: Value(reason),
      ),
    );
  }

  /// Add custom stock adjustment (e.g. partial disposal)
  Future<void> addAdjustment({
    required String productId,
    required int quantityInGrams,
    String reason = '',
  }) async {
    await _dao.insertAdjustment(
      InventoryAdjustmentsCompanion.insert(
        id: _uuid.v4(),
        productId: productId,
        quantityInGrams: quantityInGrams,
        reason: Value(reason),
      ),
    );
  }
}
