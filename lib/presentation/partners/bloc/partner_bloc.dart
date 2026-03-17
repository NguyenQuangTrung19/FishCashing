/// BLoC for Partner management.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fishcash_pos/data/repositories/partner_repository.dart';
import 'package:fishcash_pos/domain/models/partner_model.dart';

// === EVENTS ===

sealed class PartnerEvent extends Equatable {
  const PartnerEvent();
  @override
  List<Object?> get props => [];
}

final class PartnersLoadRequested extends PartnerEvent {
  const PartnersLoadRequested();
}

final class PartnerCreateRequested extends PartnerEvent {
  final String name;
  final PartnerType type;
  final String phone;
  final String address;
  final String note;

  const PartnerCreateRequested({
    required this.name,
    required this.type,
    this.phone = '',
    this.address = '',
    this.note = '',
  });

  @override
  List<Object?> get props => [name, type, phone, address, note];
}

final class PartnerUpdateRequested extends PartnerEvent {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;

  const PartnerUpdateRequested({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
  });

  @override
  List<Object?> get props => [id, name, phone, address, note];
}

final class PartnerToggleRequested extends PartnerEvent {
  final String id;
  final bool isActive;
  const PartnerToggleRequested({required this.id, required this.isActive});
  @override
  List<Object?> get props => [id, isActive];
}

final class PartnerDeleteRequested extends PartnerEvent {
  final String id;
  const PartnerDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

// === STATES ===

enum PartnerStatus { initial, loading, loaded, error }

final class PartnerState extends Equatable {
  final PartnerStatus status;
  final List<PartnerModel> partners;
  final String? errorMessage;

  const PartnerState({
    this.status = PartnerStatus.initial,
    this.partners = const [],
    this.errorMessage,
  });

  List<PartnerModel> get suppliers =>
      partners.where((p) => p.type == PartnerType.supplier).toList();

  List<PartnerModel> get buyers =>
      partners.where((p) => p.type == PartnerType.buyer).toList();

  PartnerState copyWith({
    PartnerStatus? status,
    List<PartnerModel>? partners,
    String? errorMessage,
  }) {
    return PartnerState(
      status: status ?? this.status,
      partners: partners ?? this.partners,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, partners, errorMessage];
}

// === BLOC ===

class PartnerBloc extends Bloc<PartnerEvent, PartnerState> {
  final PartnerRepository _repository;

  PartnerBloc(this._repository) : super(const PartnerState()) {
    on<PartnersLoadRequested>(_onLoad);
    on<PartnerCreateRequested>(_onCreate);
    on<PartnerUpdateRequested>(_onUpdate);
    on<PartnerToggleRequested>(_onToggle);
    on<PartnerDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(
      PartnersLoadRequested event, Emitter<PartnerState> emit) async {
    emit(state.copyWith(status: PartnerStatus.loading));

    await emit.forEach(
      _repository.watchAll(),
      onData: (partners) => state.copyWith(
        status: PartnerStatus.loaded,
        partners: partners,
      ),
      onError: (e, _) => state.copyWith(
        status: PartnerStatus.error,
        errorMessage: e.toString(),
      ),
    );
  }

  Future<void> _onCreate(
      PartnerCreateRequested event, Emitter<PartnerState> emit) async {
    try {
      await _repository.create(
        name: event.name,
        type: event.type,
        phone: event.phone,
        address: event.address,
        note: event.note,
      );
      add(const PartnersLoadRequested());
    } catch (e) {
      emit(state.copyWith(
          status: PartnerStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdate(
      PartnerUpdateRequested event, Emitter<PartnerState> emit) async {
    try {
      await _repository.update(
        id: event.id,
        name: event.name,
        phone: event.phone,
        address: event.address,
        note: event.note,
      );
      add(const PartnersLoadRequested());
    } catch (e) {
      emit(state.copyWith(
          status: PartnerStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onToggle(
      PartnerToggleRequested event, Emitter<PartnerState> emit) async {
    try {
      await _repository.toggleActive(event.id, event.isActive);
      add(const PartnersLoadRequested());
    } catch (e) {
      emit(state.copyWith(
          status: PartnerStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDelete(
      PartnerDeleteRequested event, Emitter<PartnerState> emit) async {
    try {
      await _repository.delete(event.id);
      add(const PartnersLoadRequested());
    } catch (e) {
      emit(state.copyWith(
          status: PartnerStatus.error, errorMessage: e.toString()));
    }
  }
}
