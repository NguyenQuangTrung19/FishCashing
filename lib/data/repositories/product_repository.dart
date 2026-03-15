/// Repository for Product operations.
/// Bridges the DAO layer with domain models.
library;

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/daos/product_dao.dart';
import 'package:fishcash_pos/domain/models/product_model.dart';

class ProductRepository {
  final ProductDao _dao;
  static const _uuid = Uuid();

  ProductRepository(this._dao);

  // === Mappers ===

  /// Convert cents (integer) back to Decimal currency value
  static Decimal _centsToDecimal(int cents) {
    return (Decimal.fromInt(cents) / Decimal.fromInt(100)).toDecimal();
  }

  /// Convert Decimal currency value to cents (integer)
  static int _decimalToCents(Decimal value) {
    return (value * Decimal.fromInt(100)).toBigInt().toInt();
  }

  ProductModel _toModel(ProductWithCategory pwc) {
    final p = pwc.product;
    return ProductModel(
      id: p.id,
      categoryId: p.categoryId,
      categoryName: pwc.categoryName,
      name: p.name,
      price: _centsToDecimal(p.priceInCents),
      unit: p.unit,
      imagePath: p.imagePath,
      isActive: p.isActive,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
  }

  // === Queries ===

  Future<List<ProductModel>> getAllActive() async {
    final entities = await _dao.getAllActiveWithCategory();
    return entities.map(_toModel).toList();
  }

  Stream<List<ProductModel>> watchAll() {
    return _dao.watchAllWithCategory().map(
      (list) => list.map(_toModel).toList(),
    );
  }

  Stream<List<ProductModel>> watchActive() {
    return _dao.watchActiveWithCategory().map(
      (list) => list.map(_toModel).toList(),
    );
  }

  // === Mutations ===

  Future<ProductModel> create({
    required String name,
    required String categoryId,
    required Decimal price,
    String unit = 'kg',
    String imagePath = '',
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    final companion = ProductsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      priceInCents: Value(_decimalToCents(price)),
      unit: Value(unit),
      imagePath: Value(imagePath),
      isActive: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await _dao.insertProduct(companion);

    return ProductModel(
      id: id,
      categoryId: categoryId,
      name: name,
      price: price,
      unit: unit,
      imagePath: imagePath,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> update({
    required String id,
    required String name,
    required String categoryId,
    required Decimal price,
    String? unit,
    String? imagePath,
  }) async {
    final companion = ProductsCompanion(
      id: Value(id),
      name: Value(name),
      categoryId: Value(categoryId),
      priceInCents: Value(_decimalToCents(price)),
      unit: unit != null ? Value(unit) : const Value.absent(),
      imagePath: imagePath != null ? Value(imagePath) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    await _dao.updateProduct(companion);
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _dao.toggleActive(id, isActive);
  }

  Future<void> delete(String id) async {
    await _dao.deleteProduct(id);
  }
}
