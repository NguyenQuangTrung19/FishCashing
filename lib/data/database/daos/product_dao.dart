/// Data Access Object for Products.
library;

import 'package:drift/drift.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/tables/tables.dart';

part 'product_dao.g.dart';

/// Product with its category name (joined query result)
class ProductWithCategory {
  final Product product;
  final String categoryName;

  ProductWithCategory({
    required this.product,
    required this.categoryName,
  });
}

@DriftAccessor(tables: [Products, Categories])
class ProductDao extends DatabaseAccessor<AppDatabase>
    with _$ProductDaoMixin {
  ProductDao(super.db);

  /// Get all active products with category names
  Future<List<ProductWithCategory>> getAllActiveWithCategory() async {
    final query = select(products).join([
      innerJoin(categories, categories.id.equalsExp(products.categoryId)),
    ])
      ..where(products.isActive.equals(true))
      ..orderBy([OrderingTerm.asc(products.name)]);

    final rows = await query.get();
    return rows.map((row) {
      return ProductWithCategory(
        product: row.readTable(products),
        categoryName: row.readTable(categories).name,
      );
    }).toList();
  }

  /// Watch all products with category names
  Stream<List<ProductWithCategory>> watchAllWithCategory() {
    final query = select(products).join([
      innerJoin(categories, categories.id.equalsExp(products.categoryId)),
    ])
      ..orderBy([OrderingTerm.asc(products.name)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ProductWithCategory(
          product: row.readTable(products),
          categoryName: row.readTable(categories).name,
        );
      }).toList();
    });
  }

  /// Watch active products with category names
  Stream<List<ProductWithCategory>> watchActiveWithCategory() {
    final query = select(products).join([
      innerJoin(categories, categories.id.equalsExp(products.categoryId)),
    ])
      ..where(products.isActive.equals(true))
      ..orderBy([OrderingTerm.asc(products.name)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ProductWithCategory(
          product: row.readTable(products),
          categoryName: row.readTable(categories).name,
        );
      }).toList();
    });
  }

  /// Get products filtered by category
  Future<List<Product>> getByCategory(String categoryId) {
    return (select(products)
          ..where((p) => p.categoryId.equals(categoryId))
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Get product by ID
  Future<Product?> getById(String id) {
    return (select(products)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new product
  Future<void> insertProduct(ProductsCompanion entry) {
    return into(products).insert(entry);
  }

  /// Update an existing product
  Future<bool> updateProduct(ProductsCompanion entry) {
    return (update(products)..where((p) => p.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Toggle product active status
  Future<void> toggleActive(String id, bool isActive) {
    return (update(products)..where((p) => p.id.equals(id)))
        .write(ProductsCompanion(
          isActive: Value(isActive),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// Delete product permanently
  Future<int> deleteProduct(String id) {
    return (delete(products)..where((p) => p.id.equals(id))).go();
  }
}
