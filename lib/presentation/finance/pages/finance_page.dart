/// Finance Page — Income/Expense tracking.
library;

import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/repositories/trade_order_repository.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  List<TradeOrderWithDetails> _recentOrders = [];
  bool _loading = true;
  Decimal _totalBuy = Decimal.zero;
  Decimal _totalSell = Decimal.zero;
  Decimal _totalPos = Decimal.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final repo = context.read<TradeOrderRepository>();
      final orders = await repo.getRecentOrders(limit: 50);

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
          _recentOrders = orders;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài chính'),
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
                    // Summary cards
                    _FinanceSummary(
                      totalBuy: _totalBuy,
                      totalSell: _totalSell,
                      totalPos: _totalPos,
                    ),
                    const SizedBox(height: 24),

                    // Revenue breakdown
                    Text('Doanh thu theo loại',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                    const SizedBox(height: 12),
                    _RevenueBreakdown(
                      totalSell: _totalSell,
                      totalPos: _totalPos,
                      totalBuy: _totalBuy,
                    ),
                    const SizedBox(height: 24),

                    // Recent transactions
                    Row(
                      children: [
                        Text('Giao dịch gần đây',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('${_recentOrders.length} đơn',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_recentOrders.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text('Chưa có giao dịch nào',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    )),
                          ),
                        ),
                      )
                    else
                      ..._recentOrders.map((order) {
                        return _TransactionTile(order: order);
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Summary cards for Finance
class _FinanceSummary extends StatelessWidget {
  final Decimal totalBuy;
  final Decimal totalSell;
  final Decimal totalPos;

  const _FinanceSummary({
    required this.totalBuy,
    required this.totalSell,
    required this.totalPos,
  });

  @override
  Widget build(BuildContext context) {
    final totalRevenue = totalSell + totalPos;
    final profit = totalRevenue - totalBuy;
    final isProfit = profit >= Decimal.zero;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Row(
            children: [
              _FlexCard(
                label: 'Tổng chi (Mua)',
                value: AppFormatters.currency(totalBuy),
                icon: Icons.shopping_cart,
                color: OceanTheme.buyBlue,
              ),
              const SizedBox(width: 12),
              _FlexCard(
                label: 'Bán sỉ',
                value: AppFormatters.currency(totalSell),
                icon: Icons.storefront,
                color: OceanTheme.sellGreen,
              ),
              const SizedBox(width: 12),
              _FlexCard(
                label: 'Bán lẻ (POS)',
                value: AppFormatters.currency(totalPos),
                icon: Icons.point_of_sale,
                color: OceanTheme.oceanPrimary,
              ),
              const SizedBox(width: 12),
              _FlexCard(
                label: 'Lợi nhuận',
                value: AppFormatters.currency(profit),
                icon: isProfit ? Icons.trending_up : Icons.trending_down,
                color: isProfit ? OceanTheme.profitGold : OceanTheme.lossRed,
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                _FlexCard(
                  label: 'Tổng chi (Mua)',
                  value: AppFormatters.currency(totalBuy),
                  icon: Icons.shopping_cart,
                  color: OceanTheme.buyBlue,
                ),
                const SizedBox(width: 12),
                _FlexCard(
                  label: 'Bán sỉ',
                  value: AppFormatters.currency(totalSell),
                  icon: Icons.storefront,
                  color: OceanTheme.sellGreen,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _FlexCard(
                  label: 'Bán lẻ (POS)',
                  value: AppFormatters.currency(totalPos),
                  icon: Icons.point_of_sale,
                  color: OceanTheme.oceanPrimary,
                ),
                const SizedBox(width: 12),
                _FlexCard(
                  label: 'Lợi nhuận',
                  value: AppFormatters.currency(profit),
                  icon: isProfit ? Icons.trending_up : Icons.trending_down,
                  color: isProfit ? OceanTheme.profitGold : OceanTheme.lossRed,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Flex card for summary
class _FlexCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _FlexCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
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
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: color),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
      ),
    );
  }
}

/// Revenue breakdown bar visualization
class _RevenueBreakdown extends StatelessWidget {
  final Decimal totalSell;
  final Decimal totalPos;
  final Decimal totalBuy;

  const _RevenueBreakdown({
    required this.totalSell,
    required this.totalPos,
    required this.totalBuy,
  });

  @override
  Widget build(BuildContext context) {
    final totalRevenue = totalSell + totalPos;
    final sellFraction = totalRevenue > Decimal.zero
        ? (totalSell / totalRevenue).toDecimal()
        : Decimal.zero;
    final posFraction = totalRevenue > Decimal.zero
        ? (totalPos / totalRevenue).toDecimal()
        : Decimal.zero;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: [
                    if (totalRevenue > Decimal.zero) ...[
                      Flexible(
                        flex: (sellFraction.toBigInt().toInt() == 0)
                            ? (sellFraction * Decimal.fromInt(100)).toBigInt().toInt().clamp(1, 99)
                            : 50,
                        child: Container(color: OceanTheme.sellGreen),
                      ),
                      Flexible(
                        flex: (posFraction.toBigInt().toInt() == 0)
                            ? (posFraction * Decimal.fromInt(100)).toBigInt().toInt().clamp(1, 99)
                            : 50,
                        child: Container(color: OceanTheme.oceanPrimary),
                      ),
                    ] else
                      Expanded(
                        child: Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: OceanTheme.sellGreen, label: 'Bán sỉ'),
                const SizedBox(width: 24),
                _LegendDot(color: OceanTheme.oceanPrimary, label: 'Bán lẻ'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Legend dot
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

/// Transaction list tile
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
      margin: const EdgeInsets.only(bottom: 6),
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
