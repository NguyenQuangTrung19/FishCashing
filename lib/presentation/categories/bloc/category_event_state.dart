/// BLoC events and states for Category management.
library;

import 'package:equatable/equatable.dart';
import 'package:fishcash_pos/domain/models/category_model.dart';

// === EVENTS ===

sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

final class CategoriesLoadRequested extends CategoryEvent {
  const CategoriesLoadRequested();
}

final class CategoryCreateRequested extends CategoryEvent {
  final String name;
  final String description;

  const CategoryCreateRequested({
    required this.name,
    this.description = '',
  });

  @override
  List<Object?> get props => [name, description];
}

final class CategoryUpdateRequested extends CategoryEvent {
  final String id;
  final String name;
  final String? description;

  const CategoryUpdateRequested({
    required this.id,
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, description];
}

final class CategoryDeleteRequested extends CategoryEvent {
  final String id;

  const CategoryDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

final class CategoryToggleRequested extends CategoryEvent {
  final String id;
  final bool isActive;

  const CategoryToggleRequested({required this.id, required this.isActive});

  @override
  List<Object?> get props => [id, isActive];
}

// === STATES ===

enum CategoryStatus { initial, loading, loaded, error }

final class CategoryState extends Equatable {
  final CategoryStatus status;
  final List<CategoryModel> categories;
  final String? errorMessage;

  const CategoryState({
    this.status = CategoryStatus.initial,
    this.categories = const [],
    this.errorMessage,
  });

  CategoryState copyWith({
    CategoryStatus? status,
    List<CategoryModel>? categories,
    String? errorMessage,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, categories, errorMessage];
}
