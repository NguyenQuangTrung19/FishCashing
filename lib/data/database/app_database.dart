/// Drift database definition for FishCash POS.
///
/// Uses SQLite for local-first storage.
/// All monetary values stored as cents (integer) to avoid float precision issues.
/// All quantities stored as milligrams (integer) for weight, or direct count for pieces.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:fishcash_pos/data/database/tables/tables.dart';
import 'package:fishcash_pos/data/database/daos/category_dao.dart';
import 'package:fishcash_pos/data/database/daos/product_dao.dart';
import 'package:fishcash_pos/data/database/daos/partner_dao.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/database/daos/trading_session_dao.dart';
import 'package:fishcash_pos/data/database/daos/store_info_dao.dart';
import 'package:fishcash_pos/data/database/daos/sync_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
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
  ],
  daos: [CategoryDao, ProductDao, PartnerDao, TradeOrderDao, TradingSessionDao, StoreInfoDao, SyncDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // For testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(inventoryAdjustments);
        }
        if (from < 3) {
          await m.createTable(payments);
        }
        if (from < 4) {
          // Add synced_at column to all syncable tables
          final tables = [
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
          for (final table in tables) {
            await customStatement(
              'ALTER TABLE $table ADD COLUMN synced_at INTEGER NULL',
            );
          }
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fishcash_pos.db'));
    return NativeDatabase.createInBackground(file);
  });
}
