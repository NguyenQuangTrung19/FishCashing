/// Data Access Object for Partners.
library;

import 'package:drift/drift.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/tables/tables.dart';

part 'partner_dao.g.dart';

@DriftAccessor(tables: [Partners])
class PartnerDao extends DatabaseAccessor<AppDatabase>
    with _$PartnerDaoMixin {
  PartnerDao(super.db);

  /// Get all partners (including inactive), ordered by name
  Future<List<Partner>> getAll() {
    return (select(partners)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Get partners filtered by type (including inactive)
  Future<List<Partner>> getByType(String type) {
    return (select(partners)
          ..where((p) => p.type.equals(type))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Watch partners filtered by type (including inactive)
  Stream<List<Partner>> watchByType(String type) {
    return (select(partners)
          ..where((p) => p.type.equals(type))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  /// Get all active partners, ordered by name
  Future<List<Partner>> getAllActive() {
    return (select(partners)
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Get active partners filtered by type ('supplier' or 'buyer')
  Future<List<Partner>> getActiveByType(String type) {
    return (select(partners)
          ..where((p) => p.type.equals(type))
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Watch all partners
  Stream<List<Partner>> watchAll() {
    return (select(partners)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  /// Watch active partners filtered by type
  Stream<List<Partner>> watchActiveByType(String type) {
    return (select(partners)
          ..where((p) => p.type.equals(type))
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  /// Get partner by ID
  Future<Partner?> getById(String id) {
    return (select(partners)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new partner
  Future<void> insertPartner(PartnersCompanion entry) {
    return into(partners).insert(entry);
  }

  /// Update an existing partner
  Future<bool> updatePartner(PartnersCompanion entry) {
    return (update(partners)..where((p) => p.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Toggle partner active status
  Future<void> toggleActive(String id, bool isActive) {
    return (update(partners)..where((p) => p.id.equals(id)))
        .write(PartnersCompanion(
          isActive: Value(isActive),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// Delete partner permanently
  Future<int> deletePartner(String id) {
    return (delete(partners)..where((p) => p.id.equals(id))).go();
  }
}
