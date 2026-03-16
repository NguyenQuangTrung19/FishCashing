/// Data Access Object for Trade Orders and Order Items.
library;

import 'package:drift/drift.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/tables/tables.dart';

part 'trade_order_dao.g.dart';

/// Trade Order with its partner name and items
class TradeOrderWithDetails {
  final TradeOrder order;
  final String? partnerName;
  final List<OrderItemWithProduct> items;

  TradeOrderWithDetails({
    required this.order,
    this.partnerName,
    this.items = const [],
  });
}

/// Order item with product info
class OrderItemWithProduct {
  final OrderItem item;
  final String productName;
  final String productUnit;

  OrderItemWithProduct({
    required this.item,
    required this.productName,
    required this.productUnit,
  });
}

@DriftAccessor(tables: [TradeOrders, OrderItems, Products, Partners, TradingSessions])
class TradeOrderDao extends DatabaseAccessor<AppDatabase>
    with _$TradeOrderDaoMixin {
  TradeOrderDao(super.db);

  /// Insert a trade order with its items in a transaction
  Future<void> insertOrderWithItems(
    TradeOrdersCompanion order,
    List<OrderItemsCompanion> items,
  ) async {
    await transaction(() async {
      await into(tradeOrders).insert(order);
      for (final item in items) {
        await into(orderItems).insert(item);
      }
    });
  }

  /// Update a trade order: delete old items and insert new ones
  Future<void> updateOrderWithItems(
    TradeOrdersCompanion order,
    List<OrderItemsCompanion> newItems,
  ) async {
    await transaction(() async {
      // Delete old items
      await (delete(orderItems)
            ..where((i) => i.orderId.equals(order.id.value)))
          .go();
      // Update order
      await (update(tradeOrders)
            ..where((o) => o.id.equals(order.id.value)))
          .write(order);
      // Insert new items
      for (final item in newItems) {
        await into(orderItems).insert(item);
      }
    });
  }

  /// Delete a trade order and its items
  Future<void> deleteOrder(String orderId) async {
    await transaction(() async {
      await (delete(orderItems)..where((i) => i.orderId.equals(orderId))).go();
      await (delete(tradeOrders)..where((o) => o.id.equals(orderId))).go();
    });
  }

  /// Get all orders for a session with partner name
  Future<List<TradeOrderWithDetails>> getOrdersBySession(
      String sessionId) async {
    final query = select(tradeOrders).join([
      leftOuterJoin(partners, partners.id.equalsExp(tradeOrders.partnerId)),
    ])
      ..where(tradeOrders.sessionId.equals(sessionId))
      ..orderBy([OrderingTerm.desc(tradeOrders.createdAt)]);

    final rows = await query.get();
    final result = <TradeOrderWithDetails>[];

    for (final row in rows) {
      final order = row.readTable(tradeOrders);
      final partner = row.readTableOrNull(partners);
      final items = await _getOrderItems(order.id);

      result.add(TradeOrderWithDetails(
        order: order,
        partnerName: partner?.name,
        items: items,
      ));
    }
    return result;
  }

  /// Get a single order with details
  Future<TradeOrderWithDetails?> getOrderWithDetails(String orderId) async {
    final query = select(tradeOrders).join([
      leftOuterJoin(partners, partners.id.equalsExp(tradeOrders.partnerId)),
    ])
      ..where(tradeOrders.id.equals(orderId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final order = row.readTable(tradeOrders);
    final partner = row.readTableOrNull(partners);
    final items = await _getOrderItems(orderId);

    return TradeOrderWithDetails(
      order: order,
      partnerName: partner?.name,
      items: items,
    );
  }

  /// Get order items with product info
  Future<List<OrderItemWithProduct>> _getOrderItems(String orderId) async {
    final query = select(orderItems).join([
      innerJoin(products, products.id.equalsExp(orderItems.productId)),
    ])
      ..where(orderItems.orderId.equals(orderId));

    final rows = await query.get();
    return rows.map((row) {
      final item = row.readTable(orderItems);
      final product = row.readTable(products);
      return OrderItemWithProduct(
        item: item,
        productName: product.name,
        productUnit: product.unit,
      );
    }).toList();
  }

  /// Get recent POS orders (no session)
  Future<List<TradeOrderWithDetails>> getRecentPosOrders({int limit = 8}) async {
    final query = select(tradeOrders)
      ..where((o) => o.orderType.equals('pos'))
      ..orderBy([(o) => OrderingTerm.desc(o.createdAt)])
      ..limit(limit);

    final orders = await query.get();
    final result = <TradeOrderWithDetails>[];

    for (final order in orders) {
      final items = await _getOrderItems(order.id);
      result.add(TradeOrderWithDetails(order: order, items: items));
    }
    return result;
  }

  /// Get recent orders of all types
  Future<List<TradeOrderWithDetails>> getRecentOrders({int limit = 8}) async {
    final query = select(tradeOrders).join([
      leftOuterJoin(partners, partners.id.equalsExp(tradeOrders.partnerId)),
    ])
      ..orderBy([OrderingTerm.desc(tradeOrders.createdAt)])
      ..limit(limit);

    final rows = await query.get();
    final result = <TradeOrderWithDetails>[];

    for (final row in rows) {
      final order = row.readTable(tradeOrders);
      final partner = row.readTableOrNull(partners);
      final items = await _getOrderItems(order.id);
      result.add(TradeOrderWithDetails(
        order: order,
        partnerName: partner?.name,
        items: items,
      ));
    }
    return result;
  }

  /// Get orders within a date range, optionally filtered by type
  Future<List<TradeOrderWithDetails>> getOrdersByDateRange(
    DateTime from,
    DateTime to, {
    String? orderType,
    int? limit,
  }) async {
    final query = select(tradeOrders).join([
      leftOuterJoin(partners, partners.id.equalsExp(tradeOrders.partnerId)),
    ])
      ..where(tradeOrders.createdAt.isBiggerOrEqualValue(from) &
          tradeOrders.createdAt.isSmallerOrEqualValue(to))
      ..orderBy([OrderingTerm.desc(tradeOrders.createdAt)]);

    if (orderType != null) {
      query.where(tradeOrders.orderType.equals(orderType));
    }
    if (limit != null) {
      query.limit(limit);
    }

    final rows = await query.get();
    final result = <TradeOrderWithDetails>[];

    for (final row in rows) {
      final order = row.readTable(tradeOrders);
      final partner = row.readTableOrNull(partners);
      final items = await _getOrderItems(order.id);
      result.add(TradeOrderWithDetails(
        order: order,
        partnerName: partner?.name,
        items: items,
      ));
    }
    return result;
  }

  /// Get all orders (for year picker / stats)
  Future<List<TradeOrder>> getAllOrders() async {
    return (select(tradeOrders)
          ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
        .get();
  }
}
