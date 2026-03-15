/// Repository for Partner operations.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/daos/partner_dao.dart';
import 'package:fishcash_pos/domain/models/partner_model.dart';

class PartnerRepository {
  final PartnerDao _dao;
  static const _uuid = Uuid();

  PartnerRepository(this._dao);

  PartnerModel _toModel(Partner entity) {
    return PartnerModel(
      id: entity.id,
      name: entity.name,
      type: entity.type == 'supplier' ? PartnerType.supplier : PartnerType.buyer,
      phone: entity.phone,
      address: entity.address,
      note: entity.note,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Future<List<PartnerModel>> getAll() async {
    final entities = await _dao.getAll();
    return entities.map(_toModel).toList();
  }

  Future<List<PartnerModel>> getByType(PartnerType type) async {
    final typeStr = type == PartnerType.supplier ? 'supplier' : 'buyer';
    final entities = await _dao.getByType(typeStr);
    return entities.map(_toModel).toList();
  }

  Stream<List<PartnerModel>> watchAll() {
    return _dao.watchAll().map((list) => list.map(_toModel).toList());
  }

  Stream<List<PartnerModel>> watchByType(PartnerType type) {
    final typeStr = type == PartnerType.supplier ? 'supplier' : 'buyer';
    return _dao.watchByType(typeStr).map((list) => list.map(_toModel).toList());
  }

  Future<PartnerModel> create({
    required String name,
    required PartnerType type,
    String phone = '',
    String address = '',
    String note = '',
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final typeStr = type == PartnerType.supplier ? 'supplier' : 'buyer';

    final companion = PartnersCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(typeStr),
      phone: Value(phone),
      address: Value(address),
      note: Value(note),
      isActive: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await _dao.insertPartner(companion);

    return PartnerModel(
      id: id,
      name: name,
      type: type,
      phone: phone,
      address: address,
      note: note,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> update({
    required String id,
    required String name,
    String? phone,
    String? address,
    String? note,
  }) async {
    final companion = PartnersCompanion(
      id: Value(id),
      name: Value(name),
      phone: phone != null ? Value(phone) : const Value.absent(),
      address: address != null ? Value(address) : const Value.absent(),
      note: note != null ? Value(note) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    await _dao.updatePartner(companion);
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _dao.toggleActive(id, isActive);
  }

  Future<void> delete(String id) async {
    await _dao.deletePartner(id);
  }
}
