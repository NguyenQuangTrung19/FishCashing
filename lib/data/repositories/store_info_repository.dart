/// Repository for Store Info operations.
library;

import 'package:drift/drift.dart';

import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/daos/store_info_dao.dart';

class StoreInfoRepository {
  final StoreInfoDao _dao;

  /// Default store ID — only one store info record
  static const _defaultId = 'default-store-info';

  StoreInfoRepository(this._dao);

  /// Get current store info
  Future<StoreInfo?> getStoreInfo() => _dao.getStoreInfo();

  /// Watch store info reactively
  Stream<StoreInfo?> watchStoreInfo() => _dao.watchStoreInfo();

  /// Save (insert or update) store info
  Future<void> saveStoreInfo({
    required String name,
    String address = '',
    String phone = '',
    String logoPath = '',
    String qrImagePath = '',
  }) async {
    // Check if a record already exists
    final existing = await _dao.getStoreInfo();
    final id = existing?.id ?? _defaultId;

    final companion = StoreInfosCompanion(
      id: Value(id),
      name: Value(name),
      address: Value(address),
      phone: Value(phone),
      logoPath: Value(logoPath),
      qrImagePath: Value(qrImagePath),
    );

    await _dao.upsertStoreInfo(companion);
  }
}
