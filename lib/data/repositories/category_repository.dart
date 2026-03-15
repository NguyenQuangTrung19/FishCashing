/// Repository for Category operations.
/// Bridges the DAO layer with domain models.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/daos/category_dao.dart';
import 'package:fishcash_pos/domain/models/category_model.dart';

class CategoryRepository {
  final CategoryDao _dao;
  static const _uuid = Uuid();

  CategoryRepository(this._dao);

  // === Mappers ===

  CategoryModel _toModel(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // === Queries ===

  Future<List<CategoryModel>> getAllActive() async {
    final entities = await _dao.getAllActive();
    return entities.map(_toModel).toList();
  }

  Future<List<CategoryModel>> getAll() async {
    final entities = await _dao.getAll();
    return entities.map(_toModel).toList();
  }

  Stream<List<CategoryModel>> watchAll() {
    return _dao.watchAll().map(
      (list) => list.map(_toModel).toList(),
    );
  }

  Stream<List<CategoryModel>> watchActive() {
    return _dao.watchActive().map(
      (list) => list.map(_toModel).toList(),
    );
  }

  Future<CategoryModel?> getById(String id) async {
    final entity = await _dao.getById(id);
    return entity != null ? _toModel(entity) : null;
  }

  // === Mutations ===

  Future<CategoryModel> create({
    required String name,
    String description = '',
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    final companion = CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      isActive: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await _dao.insertCategory(companion);

    return CategoryModel(
      id: id,
      name: name,
      description: description,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> update({
    required String id,
    required String name,
    String? description,
  }) async {
    final companion = CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      description: description != null ? Value(description) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    await _dao.updateCategory(companion);
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _dao.toggleActive(id, isActive);
  }

  Future<void> delete(String id) async {
    await _dao.deleteCategory(id);
  }
}
