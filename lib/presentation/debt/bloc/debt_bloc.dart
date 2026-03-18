/// BLoC for debt (công nợ) management.
///
/// Handles loading receivables/payables and recording payments.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fishcash_pos/data/repositories/debt_repository.dart';

// === EVENTS ===

abstract class DebtEvent extends Equatable {
  const DebtEvent();
  @override
  List<Object?> get props => [];
}

class DebtLoadRequested extends DebtEvent {
  const DebtLoadRequested();
}

class DebtPaymentAdded extends DebtEvent {
  final String orderId;
  final int amountInCents;
  final String note;
  final DateTime? paymentDate;

  const DebtPaymentAdded({
    required this.orderId,
    required this.amountInCents,
    this.note = '',
    this.paymentDate,
  });
  @override
  List<Object?> get props => [orderId, amountInCents, note, paymentDate];
}

class DebtPartnerDetailRequested extends DebtEvent {
  final String partnerId;
  const DebtPartnerDetailRequested(this.partnerId);
  @override
  List<Object?> get props => [partnerId];
}

class DebtOrderDeleted extends DebtEvent {
  final String orderId;
  const DebtOrderDeleted(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

// === STATE ===

enum DebtStatus { initial, loading, loaded, error }

class DebtState extends Equatable {
  final DebtStatus status;
  final List<DebtSummary> receivables; // khách nợ mình
  final List<DebtSummary> payables; // mình nợ NCC
  final List<DebtOrderDetail> partnerOrders; // chi tiết đơn hàng per partner
  final String? selectedPartnerId;
  final String? errorMessage;

  const DebtState({
    this.status = DebtStatus.initial,
    this.receivables = const [],
    this.payables = const [],
    this.partnerOrders = const [],
    this.selectedPartnerId,
    this.errorMessage,
  });

  DebtState copyWith({
    DebtStatus? status,
    List<DebtSummary>? receivables,
    List<DebtSummary>? payables,
    List<DebtOrderDetail>? partnerOrders,
    String? selectedPartnerId,
    String? errorMessage,
  }) {
    return DebtState(
      status: status ?? this.status,
      receivables: receivables ?? this.receivables,
      payables: payables ?? this.payables,
      partnerOrders: partnerOrders ?? this.partnerOrders,
      selectedPartnerId: selectedPartnerId ?? this.selectedPartnerId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, receivables, payables, partnerOrders, selectedPartnerId, errorMessage];
}

// === BLOC ===

class DebtBloc extends Bloc<DebtEvent, DebtState> {
  final DebtRepository _repository;

  DebtBloc(this._repository) : super(const DebtState()) {
    on<DebtLoadRequested>(_onLoad);
    on<DebtPaymentAdded>(_onPaymentAdded);
    on<DebtPartnerDetailRequested>(_onPartnerDetail);
    on<DebtOrderDeleted>(_onOrderDeleted);
  }

  Future<void> _onLoad(
    DebtLoadRequested event,
    Emitter<DebtState> emit,
  ) async {
    emit(state.copyWith(status: DebtStatus.loading));
    try {
      final receivables = await _repository.getReceivables();
      final payables = await _repository.getPayables();
      emit(state.copyWith(
        status: DebtStatus.loaded,
        receivables: receivables,
        payables: payables,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DebtStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onPaymentAdded(
    DebtPaymentAdded event,
    Emitter<DebtState> emit,
  ) async {
    try {
      await _repository.addPayment(
        orderId: event.orderId,
        amountInCents: event.amountInCents,
        note: event.note,
        paymentDate: event.paymentDate,
      );
      // Reload both debt summaries and partner detail
      add(const DebtLoadRequested());
      if (state.selectedPartnerId != null) {
        add(DebtPartnerDetailRequested(state.selectedPartnerId!));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DebtStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onPartnerDetail(
    DebtPartnerDetailRequested event,
    Emitter<DebtState> emit,
  ) async {
    try {
      final orders = await _repository.getPartnerOrders(event.partnerId);
      emit(state.copyWith(
        partnerOrders: orders,
        selectedPartnerId: event.partnerId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DebtStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onOrderDeleted(
    DebtOrderDeleted event,
    Emitter<DebtState> emit,
  ) async {
    try {
      await _repository.deleteDebtOrder(event.orderId);
      // Reload both debt summaries and partner detail
      add(const DebtLoadRequested());
      if (state.selectedPartnerId != null) {
        add(DebtPartnerDetailRequested(state.selectedPartnerId!));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DebtStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
