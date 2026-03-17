/// DAO for sync operations — query unsynced records and upsert from server.
///
/// Handles the data layer for push/pull sync with the backend.
library;

import 'package:drift/drift.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/tables/tables.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [
  Categories,
  Products,
  Partners,
  TradingSessions,
  TradeOrders,
  OrderItems,
  Transactions,
  StoreInfos,
  InventoryAdjustments,
  Payments,
])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  /// Table name → Drift table reference mapping
  static const _syncableTables = [
    'categories',
    'products',
    'partners',
    'trading_sessions',
    'trade_orders',
    'order_items',
    'transactions',
    'store_infos',
    'inventory_adjustments',
    'payments',
  ];

  /// Get all records from a table that have not been synced yet,
  /// or have been updated after the last sync.
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String tableName) async {
    final result = await customSelect(
      'SELECT * FROM $tableName WHERE synced_at IS NULL',
      readsFrom: _tableSetForName(tableName),
    ).get();
    return result.map((row) => row.data).toList();
  }

  /// Get records updated since a given timestamp (for incremental push)
  Future<List<Map<String, dynamic>>> getRecordsUpdatedSince(
    String tableName,
    DateTime since,
  ) async {

    // Tables with updatedAt
    const tablesWithUpdatedAt = [
      'categories', 'products', 'partners',
      'trading_sessions', 'trade_orders',
    ];

    if (tablesWithUpdatedAt.contains(tableName)) {
      final result = await customSelect(
        'SELECT * FROM $tableName WHERE '
        '(synced_at IS NULL OR updated_at > synced_at)',
        readsFrom: _tableSetForName(tableName),
      ).get();
      return result.map((row) => row.data).toList();
    }

    // Tables with only createdAt (append-only)
    final result = await customSelect(
      'SELECT * FROM $tableName WHERE synced_at IS NULL',
      readsFrom: _tableSetForName(tableName),
    ).get();
    return result.map((row) => row.data).toList();
  }

  /// Upsert a record from server into local database.
  /// Uses INSERT OR REPLACE for simplicity (last-write-wins).
  Future<void> upsertFromServer(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    // Build column names and placeholders
    final columns = record.keys.toList();
    final placeholders = columns.map((_) => '?').join(', ');
    final columnNames = columns.join(', ');
    final values = columns.map((col) => record[col]).toList();

    await customStatement(
      'INSERT OR REPLACE INTO $tableName ($columnNames) VALUES ($placeholders)',
      values,
    );
  }

  /// Mark records as synced (set synced_at = now)
  Future<void> markAsSynced(String tableName, List<String> ids) async {
    if (ids.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final placeholders = ids.map((_) => '?').join(', ');
    await customStatement(
      'UPDATE $tableName SET synced_at = $now WHERE id IN ($placeholders)',
      ids,
    );
  }

  /// Get all syncable table names
  List<String> get syncableTableNames => _syncableTables;

  /// Get all records from a table (for initial full sync push)
  Future<List<Map<String, dynamic>>> getAllRecords(String tableName) async {
    final result = await customSelect(
      'SELECT * FROM $tableName',
      readsFrom: _tableSetForName(tableName),
    ).get();
    return result.map((row) => row.data).toList();
  }

  /// Helper: resolve table set for customSelect readsFrom
  Set<ResultSetImplementation> _tableSetForName(String tableName) {
    switch (tableName) {
      case 'categories':
        return {categories};
      case 'products':
        return {products};
      case 'partners':
        return {partners};
      case 'trading_sessions':
        return {tradingSessions};
      case 'trade_orders':
        return {tradeOrders};
      case 'order_items':
        return {orderItems};
      case 'transactions':
        return {transactions};
      case 'store_infos':
        return {storeInfos};
      case 'inventory_adjustments':
        return {inventoryAdjustments};
      case 'payments':
        return {payments};
      default:
        return {};
    }
  }
}
