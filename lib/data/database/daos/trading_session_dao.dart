/// Data Access Object for Trading Sessions.
library;

import 'package:drift/drift.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/tables/tables.dart';

part 'trading_session_dao.g.dart';

@DriftAccessor(tables: [TradingSessions, TradeOrders])
class TradingSessionDao extends DatabaseAccessor<AppDatabase>
    with _$TradingSessionDaoMixin {
  TradingSessionDao(super.db);

  /// Get all sessions ordered by creation date (newest first)
  Future<List<TradingSession>> getAll() {
    return (select(tradingSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .get();
  }

  /// Watch all sessions
  Stream<List<TradingSession>> watchAll() {
    return (select(tradingSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .watch();
  }

  /// Get session by ID
  Future<TradingSession?> getById(String id) {
    return (select(tradingSessions)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new session
  Future<void> insertSession(TradingSessionsCompanion entry) {
    return into(tradingSessions).insert(entry);
  }

  /// Update session note
  Future<void> updateSession(TradingSessionsCompanion entry) {
    return (update(tradingSessions)..where((s) => s.id.equals(entry.id.value)))
        .write(entry);
  }

  /// Recalculate session totals from its orders
  Future<void> recalculateTotals(String sessionId) async {
    // Sum buy orders
    final buyQuery = selectOnly(tradeOrders)
      ..addColumns([tradeOrders.subtotalInCents.sum()])
      ..where(tradeOrders.sessionId.equals(sessionId) &
          tradeOrders.orderType.equals('buy'));
    final buyResult = await buyQuery.getSingle();
    final totalBuy = buyResult.read(tradeOrders.subtotalInCents.sum()) ?? 0;

    // Sum sell orders
    final sellQuery = selectOnly(tradeOrders)
      ..addColumns([tradeOrders.subtotalInCents.sum()])
      ..where(tradeOrders.sessionId.equals(sessionId) &
          tradeOrders.orderType.equals('sell'));
    final sellResult = await sellQuery.getSingle();
    final totalSell = sellResult.read(tradeOrders.subtotalInCents.sum()) ?? 0;

    await (update(tradingSessions)..where((s) => s.id.equals(sessionId)))
        .write(TradingSessionsCompanion(
      totalBuyInCents: Value(totalBuy),
      totalSellInCents: Value(totalSell),
      profitInCents: Value(totalSell - totalBuy),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Delete session and all its orders + items
  Future<void> deleteSession(String sessionId) async {
    await transaction(() async {
      // Get all order IDs for this session
      final orders = await (select(tradeOrders)
            ..where((o) => o.sessionId.equals(sessionId)))
          .get();

      // Delete items for each order
      for (final order in orders) {
        await (delete(db.orderItems)
              ..where((i) => i.orderId.equals(order.id)))
            .go();
      }

      // Delete all orders
      await (delete(tradeOrders)
            ..where((o) => o.sessionId.equals(sessionId)))
          .go();

      // Delete session
      await (delete(tradingSessions)
            ..where((s) => s.id.equals(sessionId)))
          .go();
    });
  }

  /// Get order count for a session
  Future<int> getOrderCount(String sessionId) async {
    final query = selectOnly(tradeOrders)
      ..addColumns([tradeOrders.id.count()])
      ..where(tradeOrders.sessionId.equals(sessionId));
    final result = await query.getSingle();
    return result.read(tradeOrders.id.count()) ?? 0;
  }
}
