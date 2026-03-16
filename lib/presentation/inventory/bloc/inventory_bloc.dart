/// BLoC for inventory (stock) management.
///
/// Supports time-period filtering and stock reset actions.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fishcash_pos/data/repositories/inventory_repository.dart';

// === EVENTS ===

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();
  @override
  List<Object?> get props => [];
}

class InventoryLoadRequested extends InventoryEvent {
  final InventoryPeriod period;
  const InventoryLoadRequested({this.period = InventoryPeriod.all});
  @override
  List<Object?> get props => [period];
}

class InventoryResetStock extends InventoryEvent {
  final String productId;
  final int currentStockInGrams;
  final String reason;
  final InventoryPeriod currentPeriod;

  const InventoryResetStock({
    required this.productId,
    required this.currentStockInGrams,
    required this.reason,
    required this.currentPeriod,
  });
  @override
  List<Object?> get props => [productId, currentStockInGrams, reason];
}

// === STATE ===

enum InventoryStatus { initial, loading, loaded, error }

class InventoryState extends Equatable {
  final InventoryStatus status;
  final List<InventoryItem> items;
  final InventoryPeriod currentPeriod;
  final String? errorMessage;

  const InventoryState({
    this.status = InventoryStatus.initial,
    this.items = const [],
    this.currentPeriod = InventoryPeriod.all,
    this.errorMessage,
  });

  InventoryState copyWith({
    InventoryStatus? status,
    List<InventoryItem>? items,
    InventoryPeriod? currentPeriod,
    String? errorMessage,
  }) {
    return InventoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, currentPeriod, errorMessage];
}

// === BLOC ===

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository _repository;

  InventoryBloc(this._repository) : super(const InventoryState()) {
    on<InventoryLoadRequested>(_onLoad);
    on<InventoryResetStock>(_onResetStock);
  }

  Future<void> _onLoad(
    InventoryLoadRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(state.copyWith(
      status: InventoryStatus.loading,
      currentPeriod: event.period,
    ));
    try {
      final items =
          await _repository.getInventorySummary(period: event.period);
      emit(state.copyWith(
        status: InventoryStatus.loaded,
        items: items,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InventoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onResetStock(
    InventoryResetStock event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.resetProductStock(
        productId: event.productId,
        currentStockInGrams: event.currentStockInGrams,
        reason: event.reason,
      );
      // Reload inventory after reset
      add(InventoryLoadRequested(period: event.currentPeriod));
    } catch (e) {
      emit(state.copyWith(
        status: InventoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
