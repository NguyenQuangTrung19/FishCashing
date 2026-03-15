/// Domain model representing a product.
library;

import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String categoryId;
  final String categoryName;
  final String name;
  final Decimal price; // in base currency (VND)
  final String unit; // default unit: kg, tấn, con, khay
  final String imagePath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.categoryId,
    this.categoryName = '',
    required this.name,
    required this.price,
    this.unit = 'kg',
    this.imagePath = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductModel copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? name,
    Decimal? price,
    String? unit,
    String? imagePath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, categoryId, name, price, unit, isActive];
}
