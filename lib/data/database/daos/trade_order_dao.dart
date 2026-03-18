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

@DriftAccessor(tables: [TradeOrders, OrderItems, Products, Partners, TradingSessions, InventoryAdjustments, Payments])
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

  /// Get stock per product with optional date range filter.
  /// Includes adjustments in the calculation.
  Future<List<Map<String, dynamic>>> getStockByProduct({
    DateTime? from,
    DateTime? to,
  }) async {
    final dateFilter = _buildDateFilter(from, to, 'o.created_at');
    final adjDateFilter = _buildDateFilter(from, to, 'ia.created_at');

    final result = await customSelect(
      '''
      SELECT
        p.id AS product_id,
        p.name AS product_name,
        p.unit AS product_unit,
        p.category_id AS category_id,
        p.is_active AS is_active,
        COALESCE(buy_sell.buy_grams, 0) AS buy_grams,
        COALESCE(buy_sell.sell_grams, 0) AS sell_grams,
        COALESCE(adj.adj_grams, 0) AS adj_grams
      FROM products p
      LEFT JOIN (
        SELECT
          oi.product_id,
          SUM(CASE WHEN o.order_type = 'buy' THEN oi.quantity_in_grams ELSE 0 END) AS buy_grams,
          SUM(CASE WHEN o.order_type IN ('sell', 'pos') THEN oi.quantity_in_grams ELSE 0 END) AS sell_grams
        FROM order_items oi
        JOIN trade_orders o ON o.id = oi.order_id
        $dateFilter
        GROUP BY oi.product_id
      ) buy_sell ON buy_sell.product_id = p.id
      LEFT JOIN (
        SELECT
          ia.product_id,
          SUM(ia.quantity_in_grams) AS adj_grams
        FROM inventory_adjustments ia
        $adjDateFilter
        GROUP BY ia.product_id
      ) adj ON adj.product_id = p.id
      ORDER BY p.name ASC
      ''',
      readsFrom: {products, orderItems, tradeOrders, inventoryAdjustments},
    ).get();

    return result
        .map((row) => {
              'productId': row.read<String>('product_id'),
              'productName': row.read<String>('product_name'),
              'productUnit': row.read<String>('product_unit'),
              'categoryId': row.read<String>('category_id'),
              'isActive': row.read<bool>('is_active'),
              'buyGrams': row.read<int>('buy_grams'),
              'sellGrams': row.read<int>('sell_grams'),
              'adjGrams': row.read<int>('adj_grams'),
            })
        .toList();
  }

  String _buildDateFilter(DateTime? from, DateTime? to, String column) {
    if (from != null && to != null) {
      final fromMs = from.millisecondsSinceEpoch ~/ 1000;
      final toMs = to.millisecondsSinceEpoch ~/ 1000;
      return 'WHERE $column >= $fromMs AND $column <= $toMs';
    }
    return '';
  }

  /// Get stock balance per product within a specific session
  Future<List<Map<String, dynamic>>> getSessionStockBalance(
      String sessionId) async {
    final result = await customSelect(
      '''
      SELECT
        p.id AS product_id,
        p.name AS product_name,
        p.unit AS product_unit,
        COALESCE(SUM(CASE WHEN o.order_type = 'buy' THEN oi.quantity_in_grams ELSE 0 END), 0) AS buy_grams,
        COALESCE(SUM(CASE WHEN o.order_type = 'sell' THEN oi.quantity_in_grams ELSE 0 END), 0) AS sell_grams
      FROM order_items oi
      JOIN trade_orders o ON o.id = oi.order_id
      JOIN products p ON p.id = oi.product_id
      WHERE o.session_id = ?
      GROUP BY p.id
      ORDER BY p.name ASC
      ''',
      variables: [Variable.withString(sessionId)],
      readsFrom: {products, orderItems, tradeOrders},
    ).get();

    return result
        .map((row) => {
              'productId': row.read<String>('product_id'),
              'productName': row.read<String>('product_name'),
              'productUnit': row.read<String>('product_unit'),
              'buyGrams': row.read<int>('buy_grams'),
              'sellGrams': row.read<int>('sell_grams'),
            })
        .toList();
  }

  /// Insert inventory adjustment (stock reset/disposal)
  Future<void> insertAdjustment(InventoryAdjustmentsCompanion adj) async {
    await into(inventoryAdjustments).insert(adj);
  }

  /// Get adjustments for a product
  Future<List<InventoryAdjustment>> getAdjustmentsForProduct(
      String productId) async {
    return (select(inventoryAdjustments)
          ..where((a) => a.productId.equals(productId))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();
  }

  // ===========================================
  // DEBT / PAYMENTS
  // ===========================================

  /// Get debt summary per partner:
  /// SUM(order subtotals) - SUM(payments) grouped by partnerId
  Future<List<Map<String, dynamic>>> getDebtByPartner(String debtType) async {
    // debtType: 'receivable' (sell orders, khách nợ mình)
    //           'payable' (buy orders, mình nợ NCC)
    final orderType = debtType == 'receivable' ? 'sell' : 'buy';

    final result = await customSelect(
      '''
      SELECT
        p.id AS partner_id,
        p.name AS partner_name,
        p.phone AS partner_phone,
        p.type AS partner_type,
        COALESCE(SUM(o.subtotal_in_cents), 0) AS total_order_cents,
        COALESCE(SUM(pay.total_paid), 0) AS total_paid_cents
      FROM trade_orders o
      JOIN partners p ON p.id = o.partner_id
      LEFT JOIN (
        SELECT
          py.order_id,
          SUM(py.amount_in_cents) AS total_paid
        FROM payments py
        GROUP BY py.order_id
      ) pay ON pay.order_id = o.id
      WHERE o.order_type = ? AND o.partner_id IS NOT NULL
      GROUP BY p.id
      HAVING (COALESCE(SUM(o.subtotal_in_cents), 0) - COALESCE(SUM(pay.total_paid), 0)) != 0
         OR COALESCE(SUM(o.subtotal_in_cents), 0) > 0
      ORDER BY p.name ASC
      ''',
      variables: [Variable.withString(orderType)],
      readsFrom: {tradeOrders, partners, payments},
    ).get();

    return result
        .map((row) => {
              'partnerId': row.read<String>('partner_id'),
              'partnerName': row.read<String>('partner_name'),
              'partnerPhone': row.read<String>('partner_phone'),
              'partnerType': row.read<String>('partner_type'),
              'totalOrderCents': row.read<int>('total_order_cents'),
              'totalPaidCents': row.read<int>('total_paid_cents'),
            })
        .toList();
  }

  /// Get orders for a specific partner with payment info
  Future<List<Map<String, dynamic>>> getPartnerOrdersWithPayments(
      String partnerId) async {
    final result = await customSelect(
      '''
      SELECT
        o.id AS order_id,
        o.order_type,
        o.subtotal_in_cents,
        o.note AS order_note,
        o.created_at AS order_date,
        o.session_id,
        COALESCE(pay.total_paid, 0) AS total_paid_cents,
        pay.last_payment_date
      FROM trade_orders o
      LEFT JOIN (
        SELECT
          py.order_id,
          SUM(py.amount_in_cents) AS total_paid,
          MAX(py.created_at) AS last_payment_date
        FROM payments py
        GROUP BY py.order_id
      ) pay ON pay.order_id = o.id
      WHERE o.partner_id = ?
      ORDER BY o.created_at DESC
      ''',
      variables: [Variable.withString(partnerId)],
      readsFrom: {tradeOrders, payments},
    ).get();

    return result
        .map((row) => {
              'orderId': row.read<String>('order_id'),
              'orderType': row.read<String>('order_type'),
              'subtotalCents': row.read<int>('subtotal_in_cents'),
              'orderNote': row.read<String>('order_note'),
              'orderDate': row.read<DateTime>('order_date'),
              'sessionId': row.readNullable<String>('session_id'),
              'totalPaidCents': row.read<int>('total_paid_cents'),
              'lastPaymentDate': row.readNullable<DateTime>('last_payment_date'),
            })
        .toList();
  }

  /// Insert a payment
  Future<void> insertPayment(PaymentsCompanion payment) async {
    await into(payments).insert(payment);
  }

  /// Get payments for an order
  Future<List<Payment>> getPaymentsForOrder(String orderId) async {
    return (select(payments)
          ..where((p) => p.orderId.equals(orderId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  /// Delete a single payment by ID
  Future<void> deletePayment(String paymentId) async {
    await (delete(payments)..where((p) => p.id.equals(paymentId))).go();
  }

  /// Delete all payments for an order
  Future<void> deletePaymentsForOrder(String orderId) async {
    await (delete(payments)..where((p) => p.orderId.equals(orderId))).go();
  }
}
