/// Data Access Object for Store Info.
library;

import 'package:drift/drift.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/tables/tables.dart';

part 'store_info_dao.g.dart';

@DriftAccessor(tables: [StoreInfos])
class StoreInfoDao extends DatabaseAccessor<AppDatabase>
    with _$StoreInfoDaoMixin {
  StoreInfoDao(super.db);

  /// Get the single store info record (first row)
  Future<StoreInfo?> getStoreInfo() {
    return (select(storeInfos)..limit(1)).getSingleOrNull();
  }

  /// Watch store info reactively
  Stream<StoreInfo?> watchStoreInfo() {
    return (select(storeInfos)..limit(1)).watchSingleOrNull();
  }

  /// Insert or update store info (upsert)
  Future<void> upsertStoreInfo(StoreInfosCompanion entry) {
    return into(storeInfos).insertOnConflictUpdate(entry);
  }
}
