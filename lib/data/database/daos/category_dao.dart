/// Data Access Object for Categories.
library;

import 'package:drift/drift.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/tables/tables.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Get all active categories, ordered by name
  Future<List<Category>> getAllActive() {
    return (select(categories)
          ..where((c) => c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  /// Get all categories (including hidden), ordered by name
  Future<List<Category>> getAll() {
    return (select(categories)
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  /// Watch all categories (reactive stream)
  Stream<List<Category>> watchAll() {
    return (select(categories)
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  /// Watch active categories only
  Stream<List<Category>> watchActive() {
    return (select(categories)
          ..where((c) => c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  /// Get category by ID
  Future<Category?> getById(String id) {
    return (select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new category
  Future<void> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  /// Update an existing category
  Future<bool> updateCategory(CategoriesCompanion entry) {
    return (update(categories)..where((c) => c.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Toggle category active status (soft delete)
  Future<void> toggleActive(String id, bool isActive) {
    return (update(categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(
          isActive: Value(isActive),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// Delete category permanently
  Future<int> deleteCategory(String id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }
}
