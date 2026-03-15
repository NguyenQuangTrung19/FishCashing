// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_dao.dart';

// ignore_for_file: type=lint
mixin _$PartnerDaoMixin on DatabaseAccessor<AppDatabase> {
  $PartnersTable get partners => attachedDatabase.partners;
  PartnerDaoManager get managers => PartnerDaoManager(this);
}

class PartnerDaoManager {
  final _$PartnerDaoMixin _db;
  PartnerDaoManager(this._db);
  $$PartnersTableTableManager get partners =>
      $$PartnersTableTableManager(_db.attachedDatabase, _db.partners);
}
