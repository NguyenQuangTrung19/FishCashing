/// BLoC for Trading Session management.
///
/// Handles session CRUD, and provides session list/detail states.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fishcash_pos/data/repositories/trading_session_repository.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/repositories/trade_order_repository.dart';

// === EVENTS ===

sealed class TradingEvent extends Equatable {
  const TradingEvent();
  @override
  List<Object?> get props => [];
}

final class TradingSessionsLoadRequested extends TradingEvent {
  const TradingSessionsLoadRequested();
}

final class TradingSessionCreateRequested extends TradingEvent {
  final String note;
  const TradingSessionCreateRequested({this.note = ''});
  @override
  List<Object?> get props => [note];
}

final class TradingSessionDeleteRequested extends TradingEvent {
  final String id;
  const TradingSessionDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

final class TradingSessionDetailRequested extends TradingEvent {
  final String sessionId;
  const TradingSessionDetailRequested(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

/// Delete a single order within a session
final class TradingOrderDeleteRequested extends TradingEvent {
  final String orderId;
  final String sessionId;
  const TradingOrderDeleteRequested(this.orderId, this.sessionId);
  @override
  List<Object?> get props => [orderId, sessionId];
}

// === STATES ===

enum TradingStatus { initial, loading, loaded, error }

final class TradingState extends Equatable {
  final TradingStatus status;
  final List<TradingSessionModel> sessions;
  final TradingSessionModel? currentSession;
  final List<TradeOrderWithDetails> currentOrders;
  final String? errorMessage;

  const TradingState({
    this.status = TradingStatus.initial,
    this.sessions = const [],
    this.currentSession,
    this.currentOrders = const [],
    this.errorMessage,
  });

  TradingState copyWith({
    TradingStatus? status,
    List<TradingSessionModel>? sessions,
    TradingSessionModel? currentSession,
    List<TradeOrderWithDetails>? currentOrders,
    String? errorMessage,
  }) {
    return TradingState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      currentSession: currentSession ?? this.currentSession,
      currentOrders: currentOrders ?? this.currentOrders,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, sessions, currentSession, currentOrders, errorMessage];
}

// === BLOC ===

class TradingBloc extends Bloc<TradingEvent, TradingState> {
  final TradingSessionRepository _sessionRepo;
  final TradeOrderRepository _orderRepo;

  TradingBloc(this._sessionRepo, this._orderRepo)
      : super(const TradingState()) {
    on<TradingSessionsLoadRequested>(_onLoad);
    on<TradingSessionCreateRequested>(_onCreate);
    on<TradingSessionDeleteRequested>(_onDelete);
    on<TradingSessionDetailRequested>(_onDetail);
    on<TradingOrderDeleteRequested>(_onOrderDelete);
  }

  Future<void> _onLoad(
    TradingSessionsLoadRequested event,
    Emitter<TradingState> emit,
  ) async {
    emit(state.copyWith(status: TradingStatus.loading));

    await emit.forEach(
      _sessionRepo.watchAll(),
      onData: (sessions) => state.copyWith(
        status: TradingStatus.loaded,
        sessions: sessions,
      ),
      onError: (e, _) => state.copyWith(
        status: TradingStatus.error,
        errorMessage: e.toString(),
      ),
    );
  }

  Future<void> _onCreate(
    TradingSessionCreateRequested event,
    Emitter<TradingState> emit,
  ) async {
    try {
      await _sessionRepo.create(note: event.note);
      add(const TradingSessionsLoadRequested());
    } catch (e) {
      emit(state.copyWith(
        status: TradingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDelete(
    TradingSessionDeleteRequested event,
    Emitter<TradingState> emit,
  ) async {
    try {
      await _sessionRepo.delete(event.id);
      add(const TradingSessionsLoadRequested());
    } catch (e) {
      emit(state.copyWith(
        status: TradingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDetail(
    TradingSessionDetailRequested event,
    Emitter<TradingState> emit,
  ) async {
    emit(state.copyWith(status: TradingStatus.loading));
    try {
      final session = await _sessionRepo.getById(event.sessionId);
      final orders =
          await _orderRepo.getOrdersBySession(event.sessionId);

      emit(state.copyWith(
        status: TradingStatus.loaded,
        currentSession: session,
        currentOrders: orders,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TradingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onOrderDelete(
    TradingOrderDeleteRequested event,
    Emitter<TradingState> emit,
  ) async {
    try {
      await _orderRepo.deleteOrder(event.orderId, sessionId: event.sessionId);
      // Reload session detail
      add(TradingSessionDetailRequested(event.sessionId));
    } catch (e) {
      emit(state.copyWith(
        status: TradingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
