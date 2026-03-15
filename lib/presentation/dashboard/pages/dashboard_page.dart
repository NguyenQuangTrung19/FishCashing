/// Dashboard page — Business overview with interactive charts.
///
/// Features:
/// - Period selector: Month / Year / All-time
/// - Bar chart: Buy vs Sell comparison
/// - Line chart: Profit trend
/// - Hover tooltips with exact VND values
/// - Summary cards, recent sessions & orders
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:fishcash_pos/presentation/shared/animated_refresh_button.dart';

import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/repositories/dashboard_repository.dart';
import 'package:fishcash_pos/data/repositories/trade_order_repository.dart';
import 'package:fishcash_pos/data/repositories/trading_session_repository.dart';
import 'package:fishcash_pos/presentation/categories/bloc/category_bloc.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_bloc.dart';
import 'package:fishcash_pos/presentation/partners/bloc/partner_bloc.dart';

// Period modes
enum _PeriodMode { month, year, allTime }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Data
  List<TradeOrderWithDetails> _recentOrders = [];
  List<TradingSessionModel> _recentSessions = [];
  DashboardSummary _summary = DashboardSummary.empty;
  List<PeriodStats> _chartData = [];
  bool _loading = true;

  // Period controls
  _PeriodMode _periodMode = _PeriodMode.month;
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [DateTime.now().year];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final dashRepo = context.read<DashboardRepository>();
      final orderRepo = context.read<TradeOrderRepository>();
      final sessionRepo = context.read<TradingSessionRepository>();

      // Load available years
      _availableYears = await dashRepo.getAvailableYears();
      if (!_availableYears.contains(_selectedYear)) {
        _selectedYear = _availableYears.isNotEmpty
            ? _availableYears.last
            : DateTime.now().year;
      }

      // Recent data
      final orders = await orderRepo.getRecentOrders(limit: 5);
      final sessions = await sessionRepo.getAll();

      // Stats based on period
      await _loadPeriodData(dashRepo);

      if (mounted) {
        setState(() {
          _recentOrders = orders;
          _recentSessions = sessions.take(5).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPeriodData(DashboardRepository dashRepo) async {
    switch (_periodMode) {
      case _PeriodMode.month:
        _chartData = await dashRepo.getMonthlyStats(_selectedYear);
        _summary = await dashRepo.getYearlySummary(_selectedYear);
      case _PeriodMode.year:
        _chartData = await dashRepo.getYearlyStats();
        _summary = await dashRepo.getAllTimeSummary();
      case _PeriodMode.allTime:
        _chartData = await dashRepo.getYearlyStats();
        _summary = await dashRepo.getAllTimeSummary();
    }
  }

  Future<void> _changePeriod(_PeriodMode mode) async {
    if (mode == _periodMode) return;
    setState(() {
      _periodMode = mode;
      _loading = true;
    });
    final dashRepo = context.read<DashboardRepository>();
    await _loadPeriodData(dashRepo);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _changeYear(int year) async {
    if (year == _selectedYear) return;
    setState(() {
      _selectedYear = year;
      _loading = true;
    });
    final dashRepo = context.read<DashboardRepository>();
    await _loadPeriodData(dashRepo);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isProfit = _summary.profit >= Decimal.zero;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [OceanTheme.oceanPrimary, OceanTheme.oceanFoam],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.set_meal, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('FishCash'),
          ],
        ),
        actions: [
          AnimatedRefreshButton(onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ====== WELCOME BANNER ======
                    _buildWelcomeBanner(),
                    const SizedBox(height: 20),

                    // ====== PERIOD SELECTOR ======
                    _buildPeriodSelector(cs),
                    const SizedBox(height: 16),

                    // ====== SUMMARY CARDS ======
                    _buildSummaryCards(isProfit),
                    const SizedBox(height: 24),

                    // ====== BAR CHART: Mua vs Bán ======
                    if (_chartData.isNotEmpty) ...[
                      _buildChartSection(
                        title: 'Mua vào vs Bán ra',
                        subtitle: _periodSubtitle(),
                        child: SizedBox(
                          height: 260,
                          child: _BuySellBarChart(data: _chartData),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ====== LINE CHART: Lợi nhuận ======
                      _buildChartSection(
                        title: 'Xu hướng lợi nhuận',
                        subtitle: _periodSubtitle(),
                        child: SizedBox(
                          height: 220,
                          child: _ProfitLineChart(data: _chartData),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ====== QUICK STATS ======
                    Text('Thống kê nhanh',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _QuickStats(context: context),
                    const SizedBox(height: 24),

                    // ====== RECENT SESSIONS ======
                    _SectionHeader(
                      title: 'Phiên giao dịch gần đây',
                      onViewAll: () => context.go('/trading'),
                    ),
                    const SizedBox(height: 8),
                    if (_recentSessions.isEmpty)
                      _EmptyPlaceholder(
                        icon: Icons.swap_horiz,
                        message: 'Chưa có phiên giao dịch',
                      )
                    else
                      ..._recentSessions.map(_buildSessionCard),
                    const SizedBox(height: 24),

                    // ====== RECENT ORDERS ======
                    _SectionHeader(
                      title: 'Đơn hàng gần đây',
                      onViewAll: () => context.go('/trading'),
                    ),
                    const SizedBox(height: 8),
                    if (_recentOrders.isEmpty)
                      _EmptyPlaceholder(
                        icon: Icons.receipt_long_outlined,
                        message: 'Chưa có đơn hàng nào',
                      )
                    else
                      ..._recentOrders.map(_buildOrderCard),
                  ],
                ),
              ),
            ),
    );
  }

  // =============================================
  // WELCOME BANNER
  // =============================================

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [OceanTheme.oceanPrimary, OceanTheme.oceanFoam],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: OceanTheme.oceanPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Xin chào! 🐟',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 4),
          Text(
            'Quản lý cửa hàng hải sản thông minh',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  // =============================================
  // PERIOD SELECTOR
  // =============================================

  Widget _buildPeriodSelector(ColorScheme cs) {
    return Row(
      children: [
        // Mode selector
        Expanded(
          child: SegmentedButton<_PeriodMode>(
            segments: const [
              ButtonSegment(
                value: _PeriodMode.month,
                label: Text('Theo tháng'),
                icon: Icon(Icons.calendar_month, size: 16),
              ),
              ButtonSegment(
                value: _PeriodMode.year,
                label: Text('Theo năm'),
                icon: Icon(Icons.date_range, size: 16),
              ),
              ButtonSegment(
                value: _PeriodMode.allTime,
                label: Text('Tổng'),
                icon: Icon(Icons.all_inclusive, size: 16),
              ),
            ],
            selected: {_periodMode},
            onSelectionChanged: (v) => _changePeriod(v.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: OceanTheme.oceanPrimary,
              selectedForegroundColor: Colors.white,
            ),
          ),
        ),

        // Year picker (only for "month" mode)
        if (_periodMode == _PeriodMode.month) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<int>(
              value: _selectedYear,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: _availableYears.map((y) {
                return DropdownMenuItem(
                  value: y,
                  child: Text('$y',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }).toList(),
              onChanged: (y) {
                if (y != null) _changeYear(y);
              },
            ),
          ),
        ],
      ],
    );
  }

  String _periodSubtitle() {
    switch (_periodMode) {
      case _PeriodMode.month:
        return 'Năm $_selectedYear';
      case _PeriodMode.year:
        return 'Tất cả các năm';
      case _PeriodMode.allTime:
        return 'Từ trước đến nay';
    }
  }

  // =============================================
  // SUMMARY CARDS
  // =============================================

  Widget _buildSummaryCards(bool isProfit) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        final cards = [
          _DashCard(
            label: 'Tổng mua',
            value: AppFormatters.currency(_summary.totalBuy),
            icon: Icons.shopping_cart,
            color: OceanTheme.buyBlue,
          ),
          _DashCard(
            label: 'Tổng bán',
            value: AppFormatters.currency(_summary.totalSell),
            icon: Icons.storefront,
            color: OceanTheme.sellGreen,
          ),
          _DashCard(
            label: 'Lợi nhuận',
            value: AppFormatters.currency(_summary.profit),
            icon: isProfit ? Icons.trending_up : Icons.trending_down,
            color: isProfit ? OceanTheme.profitGold : OceanTheme.lossRed,
          ),
          _DashCard(
            label: 'Phiên GD',
            value: '${_summary.sessionCount} phiên',
            icon: Icons.swap_horiz,
            color: OceanTheme.oceanPrimary,
          ),
        ];

        if (isWide) {
          return Row(
            children: cards
                .map((c) => Expanded(child: c))
                .expand((w) => [w, const SizedBox(width: 12)])
                .toList()
              ..removeLast(),
          );
        }

        return Column(
          children: [
            Row(children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ]),
          ],
        );
      },
    );
  }

  // =============================================
  // CHART SECTION WRAPPER
  // =============================================

  Widget _buildChartSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700)),
                    Text(subtitle,
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
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // =============================================
  // SESSION & ORDER CARDS
  // =============================================

  void _showSessionPreview(TradingSessionModel session) {
    final isP = session.profit >= Decimal.zero;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: OceanTheme.oceanPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Phiên ${AppFormatters.dateTime(session.createdAt)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (session.note.isNotEmpty) ...[
                Row(children: [
                  const Icon(Icons.note_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(session.note,
                          style: Theme.of(context).textTheme.bodyMedium)),
                ]),
                const SizedBox(height: 12),
              ],
              _PreviewMetric(
                icon: Icons.shopping_cart,
                label: 'Tổng mua vào',
                value: AppFormatters.currency(session.totalBuy),
                color: OceanTheme.buyBlue,
              ),
              const SizedBox(height: 8),
              _PreviewMetric(
                icon: Icons.storefront,
                label: 'Tổng bán ra',
                value: AppFormatters.currency(session.totalSell),
                color: OceanTheme.sellGreen,
              ),
              const SizedBox(height: 8),
              _PreviewMetric(
                icon: isP ? Icons.trending_up : Icons.trending_down,
                label: 'Lợi nhuận',
                value: AppFormatters.currency(session.profit),
                color: isP ? OceanTheme.profitGold : OceanTheme.lossRed,
              ),
              const SizedBox(height: 8),
              _PreviewMetric(
                icon: Icons.receipt_long,
                label: 'Số đơn hàng',
                value: '${session.orderCount} đơn',
                color: OceanTheme.oceanPrimary,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/trading?sessionId=${session.id}');
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Xem chi tiết'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(TradingSessionModel session) {
    final isP = session.profit >= Decimal.zero;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSessionPreview(session),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    OceanTheme.oceanPrimary.withValues(alpha: 0.15),
                radius: 20,
                child: const Icon(Icons.swap_horiz,
                    color: OceanTheme.oceanPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.note.isEmpty
                          ? 'Phiên ${AppFormatters.dateTime(session.createdAt)}'
                          : session.note,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.orderCount} đơn • ${AppFormatters.dateTime(session.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.currency(session.profit),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            isP ? OceanTheme.profitGold : OceanTheme.lossRed),
                  ),
                  Text(
                    isP ? 'Lãi' : 'Lỗ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            isP ? OceanTheme.profitGold : OceanTheme.lossRed),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(TradeOrderWithDetails order) {
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
    final label = isBuy ? 'Mua' : (isPOS ? 'POS' : 'Bán');

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          radius: 18,
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          '$label${order.partnerName != null ? " - ${order.partnerName}" : ""}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          '${order.items.length} SP • ${AppFormatters.dateTime(order.order.createdAt)}',
        ),
        trailing: Text(
          AppFormatters.currency(amount),
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
// BAR CHART: Buy vs Sell
// =============================================

class _BuySellBarChart extends StatelessWidget {
  final List<PeriodStats> data;

  const _BuySellBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    double maxVal = 0;
    for (final d in data) {
      final buyVal = d.totalBuy.toDouble();
      final sellVal = d.totalSell.toDouble();
      if (buyVal > maxVal) maxVal = buyVal;
      if (sellVal > maxVal) maxVal = sellVal;
    }
    // Add 20% headroom
    maxVal = maxVal * 1.2;
    if (maxVal == 0) maxVal = 1000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = data[groupIndex];
              final label = rodIndex == 0 ? 'Mua' : 'Bán';
              final value = rodIndex == 0 ? d.totalBuy : d.totalSell;
              return BarTooltipItem(
                '${d.label}\n$label: ${AppFormatters.currency(value)}',
                TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
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
                  child: Text(
                    data[idx].label,
                    style: const TextStyle(fontSize: 10),
                  ),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          final idx = e.key;
          final d = e.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: d.totalBuy.toDouble(),
                color: OceanTheme.buyBlue,
                width: 10,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: d.totalSell.toDouble(),
                color: OceanTheme.sellGreen,
                width: 10,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static String _shortCurrency(double value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}tỷ';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}tr';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }
}

// =============================================
// LINE CHART: Profit Trend
// =============================================

class _ProfitLineChart extends StatelessWidget {
  final List<PeriodStats> data;

  const _ProfitLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.profit.toDouble());
    }).toList();

    double minY = 0;
    double maxY = 0;
    for (final s in spots) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }
    // Add headroom
    final range = maxY - minY;
    if (range == 0) {
      minY = -1000;
      maxY = 1000;
    } else {
      minY -= range * 0.1;
      maxY += range * 0.2;
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipMargin: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final d = data[spot.spotIndex];
                return LineTooltipItem(
                  '${d.label}\nLợi nhuận: ${AppFormatters.currency(d.profit)}',
                  TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
                  _BuySellBarChart._shortCurrency(value),
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: OceanTheme.profitGold,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isProfit = spot.y >= 0;
                return FlDotCirclePainter(
                  radius: 4,
                  color: isProfit ? OceanTheme.profitGold : OceanTheme.lossRed,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  OceanTheme.profitGold.withValues(alpha: 0.3),
                  OceanTheme.profitGold.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: Colors.grey.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray: [5, 3],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================
// SHARED WIDGETS (kept from original)
// =============================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Xem tất cả'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyPlaceholder({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(icon,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4)),
              const SizedBox(height: 8),
              Text(message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PreviewMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DashCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final BuildContext context;

  const _QuickStats({required this.context});

  @override
  Widget build(BuildContext innerContext) {
    final categoryCount =
        innerContext.watch<CategoryBloc>().state.categories.length;
    final productCount =
        innerContext.watch<ProductBloc>().state.products.length;
    final partnerCount =
        innerContext.watch<PartnerBloc>().state.partners.length;

    return Row(
      children: [
        _StatChip(
          icon: Icons.category,
          label: 'Danh mục',
          value: '$categoryCount',
          color: Colors.indigo,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.inventory_2,
          label: 'Sản phẩm',
          value: '$productCount',
          color: Colors.teal,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.people,
          label: 'Đối tác',
          value: '$partnerCount',
          color: Colors.deepOrange,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                fontWeight: FontWeight.w800, color: color)),
                    Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: color),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
