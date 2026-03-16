/// Debt management page — Quản lý công nợ (phải thu / phải trả).
///
/// Two tabs: Receivables (sell orders) + Payables (buy orders).
/// Each tab: partner cards with debt summary.
/// Detail view: orders + payment history + add payment dialog.
/// Debt invoice export.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';

import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/core/services/invoice_service.dart';
import 'package:fishcash_pos/data/repositories/debt_repository.dart';
import 'package:fishcash_pos/data/repositories/store_info_repository.dart';
import 'package:fishcash_pos/presentation/debt/bloc/debt_bloc.dart';
import 'package:fishcash_pos/presentation/shared/animated_refresh_button.dart';

class DebtPage extends StatefulWidget {
  const DebtPage({super.key});

  @override
  State<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedPartnerId;
  String? _selectedPartnerName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPartnerDetail(DebtSummary partner) {
    setState(() {
      _selectedPartnerId = partner.partnerId;
      _selectedPartnerName = partner.partnerName;
    });
    context.read<DebtBloc>().add(DebtPartnerDetailRequested(partner.partnerId));
  }

  void _backToList() {
    setState(() {
      _selectedPartnerId = null;
      _selectedPartnerName = null;
    });
  }

  void _showExportOptions(BuildContext context, DebtState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Xuất PDF công nợ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              // Option 1: Summary
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: OceanTheme.oceanPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.table_chart_rounded,
                        color: OceanTheme.oceanPrimary, size: 24),
                  ),
                  title: const Text('Bảng tóm tắt công nợ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tổng hợp phải thu + phải trả'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _exportSummaryOnly(context, state);
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Option 2: Signature
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.draw_rounded,
                        color: Colors.deepOrange, size: 24),
                  ),
                  title: const Text('Giấy xác nhận công nợ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Chọn đối tác để xuất ký tên'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _exportPartnerSignature(context, state);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebtBloc, DebtState>(
      builder: (context, state) {
        // Partner detail view
        if (_selectedPartnerId != null) {
          return _PartnerDebtDetail(
            partnerId: _selectedPartnerId!,
            partnerName: _selectedPartnerName ?? '',
            state: state,
            onBack: _backToList,
          );
        }

        // Main debt overview
        return Scaffold(
          appBar: AppBar(
            title: const Text('Công nợ'),
            actions: [
              // Export options
              if (state.receivables.isNotEmpty || state.payables.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FilledButton.tonalIcon(
                    onPressed: () => _showExportOptions(context, state),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Xuất PDF', style: TextStyle(fontSize: 13)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              AnimatedRefreshButton(
                onPressed: () =>
                    context.read<DebtBloc>().add(const DebtLoadRequested()),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  text:
                      'Phải thu (${state.receivables.length})',
                ),
                Tab(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  text:
                      'Phải trả (${state.payables.length})',
                ),
              ],
              indicatorColor: OceanTheme.oceanPrimary,
              labelColor: OceanTheme.oceanPrimary,
            ),
          ),
          body: state.status == DebtStatus.loading && state.receivables.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _DebtTab(
                      debts: state.receivables,
                      emptyMessage: 'Không có công nợ phải thu',
                      emptySubtext: 'Các đơn bán ra chưa thanh toán sẽ xuất hiện ở đây',
                      accentColor: OceanTheme.sellGreen,
                      icon: Icons.arrow_downward,
                      label: 'Phải thu',
                      onPartnerTap: _showPartnerDetail,
                    ),
                    _DebtTab(
                      debts: state.payables,
                      emptyMessage: 'Không có công nợ phải trả',
                      emptySubtext: 'Các đơn mua vào chưa thanh toán sẽ xuất hiện ở đây',
                      accentColor: OceanTheme.buyBlue,
                      icon: Icons.arrow_upward,
                      label: 'Phải trả',
                      onPartnerTap: _showPartnerDetail,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ==========================================
// DEBT TAB — list of partners with debt
// ==========================================

class _DebtTab extends StatelessWidget {
  final List<DebtSummary> debts;
  final String emptyMessage;
  final String emptySubtext;
  final Color accentColor;
  final IconData icon;
  final String label;
  final ValueChanged<DebtSummary> onPartnerTap;

  const _DebtTab({
    required this.debts,
    required this.emptyMessage,
    required this.emptySubtext,
    required this.accentColor,
    required this.icon,
    required this.label,
    required this.onPartnerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(emptySubtext,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    // Summary row
    final totalDebt = debts.fold(Decimal.zero, (sum, d) => sum + d.debt);
    final partnersWithDebt = debts.where((d) => !d.isFullyPaid).length;

    return Column(
      children: [
        // Summary
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 16, color: accentColor),
                            const SizedBox(width: 6),
                            Text('Tổng $label',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppFormatters.currency(totalDebt),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: totalDebt > Decimal.zero
                                ? Colors.red
                                : OceanTheme.sellGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, size: 16, color: accentColor),
                            const SizedBox(width: 6),
                            Text('Đối tác',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$partnersWithDebt còn nợ / ${debts.length} tổng',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Partner list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];
              return _DebtPartnerCard(
                debt: debt,
                accentColor: accentColor,
                onTap: () => onPartnerTap(debt),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==========================================
// PARTNER CARD — debt summary for one partner
// ==========================================

class _DebtPartnerCard extends StatelessWidget {
  final DebtSummary debt;
  final Color accentColor;
  final VoidCallback onTap;

  const _DebtPartnerCard({
    required this.debt,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final debtColor = debt.isFullyPaid ? OceanTheme.sellGreen : Colors.red;
    final paidPercent = debt.totalOrder > Decimal.zero
        ? (debt.totalPaid / debt.totalOrder)
            .toDecimal(scaleOnInfinitePrecision: 2)
            .toDouble()
            .clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: partner name + debt amount
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: accentColor.withValues(alpha: 0.12),
                    child: Icon(Icons.person, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.partnerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        if (debt.partnerPhone.isNotEmpty)
                          Text(
                            debt.partnerPhone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Debt amount badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: debtColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: debtColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      debt.isFullyPaid
                          ? 'Đã thanh toán'
                          : AppFormatters.currency(debt.debt),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: debtColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress: paid / total
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đã trả: ${debt.totalPaidDisplay}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                            Text(
                              'Tổng: ${debt.totalOrderDisplay}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: paidPercent,
                            minHeight: 5,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              debt.isFullyPaid ? OceanTheme.sellGreen : accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PARTNER DEBT DETAIL — orders + payments
// ==========================================

class _PartnerDebtDetail extends StatelessWidget {
  final String partnerId;
  final String partnerName;
  final DebtState state;
  final VoidCallback onBack;

  const _PartnerDebtDetail({
    required this.partnerId,
    required this.partnerName,
    required this.state,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final orders = state.partnerOrders;
    final totalOrder =
        orders.fold(Decimal.zero, (sum, o) => sum + o.subtotal);
    final totalPaid =
        orders.fold(Decimal.zero, (sum, o) => sum + o.totalPaid);
    final totalDebt = totalOrder - totalPaid;

    return Scaffold(
      appBar: AppBar(
        leading:
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
        title: Text(partnerName),
        actions: [
          // Export debt invoice
          if (orders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Xuất HĐ công nợ',
              onPressed: () =>
                  _exportDebtInvoice(context, partnerName, orders, totalDebt),
            ),
        ],
      ),
      body: Column(
        children: [
          // Debt summary card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Card(
              color: totalDebt > Decimal.zero
                  ? Colors.red.withValues(alpha: 0.05)
                  : OceanTheme.sellGreen.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _DetailStat(
                        label: 'Tổng đơn',
                        value: AppFormatters.currency(totalOrder),
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        label: 'Đã trả',
                        value: AppFormatters.currency(totalPaid),
                        color: OceanTheme.sellGreen,
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        label: 'Còn nợ',
                        value: AppFormatters.currency(totalDebt),
                        color: totalDebt > Decimal.zero
                            ? Colors.red
                            : OceanTheme.sellGreen,
                        bold: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Danh sách đơn hàng (${orders.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Order list
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text('Không có đơn hàng',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _OrderDebtCard(
                        order: order,
                        onAddPayment: () =>
                            _showPaymentDialog(context, order),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, DebtOrderDetail order) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = _CurrencyInputFormatter();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.payment, color: OceanTheme.sellGreen, size: 40),
        title: const Text('Ghi nhận thanh toán'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Order info
              Card(
                color: colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        order.orderType == 'buy'
                            ? Icons.shopping_cart
                            : Icons.storefront,
                        color: order.orderType == 'buy'
                            ? OceanTheme.buyBlue
                            : OceanTheme.sellGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${order.orderType == "buy" ? "Đơn mua" : "Đơn bán"} • ${AppFormatters.dateTime(order.orderDate)}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Tổng: ${AppFormatters.currency(order.subtotal)} • Còn nợ: ${AppFormatters.currency(order.remaining)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount with currency formatter
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  formatter,
                ],
                decoration: InputDecoration(
                  labelText: 'Số tiền thanh toán',
                  hintText:
                      'VD: ${_formatWithDots(order.remaining.toDouble().round())}',
                  prefixIcon: const Icon(Icons.monetization_on),
                  suffixText: 'đ',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Quick fill button
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final remainingInt = order.remaining.toDouble().round();
                      amountController.text = _formatWithDots(remainingInt);
                      amountController.selection = TextSelection.collapsed(
                          offset: amountController.text.length);
                    },
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text('Trả hết', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: OceanTheme.sellGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Note
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  hintText: 'VD: Trả tiền mặt, CK ngân hàng...',
                  prefixIcon: Icon(Icons.note_alt),
                  border: OutlineInputBorder(),
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
            style:
                FilledButton.styleFrom(backgroundColor: OceanTheme.sellGreen),
            onPressed: () {
              final rawText = amountController.text.replaceAll('.', '').trim();
              if (rawText.isEmpty) return;
              final amount = int.tryParse(rawText);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Số tiền không hợp lệ'),
                    backgroundColor: colorScheme.error,
                  ),
                );
                return;
              }
              final amountCents = amount * 100;

              context.read<DebtBloc>().add(DebtPaymentAdded(
                    orderId: order.orderId,
                    amountInCents: amountCents,
                    note: noteController.text.trim(),
                  ));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Đã ghi nhận thanh toán ${_formatWithDots(amount)}đ'),
                  backgroundColor: OceanTheme.sellGreen,
                ),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDebtInvoice(
    BuildContext context,
    String partnerName,
    List<DebtOrderDetail> orders,
    Decimal totalDebt,
  ) async {
    try {
      final storeRepo = context.read<StoreInfoRepository>();
      final storeInfo = await storeRepo.getStoreInfo();
      final fonts = await InvoiceFonts.load();

      final pdf = await InvoiceService.generateDebtInvoice(
        fonts: fonts,
        partnerName: partnerName,
        orders: orders,
        totalDebt: totalDebt,
        storeName: storeInfo?.name ?? 'FishCash POS',
        storeAddress: storeInfo?.address ?? '',
        storePhone: storeInfo?.phone ?? '',
        storeLogoPath: storeInfo?.logoPath,
      );

      if (!context.mounted) return;

      // Show choice: save or print
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
          title: const Text('Hóa đơn công nợ'),
          content: const Text('Chọn cách xuất hóa đơn:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(ctx).pop('save'),
              icon: const Icon(Icons.save_alt),
              label: const Text('Lưu PDF'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop('print'),
              icon: const Icon(Icons.print),
              label: const Text('In / Xem trước'),
            ),
          ],
        ),
      );

      if (choice == null || !context.mounted) return;

      if (choice == 'print') {
        await Printing.layoutPdf(onLayout: (_) => pdf);
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Lưu hóa đơn công nợ',
          fileName: 'cong_no_${partnerName.replaceAll(' ', '_')}.pdf',
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result != null) {
          await File(result).writeAsBytes(pdf);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã lưu: $result'),
                backgroundColor: OceanTheme.sellGreen,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất HĐ: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// ==========================================
// ORDER DEBT CARD — single order with payment status
// ==========================================

class _OrderDebtCard extends StatelessWidget {
  final DebtOrderDetail order;
  final VoidCallback onAddPayment;

  const _OrderDebtCard({
    required this.order,
    required this.onAddPayment,
  });

  @override
  Widget build(BuildContext context) {
    final isBuy = order.orderType == 'buy';
    final accentColor = isBuy ? OceanTheme.buyBlue : OceanTheme.sellGreen;
    final statusColor = order.isFullyPaid ? OceanTheme.sellGreen : Colors.red;
    final paidPercent = order.subtotal > Decimal.zero
        ? (order.totalPaid / order.subtotal)
            .toDecimal(scaleOnInfinitePrecision: 2)
            .toDouble()
            .clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: accentColor.withValues(alpha: 0.12),
                  child: Icon(
                    isBuy ? Icons.shopping_cart : Icons.storefront,
                    color: accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBuy ? 'Đơn mua vào' : 'Đơn bán ra',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: accentColor),
                      ),
                      Text(
                        AppFormatters.dateTime(order.orderDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    order.isFullyPaid ? 'Đã trả' : 'Còn nợ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Amounts row
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Tổng đơn',
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      Text(AppFormatters.currency(order.subtotal),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Đã trả',
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      Text(AppFormatters.currency(order.totalPaid),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: OceanTheme.sellGreen)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Còn nợ',
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      Text(AppFormatters.currency(order.remaining),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: paidPercent,
                minHeight: 4,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  order.isFullyPaid ? OceanTheme.sellGreen : accentColor,
                ),
              ),
            ),

            // Add payment button
            if (!order.isFullyPaid) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 30,
                  child: FilledButton.icon(
                    onPressed: onAddPayment,
                    icon: const Icon(Icons.payment, size: 14),
                    label: const Text('Thanh toán',
                        style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      backgroundColor: OceanTheme.sellGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DETAIL STAT — small stat widget
// ==========================================

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _DetailStat({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// CURRENCY INPUT FORMATTER — dấu chấm phân cách
// ==========================================

/// Formats number input with dot separators: 1000000 → 1.000.000
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Only digits
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return const TextEditingValue();

    final formatted = _formatWithDots(int.tryParse(digits) ?? 0);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Format integer with dot separators: 1500000 → "1.500.000"
String _formatWithDots(int value) {
  if (value == 0) return '0';
  final str = value.toString();
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i > 0) {
      buffer.write('.');
    }
  }
  return buffer.toString().split('').reversed.join();
}

// ==========================================
// EXPORT: Bảng tóm tắt công nợ (summary only)
// ==========================================

Future<void> _exportSummaryOnly(BuildContext context, DebtState state) async {
  try {
    final storeRepo = context.read<StoreInfoRepository>();
    final storeInfo = await storeRepo.getStoreInfo();
    final fonts = await InvoiceFonts.load();

    final pdf = await InvoiceService.generateDebtSummaryWithSignatures(
      fonts: fonts,
      receivables: state.receivables,
      payables: state.payables,
      storeName: storeInfo?.name ?? 'FishCash POS',
      storeAddress: storeInfo?.address ?? '',
      storePhone: storeInfo?.phone ?? '',
      storeLogoPath: storeInfo?.logoPath,
    );

    if (!context.mounted) return;
    await _showSaveOrPrint(
      context: context,
      pdf: pdf,
      title: 'Bảng tóm tắt công nợ',
      subtitle: 'Tổng hợp tất cả phải thu và phải trả',
      icon: Icons.summarize,
      iconColor: OceanTheme.oceanPrimary,
      fileName: 'tom_tat_cong_no.pdf',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xuất PDF: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

// ==========================================
// EXPORT: Giấy xác nhận công nợ (per partner)
// ==========================================

Future<void> _exportPartnerSignature(
    BuildContext context, DebtState state) async {
  // Combine all partners with outstanding debt
  final allPartners = [
    ...state.receivables.where((d) => !d.isFullyPaid).map((d) => (d, 'Phải thu')),
    ...state.payables.where((d) => !d.isFullyPaid).map((d) => (d, 'Phải trả')),
  ];

  if (allPartners.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không có đối tác nào còn nợ')),
    );
    return;
  }

  // Let user pick a partner
  final selected = await showDialog<(DebtSummary, String)>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.draw, color: Colors.deepOrange, size: 40),
      title: const Text('Chọn đối tác'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: ListView.builder(
          itemCount: allPartners.length,
          itemBuilder: (_, i) {
            final (partner, type) = allPartners[i];
            final isReceivable = type == 'Phải thu';
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isReceivable
                      ? OceanTheme.sellGreen.withValues(alpha: 0.12)
                      : OceanTheme.buyBlue.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.person,
                    color: isReceivable ? OceanTheme.sellGreen : OceanTheme.buyBlue,
                    size: 20,
                  ),
                ),
                title: Text(partner.partnerName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '$type • Nợ: ${AppFormatters.currency(partner.debt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(ctx).pop((partner, type)),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Hủy'),
        ),
      ],
    ),
  );

  if (selected == null || !context.mounted) return;

  final (partner, type) = selected;

  try {
    final storeRepo = context.read<StoreInfoRepository>();
    final storeInfo = await storeRepo.getStoreInfo();
    final fonts = await InvoiceFonts.load();

    final pdf = await InvoiceService.generatePartnerSignatureSheet(
      fonts: fonts,
      partner: partner,
      debtType: type,
      storeName: storeInfo?.name ?? 'FishCash POS',
      storeAddress: storeInfo?.address ?? '',
      storePhone: storeInfo?.phone ?? '',
      storeLogoPath: storeInfo?.logoPath,
    );

    if (!context.mounted) return;
    await _showSaveOrPrint(
      context: context,
      pdf: pdf,
      title: 'Giấy xác nhận công nợ',
      subtitle: partner.partnerName,
      icon: Icons.draw,
      iconColor: Colors.deepOrange,
      fileName: 'xac_nhan_${partner.partnerName.replaceAll(' ', '_')}.pdf',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xuất PDF: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

// ==========================================
// SHARED: Save or Print dialog
// ==========================================

Future<void> _showSaveOrPrint({
  required BuildContext context,
  required Uint8List pdf,
  required String title,
  required String subtitle,
  required IconData icon,
  required Color iconColor,
  required String fileName,
}) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(icon, color: iconColor, size: 40),
      title: Text(title),
      content: Text(subtitle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Hủy'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(ctx).pop('save'),
          icon: const Icon(Icons.save_alt),
          label: const Text('Lưu PDF'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(ctx).pop('print'),
          icon: const Icon(Icons.print),
          label: const Text('In / Xem trước'),
        ),
      ],
    ),
  );

  if (choice == null || !context.mounted) return;

  if (choice == 'print') {
    await Printing.layoutPdf(onLayout: (_) => pdf);
  } else {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Lưu $title',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      await File(result).writeAsBytes(pdf);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu: $result'),
            backgroundColor: OceanTheme.sellGreen,
          ),
        );
      }
    }
  }
}
