/// BLoC for Category management.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fishcash_pos/data/repositories/category_repository.dart';
import 'package:fishcash_pos/presentation/categories/bloc/category_event_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _repository;

  CategoryBloc(this._repository) : super(const CategoryState()) {
    on<CategoriesLoadRequested>(_onLoad);
    on<CategoryCreateRequested>(_onCreate);
    on<CategoryUpdateRequested>(_onUpdate);
    on<CategoryDeleteRequested>(_onDelete);
    on<CategoryToggleRequested>(_onToggle);
  }

  Future<void> _onLoad(
    CategoriesLoadRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(status: CategoryStatus.loading));

    try {
      final categories = await _repository.getAll();
      emit(state.copyWith(
        status: CategoryStatus.loaded,
        categories: categories,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CategoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreate(
    CategoryCreateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.create(
        name: event.name,
        description: event.description,
      );
      // Reload after create
      add(const CategoriesLoadRequested());
    } catch (e) {
      emit(state.copyWith(
        status: CategoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdate(
    CategoryUpdateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.update(
        id: event.id,
        name: event.name,
        description: event.description,
      );
      add(const CategoriesLoadRequested());
    } catch (e) {
      emit(state.copyWith(
        status: CategoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDelete(
    CategoryDeleteRequested event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.delete(event.id);
      add(const CategoriesLoadRequested());
    } catch (e) {
      emit(state.copyWith(
        status: CategoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onToggle(
    CategoryToggleRequested event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.toggleActive(event.id, event.isActive);
      add(const CategoriesLoadRequested());
    } catch (e) {
      emit(state.copyWith(
        status: CategoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
