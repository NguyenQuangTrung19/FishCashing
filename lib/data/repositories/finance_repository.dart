/// Finance repository — aggregates trade order data for finance page.
///
/// Provides summary, trends, breakdowns, and filtered orders
/// for the finance page's charts and transaction list.
library;

import 'package:decimal/decimal.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';

// =============================================
// DATA MODELS
// =============================================

/// Date range for filtering
class FinanceDateRange {
  final DateTime from;
  final DateTime to;
  final String label;

  const FinanceDateRange({
    required this.from,
    required this.to,
    required this.label,
  });

  /// This week (Mon → Sun)
  factory FinanceDateRange.thisWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return FinanceDateRange(from: start, to: end, label: 'Tuần này');
  }

  /// This month
  factory FinanceDateRange.thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return FinanceDateRange(from: start, to: end, label: 'Tháng này');
  }

  /// This year
  factory FinanceDateRange.thisYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return FinanceDateRange(from: start, to: end, label: 'Năm ${now.year}');
  }

  /// All time
  factory FinanceDateRange.allTime() {
    return FinanceDateRange(
      from: DateTime(2020, 1, 1),
      to: DateTime.now().copyWith(hour: 23, minute: 59, second: 59),
      label: 'Tất cả',
    );
  }

  /// Custom range
  factory FinanceDateRange.custom(DateTime from, DateTime to) {
    return FinanceDateRange(
      from: DateTime(from.year, from.month, from.day),
      to: DateTime(to.year, to.month, to.day, 23, 59, 59),
      label: 'Tùy chọn',
    );
  }
}

/// Financial summary for a period
class FinanceSummary {
  final Decimal totalBuy;
  final Decimal totalSell;
  final Decimal totalPos;
  final Decimal profit;
  final int orderCount;
  final int buyCount;
  final int sellCount;
  final int posCount;

  const FinanceSummary({
    required this.totalBuy,
    required this.totalSell,
    required this.totalPos,
    required this.profit,
    required this.orderCount,
    required this.buyCount,
    required this.sellCount,
    required this.posCount,
  });

  Decimal get totalRevenue => totalSell + totalPos;

  static final empty = FinanceSummary(
    totalBuy: Decimal.zero,
    totalSell: Decimal.zero,
    totalPos: Decimal.zero,
    profit: Decimal.zero,
    orderCount: 0,
    buyCount: 0,
    sellCount: 0,
    posCount: 0,
  );
}

/// Single data point for monthly trend chart
class FinanceTrendPoint {
  final String label; // e.g. "T1", "T2"
  final int month;
  final Decimal totalBuy;
  final Decimal totalSell;
  final Decimal totalPos;
  final Decimal profit;

  const FinanceTrendPoint({
    required this.label,
    required this.month,
    required this.totalBuy,
    required this.totalSell,
    required this.totalPos,
    required this.profit,
  });

  Decimal get totalRevenue => totalSell + totalPos;
}

/// Pie chart data — breakdown by type
class FinanceBreakdown {
  final String label;
  final Decimal amount;
  final int count;

  const FinanceBreakdown({
    required this.label,
    required this.amount,
    required this.count,
  });
}

// =============================================
// REPOSITORY
// =============================================

class FinanceRepository {
  final TradeOrderDao _orderDao;

  FinanceRepository(this._orderDao);

  static Decimal _centsToDecimal(int cents) {
    return (Decimal.fromInt(cents) / Decimal.fromInt(100)).toDecimal();
  }

  /// Get financial summary for a date range
  Future<FinanceSummary> getSummary(FinanceDateRange range) async {
    final orders = await _orderDao.getOrdersByDateRange(range.from, range.to);

    Decimal buy = Decimal.zero;
    Decimal sell = Decimal.zero;
    Decimal pos = Decimal.zero;
    int buyCount = 0;
    int sellCount = 0;
    int posCount = 0;

    for (final o in orders) {
      final amount = _centsToDecimal(o.order.subtotalInCents);
      switch (o.order.orderType) {
        case 'buy':
          buy += amount;
          buyCount++;
        case 'sell':
          sell += amount;
          sellCount++;
        case 'pos':
          pos += amount;
          posCount++;
      }
    }

    return FinanceSummary(
      totalBuy: buy,
      totalSell: sell,
      totalPos: pos,
      profit: (sell + pos) - buy,
      orderCount: orders.length,
      buyCount: buyCount,
      sellCount: sellCount,
      posCount: posCount,
    );
  }

  /// Get monthly trend data for a year
  Future<List<FinanceTrendPoint>> getMonthlyTrend(int year) async {
    final from = DateTime(year, 1, 1);
    final to = DateTime(year, 12, 31, 23, 59, 59);
    final orders = await _orderDao.getOrdersByDateRange(from, to);

    return List.generate(12, (i) {
      final month = i + 1;
      Decimal buy = Decimal.zero;
      Decimal sell = Decimal.zero;
      Decimal pos = Decimal.zero;

      for (final o in orders) {
        if (o.order.createdAt.month == month) {
          final amount = _centsToDecimal(o.order.subtotalInCents);
          switch (o.order.orderType) {
            case 'buy':
              buy += amount;
            case 'sell':
              sell += amount;
            case 'pos':
              pos += amount;
          }
        }
      }

      return FinanceTrendPoint(
        label: 'T$month',
        month: month,
        totalBuy: buy,
        totalSell: sell,
        totalPos: pos,
        profit: (sell + pos) - buy,
      );
    });
  }

  /// Get breakdown by order type for pie chart
  Future<List<FinanceBreakdown>> getBreakdown(FinanceDateRange range) async {
    final orders = await _orderDao.getOrdersByDateRange(range.from, range.to);

    Decimal buy = Decimal.zero;
    Decimal sell = Decimal.zero;
    Decimal pos = Decimal.zero;
    int buyCount = 0;
    int sellCount = 0;
    int posCount = 0;

    for (final o in orders) {
      final amount = _centsToDecimal(o.order.subtotalInCents);
      switch (o.order.orderType) {
        case 'buy':
          buy += amount;
          buyCount++;
        case 'sell':
          sell += amount;
          sellCount++;
        case 'pos':
          pos += amount;
          posCount++;
      }
    }

    return [
      if (buy > Decimal.zero)
        FinanceBreakdown(label: 'Mua vào', amount: buy, count: buyCount),
      if (sell > Decimal.zero)
        FinanceBreakdown(label: 'Bán sỉ', amount: sell, count: sellCount),
      if (pos > Decimal.zero)
        FinanceBreakdown(label: 'Bán lẻ (POS)', amount: pos, count: posCount),
    ];
  }

  /// Get filtered orders for transaction list
  Future<List<TradeOrderWithDetails>> getFilteredOrders(
    FinanceDateRange range, {
    String? orderType,
    int limit = 100,
  }) async {
    return _orderDao.getOrdersByDateRange(
      range.from,
      range.to,
      orderType: orderType,
      limit: limit,
    );
  }

  /// Get available years for year picker
  Future<List<int>> getAvailableYears() async {
    final allOrders = await _orderDao.getAllOrders();
    final years =
        allOrders.map((o) => o.createdAt.year).toSet().toList()..sort();
    if (years.isEmpty) years.add(DateTime.now().year);
    return years;
  }
}
