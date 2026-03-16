/// Inventory page — Stock management overview.
///
/// Shows all products with buy/sell/stock quantities,
/// color-coded status indicators, search/filter, time period selector,
/// and a stock reset button per product.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';

import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/data/repositories/inventory_repository.dart';
import 'package:fishcash_pos/presentation/categories/bloc/category_bloc.dart';
import 'package:fishcash_pos/presentation/inventory/bloc/inventory_bloc.dart';
import 'package:fishcash_pos/presentation/shared/animated_refresh_button.dart';
import 'package:fishcash_pos/presentation/shared/widgets/search_filter_bar.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _searchQuery = '';
  String _categoryFilter = 'all';
  String _statusFilter = 'all'; // all, sufficient, low, empty, negative

  List<InventoryItem> _applyFilters(List<InventoryItem> items) {
    var filtered = items;

    // Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((i) => i.productName.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Category
    if (_categoryFilter != 'all') {
      filtered =
          filtered.where((i) => i.categoryId == _categoryFilter).toList();
    }

    // Status
    if (_statusFilter != 'all') {
      if (_statusFilter == 'negative') {
        // Combine empty + negative
        filtered = filtered
            .where((i) =>
                i.status == StockStatus.empty ||
                i.status == StockStatus.negative)
            .toList();
      } else {
        final targetStatus = StockStatus.values.firstWhere(
          (s) => s.name == _statusFilter,
          orElse: () => StockStatus.sufficient,
        );
        filtered = filtered.where((i) => i.status == targetStatus).toList();
      }
    }

    return filtered;
  }

  void _showResetDialog(InventoryItem item) {
    final reasonController = TextEditingController(text: 'Làm mới kho');
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.restart_alt, color: Colors.orange, size: 40),
        title: const Text('Làm mới kho'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.orange.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.orange, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(
                              'Tồn kho hiện tại: ${AppFormatters.quantity(item.stockQuantity)} ${item.unit}',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Lý do',
                  hintText: 'VD: Thanh lý, Hao hụt, Tự dùng...',
                  prefixIcon: Icon(Icons.note_alt),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tồn kho sẽ được reset về 0.\nThao tác này không thể hoàn tác.',
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              // Convert stock to grams for the reset
              final stockInGrams =
                  (item.stockQuantity * Decimal.fromInt(1000)).toBigInt().toInt();
              final bloc = context.read<InventoryBloc>();
              bloc.add(InventoryResetStock(
                productId: item.productId,
                currentStockInGrams: stockInGrams,
                reason: reasonController.text.trim(),
                currentPeriod: bloc.state.currentPeriod,
              ));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Đã làm mới kho "${item.productName}"'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Xác nhận reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho hàng'),
        actions: [
          AnimatedRefreshButton(
            onPressed: () {
              final bloc = context.read<InventoryBloc>();
              bloc.add(
                  InventoryLoadRequested(period: bloc.state.currentPeriod));
            },
          ),
        ],
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state.status == InventoryStatus.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == InventoryStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64,
                      color: colorScheme.error.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${state.errorMessage}',
                      style: textTheme.bodyLarge),
                ],
              ),
            );
          }

          final allItems = state.items;
          final filteredItems = _applyFilters(allItems);

          // Summary stats
          final totalBuy =
              allItems.fold(Decimal.zero, (sum, i) => sum + i.buyQuantity);
          final totalSell =
              allItems.fold(Decimal.zero, (sum, i) => sum + i.sellQuantity);
          final totalStock = allItems.fold(
              Decimal.zero, (sum, i) => sum + i.stockQuantity);
          final lowCount =
              allItems.where((i) => i.status == StockStatus.low).length;
          final negativeCount =
              allItems.where((i) => i.status == StockStatus.negative).length;

          // Category chips
          final categoryState = context.watch<CategoryBloc>().state;
          final categoryFilters = [
            const FilterOption(id: 'all', label: 'Tất cả', icon: Icons.apps),
            ...categoryState.categories
                .where((c) => c.isActive)
                .map((c) => FilterOption(
                      id: c.id,
                      label: c.name,
                      icon: Icons.category,
                    )),
          ];

          return Column(
            children: [
              // Period selector
              _buildPeriodSelector(context, state.currentPeriod),

              // Summary cards
              _buildSummaryRow(
                context,
                totalBuy: totalBuy,
                totalSell: totalSell,
                totalStock: totalStock,
                lowCount: lowCount,
                negativeCount: negativeCount,
                totalProducts: allItems.length,
              ),

              // Search + filters
              SearchFilterBar(
                hintText: 'Tìm sản phẩm...',
                onSearchChanged: (q) => setState(() => _searchQuery = q),
                filters: categoryFilters,
                selectedFilterId: _categoryFilter,
                onFilterChanged: (id) =>
                    setState(() => _categoryFilter = id),
              ),

              // Status filter chips
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _StatusFilterChip(
                      label: 'Tất cả',
                      count: allItems.length,
                      isSelected: _statusFilter == 'all',
                      color: colorScheme.primary,
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    const SizedBox(width: 6),
                    _StatusFilterChip(
                      label: 'Đủ hàng',
                      count: allItems
                          .where((i) => i.status == StockStatus.sufficient)
                          .length,
                      isSelected: _statusFilter == 'sufficient',
                      color: OceanTheme.sellGreen,
                      onTap: () =>
                          setState(() => _statusFilter = 'sufficient'),
                    ),
                    const SizedBox(width: 6),
                    _StatusFilterChip(
                      label: 'Sắp hết',
                      count: lowCount,
                      isSelected: _statusFilter == 'low',
                      color: Colors.orange,
                      onTap: () => setState(() => _statusFilter = 'low'),
                    ),
                    const SizedBox(width: 6),
                    _StatusFilterChip(
                      label: 'Hết / Thiếu',
                      count: allItems
                              .where((i) => i.status == StockStatus.empty)
                              .length +
                          negativeCount,
                      isSelected: _statusFilter == 'negative',
                      color: Colors.red,
                      onTap: () =>
                          setState(() => _statusFilter = 'negative'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Stock table
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              allItems.isEmpty
                                  ? 'Chưa có dữ liệu kho'
                                  : 'Không tìm thấy sản phẩm',
                              style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : _buildStockTable(context, filteredItems),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, InventoryPeriod current) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<InventoryPeriod>(
          segments: const [
            ButtonSegment(
              value: InventoryPeriod.all,
              label: Text('Tất cả'),
              icon: Icon(Icons.all_inclusive, size: 16),
            ),
            ButtonSegment(
              value: InventoryPeriod.thisMonth,
              label: Text('Tháng này'),
              icon: Icon(Icons.calendar_today, size: 16),
            ),
            ButtonSegment(
              value: InventoryPeriod.lastMonth,
              label: Text('Tháng trước'),
              icon: Icon(Icons.calendar_month, size: 16),
            ),
            ButtonSegment(
              value: InventoryPeriod.thisYear,
              label: Text('Năm nay'),
              icon: Icon(Icons.date_range, size: 16),
            ),
          ],
          selected: {current},
          onSelectionChanged: (selected) {
            context
                .read<InventoryBloc>()
                .add(InventoryLoadRequested(period: selected.first));
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required Decimal totalBuy,
    required Decimal totalSell,
    required Decimal totalStock,
    required int lowCount,
    required int negativeCount,
    required int totalProducts,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.arrow_downward,
              label: 'Tổng mua',
              value: AppFormatters.quantity(totalBuy),
              unit: 'kg',
              color: OceanTheme.buyBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              icon: Icons.arrow_upward,
              label: 'Tổng bán',
              value: AppFormatters.quantity(totalSell),
              unit: 'kg',
              color: OceanTheme.sellGreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              icon: Icons.warehouse,
              label: 'Tồn kho',
              value: AppFormatters.quantity(totalStock),
              unit: 'kg',
              color: totalStock < Decimal.zero
                  ? Colors.red
                  : OceanTheme.oceanPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              icon: Icons.warning_amber,
              label: 'Cảnh báo',
              value: '${lowCount + negativeCount}',
              unit: 'sp',
              color: (lowCount + negativeCount) > 0
                  ? Colors.orange
                  : OceanTheme.sellGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockTable(BuildContext context, List<InventoryItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _StockRow(
          item: item,
          onReset: item.stockQuantity != Decimal.zero
              ? () => _showResetDialog(item)
              : null,
        );
      },
    );
  }
}

// === WIDGETS ===

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$value $unit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback? onReset;

  const _StockRow({required this.item, this.onReset});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final statusColor = switch (item.status) {
      StockStatus.sufficient => OceanTheme.sellGreen,
      StockStatus.low => Colors.orange,
      StockStatus.empty => Colors.red,
      StockStatus.negative => Colors.red,
    };

    final statusLabel = switch (item.status) {
      StockStatus.sufficient => 'Đủ hàng',
      StockStatus.low => 'Sắp hết',
      StockStatus.empty => 'Hết hàng',
      StockStatus.negative => 'Thiếu hàng',
    };

    final statusIcon = switch (item.status) {
      StockStatus.sufficient => Icons.check_circle,
      StockStatus.low => Icons.warning_amber,
      StockStatus.empty => Icons.remove_circle_outline,
      StockStatus.negative => Icons.error_outline,
    };

    // Stock bar: percentage of stock relative to buy
    final stockPercent = item.buyQuantity > Decimal.zero
        ? (item.stockQuantity / item.buyQuantity)
            .toDecimal(scaleOnInfinitePrecision: 2)
            .toDouble()
            .clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name + status + reset button
            Row(
              children: [
                // Status indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Product name
                Expanded(
                  child: Text(
                    item.productName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration:
                          item.isActive ? null : TextDecoration.lineThrough,
                      color: item.isActive
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // Reset button
                if (onReset != null)
                  SizedBox(
                    height: 28,
                    child: TextButton.icon(
                      onPressed: onReset,
                      icon: const Icon(Icons.restart_alt, size: 14),
                      label: const Text('Reset', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quantities row
            Row(
              children: [
                Expanded(
                  child: _QuantityColumn(
                    label: 'Mua vào',
                    value: AppFormatters.quantity(item.buyQuantity),
                    unit: item.unit,
                    color: OceanTheme.buyBlue,
                    icon: Icons.arrow_downward,
                  ),
                ),
                Expanded(
                  child: _QuantityColumn(
                    label: 'Bán ra',
                    value: AppFormatters.quantity(item.sellQuantity),
                    unit: item.unit,
                    color: OceanTheme.sellGreen,
                    icon: Icons.arrow_upward,
                  ),
                ),
                if (item.adjustmentQuantity != Decimal.zero)
                  Expanded(
                    child: _QuantityColumn(
                      label: 'Điều chỉnh',
                      value: AppFormatters.quantity(item.adjustmentQuantity),
                      unit: item.unit,
                      color: Colors.orange,
                      icon: Icons.tune,
                    ),
                  ),
                Expanded(
                  child: _QuantityColumn(
                    label: 'Tồn kho',
                    value: AppFormatters.quantity(item.stockQuantity),
                    unit: item.unit,
                    color: statusColor,
                    icon: Icons.warehouse,
                    bold: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Stock progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stockPercent,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityColumn extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  final bool bold;

  const _QuantityColumn({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$value $unit',
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
