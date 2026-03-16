// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_info_dao.dart';

// ignore_for_file: type=lint
mixin _$StoreInfoDaoMixin on DatabaseAccessor<AppDatabase> {
  $StoreInfosTable get storeInfos => attachedDatabase.storeInfos;
  StoreInfoDaoManager get managers => StoreInfoDaoManager(this);
}

class StoreInfoDaoManager {
  final _$StoreInfoDaoMixin _db;
  StoreInfoDaoManager(this._db);
  $$StoreInfosTableTableManager get storeInfos =>
      $$StoreInfosTableTableManager(_db.attachedDatabase, _db.storeInfos);
}
