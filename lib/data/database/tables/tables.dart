/// Drift table definitions for all FishCash POS entities.
///
/// Tables follow the ERD specification with proper types:
/// - NUMERIC(15,2) for currency → stored as INTEGER (cents) in SQLite
/// - NUMERIC(12,3) for quantity → stored as INTEGER (milligrams) in SQLite
/// - UUID → stored as TEXT in SQLite
library;

import 'package:drift/drift.dart';

/// Categories table — Product classification groups
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Products table — Items for trading
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  IntColumn get priceInCents => integer()(); // price × 100
  TextColumn get unit => text().withDefault(const Constant('kg'))();
  TextColumn get imagePath => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Partners table — Suppliers and Buyers
class Partners extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get type => text()(); // 'supplier' or 'buyer'
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Trading Sessions table — Wholesale trading batches
class TradingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get totalBuyInCents => integer().withDefault(const Constant(0))();
  IntColumn get totalSellInCents => integer().withDefault(const Constant(0))();
  IntColumn get profitInCents => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Trade Orders table — Individual buy/sell orders
class TradeOrders extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().nullable()(); // null = POS order
  TextColumn get partnerId => text().nullable()(); // null = walk-in customer
  TextColumn get orderType => text()(); // 'buy', 'sell', 'pos'
  IntColumn get subtotalInCents => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Order Items table — Line items within an order
class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(TradeOrders, #id)();
  TextColumn get productId => text().references(Products, #id)();
  IntColumn get quantityInGrams => integer()(); // quantity × 1000 (3 decimal places)
  TextColumn get unit => text()(); // unit at time of transaction
  IntColumn get unitPriceInCents => integer()(); // price × 100
  IntColumn get lineTotalInCents => integer()(); // quantity × unit_price
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Transactions table — Financial records
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().nullable()();
  TextColumn get type => text()(); // 'income' or 'expense'
  IntColumn get amountInCents => integer()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('cash'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Store Info table — Shop information for invoices
class StoreInfos extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get logoPath => text().withDefault(const Constant(''))();
  TextColumn get qrImagePath => text().withDefault(const Constant(''))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Inventory Adjustments table — Stock corrections (reset, disposal, personal use)
class InventoryAdjustments extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  IntColumn get quantityInGrams => integer()(); // negative = removed from stock
  TextColumn get reason => text().withDefault(const Constant(''))(); // e.g. 'Thanh lý', 'Hao hụt', 'Làm mới kho'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Payments table — Partial/full payments against orders
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(TradeOrders, #id)();
  IntColumn get amountInCents => integer()(); // payment amount × 100
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
