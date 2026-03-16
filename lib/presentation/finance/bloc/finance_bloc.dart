/// Finance BLoC — manages state for the Finance page.
///
/// Handles date range filtering, order type filtering,
/// and loading financial data for charts and transaction list.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/repositories/finance_repository.dart';

// =============================================
// EVENTS
// =============================================

sealed class FinanceEvent {
  const FinanceEvent();
}

/// Initial load
class FinanceLoadRequested extends FinanceEvent {
  const FinanceLoadRequested();
}

/// Date range changed
class FinanceDateRangeChanged extends FinanceEvent {
  final FinanceDateRange range;
  const FinanceDateRangeChanged(this.range);
}

/// Order type filter changed (null = all)
class FinanceOrderTypeChanged extends FinanceEvent {
  final String? orderType;
  const FinanceOrderTypeChanged(this.orderType);
}

/// Year changed for trend chart
class FinanceTrendYearChanged extends FinanceEvent {
  final int year;
  const FinanceTrendYearChanged(this.year);
}

// =============================================
// STATE
// =============================================

enum FinanceStatus { initial, loading, loaded, error }

class FinanceState {
  final FinanceStatus status;
  final FinanceDateRange dateRange;
  final String? orderTypeFilter; // null = all
  final FinanceSummary summary;
  final List<FinanceTrendPoint> trendData;
  final List<FinanceBreakdown> breakdown;
  final List<TradeOrderWithDetails> orders;
  final List<int> availableYears;
  final int trendYear;
  final String? errorMessage;

  FinanceState({
    this.status = FinanceStatus.initial,
    required this.dateRange,
    this.orderTypeFilter,
    FinanceSummary? summary,
    this.trendData = const [],
    this.breakdown = const [],
    this.orders = const [],
    this.availableYears = const [],
    this.trendYear = 0,
    this.errorMessage,
  }) : summary = summary ?? FinanceSummary.empty;

  FinanceState copyWith({
    FinanceStatus? status,
    FinanceDateRange? dateRange,
    String? Function()? orderTypeFilter,
    FinanceSummary? summary,
    List<FinanceTrendPoint>? trendData,
    List<FinanceBreakdown>? breakdown,
    List<TradeOrderWithDetails>? orders,
    List<int>? availableYears,
    int? trendYear,
    String? errorMessage,
  }) {
    return FinanceState(
      status: status ?? this.status,
      dateRange: dateRange ?? this.dateRange,
      orderTypeFilter:
          orderTypeFilter != null ? orderTypeFilter() : this.orderTypeFilter,
      summary: summary ?? this.summary,
      trendData: trendData ?? this.trendData,
      breakdown: breakdown ?? this.breakdown,
      orders: orders ?? this.orders,
      availableYears: availableYears ?? this.availableYears,
      trendYear: trendYear ?? this.trendYear,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// =============================================
// BLOC
// =============================================

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository _repository;

  FinanceBloc(this._repository)
      : super(FinanceState(dateRange: FinanceDateRange.thisMonth())) {
    on<FinanceLoadRequested>(_onLoad);
    on<FinanceDateRangeChanged>(_onDateRangeChanged);
    on<FinanceOrderTypeChanged>(_onOrderTypeChanged);
    on<FinanceTrendYearChanged>(_onTrendYearChanged);
  }

  Future<void> _onLoad(
    FinanceLoadRequested event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final years = await _repository.getAvailableYears();
      final trendYear =
          state.trendYear > 0 ? state.trendYear : DateTime.now().year;

      final results = await Future.wait([
        _repository.getSummary(state.dateRange),
        _repository.getMonthlyTrend(trendYear),
        _repository.getBreakdown(state.dateRange),
        _repository.getFilteredOrders(
          state.dateRange,
          orderType: state.orderTypeFilter,
        ),
      ]);

      emit(state.copyWith(
        status: FinanceStatus.loaded,
        summary: results[0] as FinanceSummary,
        trendData: results[1] as List<FinanceTrendPoint>,
        breakdown: results[2] as List<FinanceBreakdown>,
        orders: results[3] as List<TradeOrderWithDetails>,
        availableYears: years,
        trendYear: trendYear,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDateRangeChanged(
    FinanceDateRangeChanged event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(
      dateRange: event.range,
      status: FinanceStatus.loading,
    ));
    try {
      final results = await Future.wait([
        _repository.getSummary(event.range),
        _repository.getBreakdown(event.range),
        _repository.getFilteredOrders(
          event.range,
          orderType: state.orderTypeFilter,
        ),
      ]);

      emit(state.copyWith(
        status: FinanceStatus.loaded,
        summary: results[0] as FinanceSummary,
        breakdown: results[1] as List<FinanceBreakdown>,
        orders: results[2] as List<TradeOrderWithDetails>,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onOrderTypeChanged(
    FinanceOrderTypeChanged event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(
      orderTypeFilter: () => event.orderType,
      status: FinanceStatus.loading,
    ));
    try {
      final orders = await _repository.getFilteredOrders(
        state.dateRange,
        orderType: event.orderType,
      );
      emit(state.copyWith(
        status: FinanceStatus.loaded,
        orders: orders,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onTrendYearChanged(
    FinanceTrendYearChanged event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(
      trendYear: event.year,
      status: FinanceStatus.loading,
    ));
    try {
      final trendData = await _repository.getMonthlyTrend(event.year);
      emit(state.copyWith(
        status: FinanceStatus.loaded,
        trendData: trendData,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
