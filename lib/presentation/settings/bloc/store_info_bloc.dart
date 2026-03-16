/// BLoC for Store Info management.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/repositories/store_info_repository.dart';

// === EVENTS ===

sealed class StoreInfoEvent extends Equatable {
  const StoreInfoEvent();
  @override
  List<Object?> get props => [];
}

final class StoreInfoLoadRequested extends StoreInfoEvent {
  const StoreInfoLoadRequested();
}

final class StoreInfoSaveRequested extends StoreInfoEvent {
  final String name;
  final String address;
  final String phone;
  final String logoPath;
  final String qrImagePath;

  const StoreInfoSaveRequested({
    required this.name,
    this.address = '',
    this.phone = '',
    this.logoPath = '',
    this.qrImagePath = '',
  });

  @override
  List<Object?> get props => [name, address, phone, logoPath, qrImagePath];
}

// === STATES ===

enum StoreInfoStatus { initial, loading, loaded, saving, saved, error }

final class StoreInfoState extends Equatable {
  final StoreInfoStatus status;
  final StoreInfo? storeInfo;
  final String? errorMessage;

  const StoreInfoState({
    this.status = StoreInfoStatus.initial,
    this.storeInfo,
    this.errorMessage,
  });

  StoreInfoState copyWith({
    StoreInfoStatus? status,
    StoreInfo? storeInfo,
    String? errorMessage,
    bool clearStoreInfo = false,
  }) {
    return StoreInfoState(
      status: status ?? this.status,
      storeInfo: clearStoreInfo ? null : (storeInfo ?? this.storeInfo),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, storeInfo, errorMessage];
}

// === BLOC ===

class StoreInfoBloc extends Bloc<StoreInfoEvent, StoreInfoState> {
  final StoreInfoRepository _repository;

  StoreInfoBloc(this._repository) : super(const StoreInfoState()) {
    on<StoreInfoLoadRequested>(_onLoad);
    on<StoreInfoSaveRequested>(_onSave);
  }

  Future<void> _onLoad(
      StoreInfoLoadRequested event, Emitter<StoreInfoState> emit) async {
    emit(state.copyWith(status: StoreInfoStatus.loading));
    try {
      final info = await _repository.getStoreInfo();
      emit(state.copyWith(
        status: StoreInfoStatus.loaded,
        storeInfo: info,
        clearStoreInfo: info == null,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: StoreInfoStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSave(
      StoreInfoSaveRequested event, Emitter<StoreInfoState> emit) async {
    emit(state.copyWith(status: StoreInfoStatus.saving));
    try {
      await _repository.saveStoreInfo(
        name: event.name,
        address: event.address,
        phone: event.phone,
        logoPath: event.logoPath,
        qrImagePath: event.qrImagePath,
      );
      // Reload to get the saved data
      final info = await _repository.getStoreInfo();
      emit(state.copyWith(
        status: StoreInfoStatus.saved,
        storeInfo: info,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: StoreInfoStatus.error, errorMessage: e.toString()));
    }
  }
}
