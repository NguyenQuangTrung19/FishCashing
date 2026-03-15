/// Dashboard page — Overview of business metrics with real data.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import 'package:go_router/go_router.dart';

import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/repositories/trade_order_repository.dart';
import 'package:fishcash_pos/data/repositories/trading_session_repository.dart';
import 'package:fishcash_pos/presentation/categories/bloc/category_bloc.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_bloc.dart';
import 'package:fishcash_pos/presentation/partners/bloc/partner_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<TradeOrderWithDetails> _recentOrders = [];
  List<TradingSessionModel> _recentSessions = [];
  int _sessionCount = 0;
  Decimal _totalBuy = Decimal.zero;
  Decimal _totalSell = Decimal.zero;
  Decimal _totalPos = Decimal.zero;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final orderRepo = context.read<TradeOrderRepository>();
      final sessionRepo = context.read<TradingSessionRepository>();

      final orders = await orderRepo.getRecentOrders(limit: 10);
      final sessions = await sessionRepo.getAll();

      Decimal buy = Decimal.zero;
      Decimal sell = Decimal.zero;
      Decimal pos = Decimal.zero;

      for (final o in orders) {
        final amount = (Decimal.fromInt(o.order.subtotalInCents) /
                Decimal.fromInt(100))
            .toDecimal();
        switch (o.order.orderType) {
          case 'buy':
            buy += amount;
          case 'sell':
            sell += amount;
          case 'pos':
            pos += amount;
        }
      }

      if (mounted) {
        setState(() {
          _recentOrders = orders.take(5).toList();
          _recentSessions = sessions.take(5).toList();
          _sessionCount = sessions.length;
          _totalBuy = buy;
          _totalSell = sell;
          _totalPos = pos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSessionPreview(TradingSessionModel session) {
    final isProfit = session.profit >= Decimal.zero;
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
                  Expanded(child: Text(session.note, style: Theme.of(context).textTheme.bodyMedium)),
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
                icon: isProfit ? Icons.trending_up : Icons.trending_down,
                label: 'Lợi nhuận',
                value: AppFormatters.currency(session.profit),
                color: isProfit ? OceanTheme.profitGold : OceanTheme.lossRed,
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
              context.go('/trading');
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Xem chi tiết'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _totalSell + _totalPos;
    final profit = totalRevenue - _totalBuy;
    final isProfit = profit >= Decimal.zero;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    OceanTheme.oceanPrimary,
                    OceanTheme.oceanFoam,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.set_meal, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('FishCash'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
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
                    // Welcome banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            OceanTheme.oceanPrimary,
                            OceanTheme.oceanFoam,
                          ],
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
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  )),
                          const SizedBox(height: 4),
                          Text(
                            'Quản lý cửa hàng hải sản thông minh',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary cards
                    Text('Tổng quan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _SummaryCards(
                      totalBuy: _totalBuy,
                      totalSell: totalRevenue,
                      profit: profit,
                      isProfit: isProfit,
                      sessionCount: _sessionCount,
                    ),
                    const SizedBox(height: 24),

                    // Quick stats
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
                      ..._recentSessions.map((session) {
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
                                    backgroundColor: OceanTheme.oceanPrimary.withValues(alpha: 0.15),
                                    radius: 20,
                                    child: const Icon(Icons.swap_horiz, color: OceanTheme.oceanPrimary, size: 20),
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
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                                            color: isP ? OceanTheme.profitGold : OceanTheme.lossRed),
                                      ),
                                      Text(
                                        isP ? 'Lãi' : 'Lỗ',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: isP ? OceanTheme.profitGold : OceanTheme.lossRed),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
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
                      ..._recentOrders.map((order) {
                        final isBuy = order.order.orderType == 'buy';
                        final isPOS = order.order.orderType == 'pos';
                        final amount = (Decimal.fromInt(
                                    order.order.subtotalInCents) /
                                Decimal.fromInt(100))
                            .toDecimal();

                        final color = isBuy
                            ? OceanTheme.buyBlue
                            : (isPOS
                                ? OceanTheme.oceanPrimary
                                : OceanTheme.sellGreen);
                        final icon = isBuy
                            ? Icons.shopping_cart
                            : (isPOS
                                ? Icons.point_of_sale
                                : Icons.storefront);
                        final label =
                            isBuy ? 'Mua' : (isPOS ? 'POS' : 'Bán');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor:
                                  color.withValues(alpha: 0.15),
                              radius: 18,
                              child: Icon(icon, color: color, size: 18),
                            ),
                            title: Text(
                              '$label${order.partnerName != null ? " - ${order.partnerName}" : ""}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${order.items.length} SP • ${AppFormatters.dateTime(order.order.createdAt)}',
                            ),
                            trailing: Text(
                              AppFormatters.currency(amount),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}

// ============================================
// SECTION HEADER with "Xem tất cả"
// ============================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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

// ============================================
// EMPTY PLACEHOLDER
// ============================================

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
              Icon(icon, size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
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

// ============================================
// PREVIEW METRIC ROW (for session preview dialog)
// ============================================

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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

// ============================================
// SUMMARY CARDS (4 cards)
// ============================================

class _SummaryCards extends StatelessWidget {
  final Decimal totalBuy;
  final Decimal totalSell;
  final Decimal profit;
  final bool isProfit;
  final int sessionCount;

  const _SummaryCards({
    required this.totalBuy,
    required this.totalSell,
    required this.profit,
    required this.isProfit,
    required this.sessionCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        final cards = [
          _DashCard(
            label: 'Tổng mua',
            value: AppFormatters.currency(totalBuy),
            icon: Icons.shopping_cart,
            color: OceanTheme.buyBlue,
          ),
          _DashCard(
            label: 'Tổng bán',
            value: AppFormatters.currency(totalSell),
            icon: Icons.storefront,
            color: OceanTheme.sellGreen,
          ),
          _DashCard(
            label: 'Lợi nhuận',
            value: AppFormatters.currency(profit),
            icon: isProfit ? Icons.trending_up : Icons.trending_down,
            color: isProfit ? OceanTheme.profitGold : OceanTheme.lossRed,
          ),
          _DashCard(
            label: 'Phiên GD',
            value: '$sessionCount phiên',
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
}

/// Dashboard card
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

/// Quick stats: product count, category count, partner count
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

/// Stat chip
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
