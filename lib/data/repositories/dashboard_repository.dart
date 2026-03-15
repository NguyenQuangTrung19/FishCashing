/// Dashboard statistics repository.
///
/// Queries TradingSessions table to build monthly/yearly/all-time stats
/// for chart visualization on the dashboard page.
library;

import 'package:decimal/decimal.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/daos/trading_session_dao.dart';

/// A single data point for charts (one month or one year)
class PeriodStats {
  final String label; // e.g. "T1", "T2", "2024", "2025"
  final Decimal totalBuy;
  final Decimal totalSell;
  final Decimal profit;
  final int sessionCount;

  const PeriodStats({
    required this.label,
    required this.totalBuy,
    required this.totalSell,
    required this.profit,
    required this.sessionCount,
  });

  static PeriodStats zero(String label) => PeriodStats(
        label: label,
        totalBuy: Decimal.zero,
        totalSell: Decimal.zero,
        profit: Decimal.zero,
        sessionCount: 0,
      );
}

/// Summary stats for a period
class DashboardSummary {
  final Decimal totalBuy;
  final Decimal totalSell;
  final Decimal profit;
  final int sessionCount;
  final int orderCount;

  const DashboardSummary({
    required this.totalBuy,
    required this.totalSell,
    required this.profit,
    required this.sessionCount,
    required this.orderCount,
  });

  static final empty = DashboardSummary(
    totalBuy: Decimal.zero,
    totalSell: Decimal.zero,
    profit: Decimal.zero,
    sessionCount: 0,
    orderCount: 0,
  );
}

class DashboardRepository {
  final TradingSessionDao _sessionDao;

  DashboardRepository(this._sessionDao);

  static Decimal _centsToDecimal(int cents) {
    return (Decimal.fromInt(cents) / Decimal.fromInt(100)).toDecimal();
  }

  /// Get monthly stats for a given year (12 data points)
  Future<List<PeriodStats>> getMonthlyStats(int year) async {
    final sessions = await _sessionDao.getAll();

    // Initialize 12 months
    final monthData = List.generate(12, (i) {
      Decimal buy = Decimal.zero;
      Decimal sell = Decimal.zero;
      Decimal profit = Decimal.zero;
      int count = 0;

      for (final s in sessions) {
        if (s.createdAt.year == year && s.createdAt.month == i + 1) {
          buy += _centsToDecimal(s.totalBuyInCents);
          sell += _centsToDecimal(s.totalSellInCents);
          profit += _centsToDecimal(s.profitInCents);
          count++;
        }
      }

      return PeriodStats(
        label: 'T${i + 1}',
        totalBuy: buy,
        totalSell: sell,
        profit: profit,
        sessionCount: count,
      );
    });

    return monthData;
  }

  /// Get yearly stats (one data point per year that has data)
  Future<List<PeriodStats>> getYearlyStats() async {
    final sessions = await _sessionDao.getAll();
    if (sessions.isEmpty) return [];

    // Group by year
    final yearMap = <int, List<TradingSession>>{};
    for (final s in sessions) {
      yearMap.putIfAbsent(s.createdAt.year, () => []).add(s);
    }

    final years = yearMap.keys.toList()..sort();
    return years.map((year) {
      final list = yearMap[year]!;
      Decimal buy = Decimal.zero;
      Decimal sell = Decimal.zero;
      Decimal profit = Decimal.zero;

      for (final s in list) {
        buy += _centsToDecimal(s.totalBuyInCents);
        sell += _centsToDecimal(s.totalSellInCents);
        profit += _centsToDecimal(s.profitInCents);
      }

      return PeriodStats(
        label: '$year',
        totalBuy: buy,
        totalSell: sell,
        profit: profit,
        sessionCount: list.length,
      );
    }).toList();
  }

  /// Get summary for a specific month
  Future<DashboardSummary> getMonthlySummary(int year, int month) async {
    final sessions = await _sessionDao.getAll();
    Decimal buy = Decimal.zero;
    Decimal sell = Decimal.zero;
    Decimal profit = Decimal.zero;
    int sessionCount = 0;
    int orderCount = 0;

    for (final s in sessions) {
      if (s.createdAt.year == year && s.createdAt.month == month) {
        buy += _centsToDecimal(s.totalBuyInCents);
        sell += _centsToDecimal(s.totalSellInCents);
        profit += _centsToDecimal(s.profitInCents);
        sessionCount++;
        orderCount += await _sessionDao.getOrderCount(s.id);
      }
    }

    return DashboardSummary(
      totalBuy: buy,
      totalSell: sell,
      profit: profit,
      sessionCount: sessionCount,
      orderCount: orderCount,
    );
  }

  /// Get summary for a specific year
  Future<DashboardSummary> getYearlySummary(int year) async {
    final sessions = await _sessionDao.getAll();
    Decimal buy = Decimal.zero;
    Decimal sell = Decimal.zero;
    Decimal profit = Decimal.zero;
    int sessionCount = 0;
    int orderCount = 0;

    for (final s in sessions) {
      if (s.createdAt.year == year) {
        buy += _centsToDecimal(s.totalBuyInCents);
        sell += _centsToDecimal(s.totalSellInCents);
        profit += _centsToDecimal(s.profitInCents);
        sessionCount++;
        orderCount += await _sessionDao.getOrderCount(s.id);
      }
    }

    return DashboardSummary(
      totalBuy: buy,
      totalSell: sell,
      profit: profit,
      sessionCount: sessionCount,
      orderCount: orderCount,
    );
  }

  /// Get all-time summary
  Future<DashboardSummary> getAllTimeSummary() async {
    final sessions = await _sessionDao.getAll();
    Decimal buy = Decimal.zero;
    Decimal sell = Decimal.zero;
    Decimal profit = Decimal.zero;
    int orderCount = 0;

    for (final s in sessions) {
      buy += _centsToDecimal(s.totalBuyInCents);
      sell += _centsToDecimal(s.totalSellInCents);
      profit += _centsToDecimal(s.profitInCents);
      orderCount += await _sessionDao.getOrderCount(s.id);
    }

    return DashboardSummary(
      totalBuy: buy,
      totalSell: sell,
      profit: profit,
      sessionCount: sessions.length,
      orderCount: orderCount,
    );
  }

  /// Get available years for the year picker
  Future<List<int>> getAvailableYears() async {
    final sessions = await _sessionDao.getAll();
    final years = sessions.map((s) => s.createdAt.year).toSet().toList()..sort();
    if (years.isEmpty) years.add(DateTime.now().year);
    return years;
  }
}
