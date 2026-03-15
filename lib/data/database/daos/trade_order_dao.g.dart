// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_order_dao.dart';

// ignore_for_file: type=lint
mixin _$TradeOrderDaoMixin on DatabaseAccessor<AppDatabase> {
  $TradeOrdersTable get tradeOrders => attachedDatabase.tradeOrders;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $OrderItemsTable get orderItems => attachedDatabase.orderItems;
  $PartnersTable get partners => attachedDatabase.partners;
  $TradingSessionsTable get tradingSessions => attachedDatabase.tradingSessions;
  TradeOrderDaoManager get managers => TradeOrderDaoManager(this);
}

class TradeOrderDaoManager {
  final _$TradeOrderDaoMixin _db;
  TradeOrderDaoManager(this._db);
  $$TradeOrdersTableTableManager get tradeOrders =>
      $$TradeOrdersTableTableManager(_db.attachedDatabase, _db.tradeOrders);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db.attachedDatabase, _db.orderItems);
  $$PartnersTableTableManager get partners =>
      $$PartnersTableTableManager(_db.attachedDatabase, _db.partners);
  $$TradingSessionsTableTableManager get tradingSessions =>
      $$TradingSessionsTableTableManager(
        _db.attachedDatabase,
        _db.tradingSessions,
      );
}
