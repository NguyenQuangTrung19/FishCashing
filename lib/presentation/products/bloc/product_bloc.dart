/// BLoC for Product management.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fishcash_pos/data/repositories/product_repository.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_event_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;

  ProductBloc(this._repository) : super(const ProductState()) {
    on<ProductsLoadRequested>(_onLoad);
    on<ProductCreateRequested>(_onCreate);
    on<ProductUpdateRequested>(_onUpdate);
    on<ProductToggleRequested>(_onToggle);
  }

  Future<void> _onLoad(
    ProductsLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.loading));

    try {
      // Use stream's first emission for initial load
      final products = await _repository.watchAll().first;
      emit(state.copyWith(
        status: ProductStatus.loaded,
        products: products,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProductStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreate(
    ProductCreateRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.create(
        name: event.name,
        categoryId: event.categoryId,
        price: event.price,
        unit: event.unit,
      );
      add(const ProductsLoadRequested());
    } catch (e) {
      emit(state.copyWith(
        status: ProductStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdate(
    ProductUpdateRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.update(
        id: event.id,
        name: event.name,
        categoryId: event.categoryId,
        price: event.price,
        unit: event.unit,
      );
      add(const ProductsLoadRequested());
    } catch (e) {
      emit(state.copyWith(
        status: ProductStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onToggle(
    ProductToggleRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.toggleActive(event.id, event.isActive);
      add(const ProductsLoadRequested());
    } catch (e) {
      emit(state.copyWith(
        status: ProductStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
