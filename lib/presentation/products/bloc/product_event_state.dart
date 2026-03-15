/// BLoC events and states for Product management.
library;

import 'package:equatable/equatable.dart';
import 'package:decimal/decimal.dart';
import 'package:fishcash_pos/domain/models/product_model.dart';

// === EVENTS ===

sealed class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

final class ProductsLoadRequested extends ProductEvent {
  const ProductsLoadRequested();
}

final class ProductCreateRequested extends ProductEvent {
  final String name;
  final String categoryId;
  final Decimal price;
  final String unit;

  const ProductCreateRequested({
    required this.name,
    required this.categoryId,
    required this.price,
    this.unit = 'kg',
  });

  @override
  List<Object?> get props => [name, categoryId, price, unit];
}

final class ProductUpdateRequested extends ProductEvent {
  final String id;
  final String name;
  final String categoryId;
  final Decimal price;
  final String? unit;

  const ProductUpdateRequested({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.unit,
  });

  @override
  List<Object?> get props => [id, name, categoryId, price, unit];
}

final class ProductToggleRequested extends ProductEvent {
  final String id;
  final bool isActive;

  const ProductToggleRequested({required this.id, required this.isActive});

  @override
  List<Object?> get props => [id, isActive];
}

// === STATES ===

enum ProductStatus { initial, loading, loaded, error }

final class ProductState extends Equatable {
  final ProductStatus status;
  final List<ProductModel> products;
  final String? errorMessage;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.errorMessage,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<ProductModel>? products,
    String? errorMessage,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, products, errorMessage];
}
