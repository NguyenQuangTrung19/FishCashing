// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $PartnersTable get partners => attachedDatabase.partners;
  $TradingSessionsTable get tradingSessions => attachedDatabase.tradingSessions;
  $TradeOrdersTable get tradeOrders => attachedDatabase.tradeOrders;
  $OrderItemsTable get orderItems => attachedDatabase.orderItems;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $StoreInfosTable get storeInfos => attachedDatabase.storeInfos;
  $InventoryAdjustmentsTable get inventoryAdjustments =>
      attachedDatabase.inventoryAdjustments;
  $PaymentsTable get payments => attachedDatabase.payments;
  SyncDaoManager get managers => SyncDaoManager(this);
}

class SyncDaoManager {
  final _$SyncDaoMixin _db;
  SyncDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$PartnersTableTableManager get partners =>
      $$PartnersTableTableManager(_db.attachedDatabase, _db.partners);
  $$TradingSessionsTableTableManager get tradingSessions =>
      $$TradingSessionsTableTableManager(
        _db.attachedDatabase,
        _db.tradingSessions,
      );
  $$TradeOrdersTableTableManager get tradeOrders =>
      $$TradeOrdersTableTableManager(_db.attachedDatabase, _db.tradeOrders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db.attachedDatabase, _db.orderItems);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
  $$StoreInfosTableTableManager get storeInfos =>
      $$StoreInfosTableTableManager(_db.attachedDatabase, _db.storeInfos);
  $$InventoryAdjustmentsTableTableManager get inventoryAdjustments =>
      $$InventoryAdjustmentsTableTableManager(
        _db.attachedDatabase,
        _db.inventoryAdjustments,
      );
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
}
