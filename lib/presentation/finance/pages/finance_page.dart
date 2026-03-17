/// Finance Page — Full financial analytics with charts & filters.
///
/// Features:
/// - Date range filter (week / month / year / all / custom)
/// - Summary cards (buy, sell, POS, profit)
/// - Pie chart: revenue breakdown by type
/// - Bar chart: monthly buy vs sell comparison
/// - Line chart: monthly profit trend
/// - Transaction list with order type filter
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/repositories/finance_repository.dart';
import 'package:fishcash_pos/presentation/finance/bloc/finance_bloc.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tài chính'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => context
                    .read<FinanceBloc>()
                    .add(const FinanceLoadRequested()),
              ),
            ],
          ),
          body: state.status == FinanceStatus.loading &&
                  state.summary == FinanceSummary.empty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async => context
                      .read<FinanceBloc>()
                      .add(const FinanceLoadRequested()),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header banner
                        _buildHeaderBanner(context, state),
                        const SizedBox(height: 16),

                        // Date range filter
                        _DateRangeFilter(
                          currentRange: state.dateRange,
                          onChanged: (range) => context
                              .read<FinanceBloc>()
                              .add(FinanceDateRangeChanged(range)),
                        ),
                        const SizedBox(height: 16),

                        // Loading overlay for data changes
                        if (state.status == FinanceStatus.loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(),
                          ),

                        // Summary cards
                        _SummaryCards(summary: state.summary),
                        const SizedBox(height: 24),

                        // Charts row (pie + bar)
                        if (state.breakdown.isNotEmpty ||
                            state.trendData.isNotEmpty) ...[
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 800) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (state.breakdown.isNotEmpty)
                                      Expanded(
                                        child: _PieChartCard(
                                            breakdown: state.breakdown),
                                      ),
                                    if (state.breakdown.isNotEmpty &&
                                        state.trendData.isNotEmpty)
                                      const SizedBox(width: 16),
                                    if (state.trendData.isNotEmpty)
                                      Expanded(
                                        child: _BarChartCard(
                                          data: state.trendData,
                                          year: state.trendYear,
                                          years: state.availableYears,
                                          onYearChanged: (y) => context
                                              .read<FinanceBloc>()
                                              .add(
                                                  FinanceTrendYearChanged(y)),
                                        ),
                                      ),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  if (state.breakdown.isNotEmpty)
                                    _PieChartCard(
                                        breakdown: state.breakdown),
                                  if (state.breakdown.isNotEmpty)
                                    const SizedBox(height: 16),
                                  if (state.trendData.isNotEmpty)
                                    _BarChartCard(
                                      data: state.trendData,
                                      year: state.trendYear,
                                      years: state.availableYears,
                                      onYearChanged: (y) => context
                                          .read<FinanceBloc>()
                                          .add(FinanceTrendYearChanged(y)),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Profit trend line chart
                        if (state.trendData.isNotEmpty) ...[
                          _ProfitLineChartCard(
                            data: state.trendData,
                            year: state.trendYear,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Transaction list
                        _TransactionSection(
                          orders: state.orders,
                          filterType: state.orderTypeFilter,
                          onFilterChanged: (type) => context
                              .read<FinanceBloc>()
                              .add(FinanceOrderTypeChanged(type)),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderBanner(BuildContext context, FinanceState state) {
    final isProfit = state.summary.profit >= Decimal.zero;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [OceanTheme.oceanDeep, OceanTheme.oceanPrimary]
              : [const Color(0xFF8B1A1A), const Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? OceanTheme.oceanPrimary : OceanTheme.lossRed)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isProfit ? Icons.trending_up : Icons.trending_down,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isProfit ? 'Lợi nhuận' : 'Lỗ ròng',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.currency(state.summary.profit.abs()),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.dateRange.label} • ${state.summary.orderCount} đơn hàng',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// DATE RANGE FILTER
// =============================================

class _DateRangeFilter extends StatelessWidget {
  final FinanceDateRange currentRange;
  final ValueChanged<FinanceDateRange> onChanged;

  const _DateRangeFilter({
    required this.currentRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Tuần này',
            selected: currentRange.label == 'Tuần này',
            onTap: () => onChanged(FinanceDateRange.thisWeek()),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Tháng này',
            selected: currentRange.label == 'Tháng này',
            onTap: () => onChanged(FinanceDateRange.thisMonth()),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Năm ${DateTime.now().year}',
            selected: currentRange.label == 'Năm ${DateTime.now().year}',
            onTap: () => onChanged(FinanceDateRange.thisYear()),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Tất cả',
            selected: currentRange.label == 'Tất cả',
            onTap: () => onChanged(FinanceDateRange.allTime()),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            icon: Icons.date_range,
            label: currentRange.label == 'Tùy chọn'
                ? '${_fmt(currentRange.from)} → ${_fmt(currentRange.to)}'
                : 'Tùy chọn',
            selected: currentRange.label == 'Tùy chọn',
            onTap: () => _pickCustomRange(context),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}';

  Future<void> _pickCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: currentRange.from,
        end: currentRange.to,
      ),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: OceanTheme.oceanPrimary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onChanged(FinanceDateRange.custom(picked.start, picked.end));
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? OceanTheme.oceanPrimary
          : Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16,
                    color: selected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================
// SUMMARY CARDS
// =============================================

class _SummaryCards extends StatelessWidget {
  final FinanceSummary summary;

  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isProfit = summary.profit >= Decimal.zero;

    final cards = [
      _SummaryCardData(
        label: 'Tổng chi (Mua)',
        value: AppFormatters.currency(summary.totalBuy),
        count: '${summary.buyCount} đơn',
        icon: Icons.shopping_cart,
        color: OceanTheme.buyBlue,
      ),
      _SummaryCardData(
        label: 'Bán sỉ',
        value: AppFormatters.currency(summary.totalSell),
        count: '${summary.sellCount} đơn',
        icon: Icons.storefront,
        color: OceanTheme.sellGreen,
      ),
      _SummaryCardData(
        label: 'Bán lẻ (POS)',
        value: AppFormatters.currency(summary.totalPos),
        count: '${summary.posCount} đơn',
        icon: Icons.point_of_sale,
        color: OceanTheme.oceanPrimary,
      ),
      _SummaryCardData(
        label: 'Lợi nhuận',
        value: AppFormatters.currency(summary.profit),
        count: '${summary.orderCount} đơn tổng',
        icon: isProfit ? Icons.trending_up : Icons.trending_down,
        color: isProfit ? OceanTheme.profitGold : OceanTheme.lossRed,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            children: cards
                .map((c) => Expanded(child: _SummaryCard(data: c)))
                .expand((w) => [w, const SizedBox(width: 10)])
                .toList()
              ..removeLast(),
          );
        }
        return Column(
          children: [
            Row(children: [
              Expanded(child: _SummaryCard(data: cards[0])),
              const SizedBox(width: 10),
              Expanded(child: _SummaryCard(data: cards[1])),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _SummaryCard(data: cards[2])),
              const SizedBox(width: 10),
              Expanded(child: _SummaryCard(data: cards[3])),
            ]),
          ],
        );
      },
    );
  }
}

class _SummaryCardData {
  final String label;
  final String value;
  final String count;
  final IconData icon;
  final Color color;
  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.count,
    required this.icon,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon, color: data.color, size: 18),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(data.label,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: data.color),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: data.color,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              data.count,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================
// PIE CHART — Revenue Breakdown
// =============================================

class _PieChartCard extends StatelessWidget {
  final List<FinanceBreakdown> breakdown;

  const _PieChartCard({required this.breakdown});

  static const _colors = [
    OceanTheme.buyBlue,
    OceanTheme.sellGreen,
    OceanTheme.oceanPrimary,
  ];

  @override
  Widget build(BuildContext context) {
    final total = breakdown.fold(
        Decimal.zero, (sum, b) => sum + b.amount);

    return _ChartContainer(
      title: 'Phân loại giao dịch',
      icon: Icons.pie_chart_outline,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 3,
                sections: breakdown.asMap().entries.map((e) {
                  final pct = total > Decimal.zero
                      ? (e.value.amount / total)
                              .toDecimal(scaleOnInfinitePrecision: 4) *
                          Decimal.fromInt(100)
                      : Decimal.zero;
                  return PieChartSectionData(
                    color: _colors[e.key % _colors.length],
                    value: e.value.amount.toDouble(),
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 55,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          ...breakdown.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _colors[e.key % _colors.length],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${e.value.label} (${e.value.count} đơn)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    AppFormatters.currency(e.value.amount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _colors[e.key % _colors.length],
                        ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================
// BAR CHART — Monthly Buy vs Sell
// =============================================

class _BarChartCard extends StatelessWidget {
  final List<FinanceTrendPoint> data;
  final int year;
  final List<int> years;
  final ValueChanged<int> onYearChanged;

  const _BarChartCard({
    required this.data,
    required this.year,
    required this.years,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    double maxVal = 0;
    for (final d in data) {
      final buyVal = d.totalBuy.toDouble();
      final sellVal = d.totalRevenue.toDouble();
      if (buyVal > maxVal) maxVal = buyVal;
      if (sellVal > maxVal) maxVal = sellVal;
    }
    maxVal = maxVal * 1.2;
    if (maxVal == 0) maxVal = 1000;

    return _ChartContainer(
      title: 'Mua vào vs Doanh thu',
      icon: Icons.bar_chart,
      trailing: _YearDropdown(
          year: year, years: years, onChanged: onYearChanged),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupI, rod, rodI) {
                      final d = data[groupI];
                      final label = rodI == 0 ? 'Chi mua' : 'Doanh thu';
                      final value =
                          rodI == 0 ? d.totalBuy : d.totalRevenue;
                      return BarTooltipItem(
                        '${d.label}\n$label: ${AppFormatters.currency(value)}',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(data[idx].label,
                              style: const TextStyle(fontSize: 10)),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _shortCurrency(value),
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: data.asMap().entries.map((e) {
                  final d = e.value;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: d.totalBuy.toDouble(),
                        color: OceanTheme.buyBlue,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: d.totalRevenue.toDouble(),
                        color: OceanTheme.sellGreen,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: OceanTheme.buyBlue, label: 'Chi mua'),
              const SizedBox(width: 20),
              _LegendDot(color: OceanTheme.sellGreen, label: 'Doanh thu'),
            ],
          ),
        ],
      ),
    );
  }

  static String _shortCurrency(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// =============================================
// LINE CHART — Profit Trend
// =============================================

class _ProfitLineChartCard extends StatelessWidget {
  final List<FinanceTrendPoint> data;
  final int year;

  const _ProfitLineChartCard({required this.data, required this.year});

  @override
  Widget build(BuildContext context) {
    final hasData = data.any((d) => d.profit != Decimal.zero);
    if (!hasData) return const SizedBox.shrink();

    double maxVal = 0;
    double minVal = 0;
    for (final d in data) {
      final v = d.profit.toDouble();
      if (v > maxVal) maxVal = v;
      if (v < minVal) minVal = v;
    }
    maxVal = maxVal * 1.2;
    minVal = minVal * 1.2;
    if (maxVal == 0 && minVal == 0) maxVal = 1000;

    return _ChartContainer(
      title: 'Xu hướng lợi nhuận',
      icon: Icons.show_chart,
      subtitle: 'Năm $year',
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: minVal,
            maxY: maxVal,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    final d = data[spot.x.toInt()];
                    return LineTooltipItem(
                      '${d.label}: ${AppFormatters.currency(d.profit)}',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    );
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) return const Text('');
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(data[idx].label,
                          style: const TextStyle(fontSize: 10)),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _BarChartCard._shortCurrency(value),
                      style: TextStyle(
                        fontSize: 9,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withValues(alpha: 0.15),
                strokeWidth: 1,
              ),
            ),
            lineBarsData: [
              // Zero line reference
              LineChartBarData(
                spots: List.generate(
                    data.length, (i) => FlSpot(i.toDouble(), 0)),
                isCurved: false,
                color: Colors.grey.withValues(alpha: 0.3),
                dotData: const FlDotData(show: false),
                barWidth: 1,
                dashArray: [4, 4],
              ),
              // Profit line
              LineChartBarData(
                spots: data.asMap().entries.map((e) {
                  return FlSpot(
                      e.key.toDouble(), e.value.profit.toDouble());
                }).toList(),
                isCurved: true,
                curveSmoothness: 0.25,
                color: OceanTheme.profitGold,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final isPos = spot.y >= 0;
                    return FlDotCirclePainter(
                      radius: 4,
                      color: isPos ? OceanTheme.profitGold : OceanTheme.lossRed,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      OceanTheme.profitGold.withValues(alpha: 0.2),
                      OceanTheme.profitGold.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================
// TRANSACTION LIST
// =============================================

class _TransactionSection extends StatelessWidget {
  final List<TradeOrderWithDetails> orders;
  final String? filterType;
  final ValueChanged<String?> onFilterChanged;

  const _TransactionSection({
    required this.orders,
    required this.filterType,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long, size: 20),
            const SizedBox(width: 8),
            Text('Danh sách giao dịch',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${orders.length} đơn',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        // Order type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Tất cả',
                selected: filterType == null,
                onTap: () => onFilterChanged(null),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: '🔴 Mua',
                selected: filterType == 'buy',
                onTap: () => onFilterChanged('buy'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: '🟢 Bán sỉ',
                selected: filterType == 'sell',
                onTap: () => onFilterChanged('sell'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: '🔵 POS',
                selected: filterType == 'pos',
                onTap: () => onFilterChanged('pos'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 48,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Text('Không có giao dịch nào trong khoảng thời gian này',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            )),
                  ],
                ),
              ),
            ),
          )
        else
          ...orders.map((order) => _TransactionTile(order: order)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TradeOrderWithDetails order;
  const _TransactionTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final isBuy = order.order.orderType == 'buy';
    final isPOS = order.order.orderType == 'pos';
    final amount =
        (Decimal.fromInt(order.order.subtotalInCents) / Decimal.fromInt(100))
            .toDecimal();

    final color = isBuy
        ? OceanTheme.buyBlue
        : (isPOS ? OceanTheme.oceanPrimary : OceanTheme.sellGreen);
    final icon = isBuy
        ? Icons.shopping_cart
        : (isPOS ? Icons.point_of_sale : Icons.storefront);
    final typeLabel = isBuy ? 'Mua' : (isPOS ? 'POS' : 'Bán');

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          radius: 18,
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          '$typeLabel${order.partnerName != null ? " - ${order.partnerName}" : ""}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          '${order.items.length} SP • ${AppFormatters.dateTime(order.order.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '${isBuy ? "-" : "+"}${AppFormatters.currency(amount)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ),
    );
  }
}

// =============================================
// SHARED WIDGETS
// =============================================

class _ChartContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const _ChartContainer({
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [OceanTheme.oceanPrimary, OceanTheme.oceanFoam],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                  ],
                ),
              ),
              if (trailing case final t?) t,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _YearDropdown extends StatelessWidget {
  final int year;
  final List<int> years;
  final ValueChanged<int> onChanged;

  const _YearDropdown({
    required this.year,
    required this.years,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (years.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<int>(
        value: years.contains(year) ? year : years.last,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(10),
        isDense: true,
        items: years.map((y) {
          return DropdownMenuItem(
            value: y,
            child: Text('$y',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          );
        }).toList(),
        onChanged: (y) {
          if (y != null) onChanged(y);
        },
      ),
    );
  }
}
