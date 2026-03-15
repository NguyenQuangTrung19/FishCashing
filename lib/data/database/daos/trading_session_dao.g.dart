// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trading_session_dao.dart';

// ignore_for_file: type=lint
mixin _$TradingSessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $TradingSessionsTable get tradingSessions => attachedDatabase.tradingSessions;
  $TradeOrdersTable get tradeOrders => attachedDatabase.tradeOrders;
  TradingSessionDaoManager get managers => TradingSessionDaoManager(this);
}

class TradingSessionDaoManager {
  final _$TradingSessionDaoMixin _db;
  TradingSessionDaoManager(this._db);
  $$TradingSessionsTableTableManager get tradingSessions =>
      $$TradingSessionsTableTableManager(
        _db.attachedDatabase,
        _db.tradingSessions,
      );
  $$TradeOrdersTableTableManager get tradeOrders =>
      $$TradeOrdersTableTableManager(_db.attachedDatabase, _db.tradeOrders);
}
