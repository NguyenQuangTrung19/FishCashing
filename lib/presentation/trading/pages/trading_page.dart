/// Trading Page — Sessions + Order management.
///
/// Flow: Session list → Session detail → Select partner → Create buy/sell orders (POS UI)
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';

import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/repositories/trading_session_repository.dart';
import 'package:fishcash_pos/data/repositories/partner_repository.dart';
import 'package:fishcash_pos/domain/models/partner_model.dart';
import 'package:fishcash_pos/presentation/trading/bloc/trading_bloc.dart';
import 'package:fishcash_pos/presentation/trading/widgets/order_creation_view.dart';
import 'package:fishcash_pos/presentation/trading/widgets/invoice_export_dialog.dart';
import 'package:fishcash_pos/presentation/shared/animated_refresh_button.dart';
import 'package:fishcash_pos/presentation/partners/bloc/partner_bloc.dart';
import 'package:fishcash_pos/presentation/pos/bloc/pos_bloc.dart';

/// View mode for the trading page
enum _ViewMode { list, detail, createOrder }

class TradingPage extends StatefulWidget {
  final String? initialSessionId;

  const TradingPage({super.key, this.initialSessionId});

  @override
  State<TradingPage> createState() => _TradingPageState();
}

class _TradingPageState extends State<TradingPage> {
  _ViewMode _viewMode = _ViewMode.list;
  String? _selectedSessionId;
  String? _createOrderType; // 'buy' or 'sell'
  String? _selectedPartnerId;
  String? _selectedPartnerName;
  String? _editingOrderId; // non-null = editing existing order

  @override
  void initState() {
    super.initState();
    // Auto-navigate to session detail if initialSessionId is provided
    if (widget.initialSessionId != null) {
      _selectedSessionId = widget.initialSessionId;
      _viewMode = _ViewMode.detail;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .read<TradingBloc>()
            .add(TradingSessionDetailRequested(widget.initialSessionId!));
      });
    }
  }

  void _goToList() {
    setState(() {
      _viewMode = _ViewMode.list;
      _selectedSessionId = null;
      _createOrderType = null;
      _selectedPartnerId = null;
      _selectedPartnerName = null;
    });
    context.read<TradingBloc>().add(const TradingSessionsLoadRequested());
  }

  void _goToDetail(String sessionId) {
    setState(() {
      _viewMode = _ViewMode.detail;
      _selectedSessionId = sessionId;
      _createOrderType = null;
      _selectedPartnerId = null;
      _selectedPartnerName = null;
    });
    context.read<TradingBloc>().add(TradingSessionDetailRequested(sessionId));
  }

  /// Show partner selection dialog then navigate to order creation
  void _startCreateOrder(String orderType) {
    final isBuy = orderType == 'buy';
    final partnerType = isBuy ? PartnerType.supplier : PartnerType.buyer;
    final partnerLabel = isBuy ? 'Nhà cung cấp' : 'Khách mua';
    final accentColor = isBuy ? OceanTheme.buyBlue : OceanTheme.sellGreen;

    // Get existing partners of the right type
    final allPartners = context.read<PartnerBloc>().state.partners;
    final relevantPartners = allPartners
        .where((p) => p.type == partnerType && p.isActive)
        .toList();

    final nameController = TextEditingController();
    bool isCreatingNew = relevantPartners.isEmpty;
    String? selectedId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            icon: Icon(
              isBuy ? Icons.directions_boat : Icons.store,
              color: accentColor,
              size: 36,
            ),
            title: Text(
              'Chọn $partnerLabel',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle: existing vs new
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text('Chọn có sẵn (${relevantPartners.length})'),
                        icon: const Icon(Icons.list),
                      ),
                      const ButtonSegment(
                        value: true,
                        label: Text('Nhập tên mới'),
                        icon: Icon(Icons.add),
                      ),
                    ],
                    selected: {isCreatingNew},
                    onSelectionChanged: (v) {
                      setDialogState(() {
                        isCreatingNew = v.first;
                        if (isCreatingNew) selectedId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  if (!isCreatingNew) ...[
                    // Existing partner list
                    if (relevantPartners.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Chưa có $partnerLabel nào.\nChuyển sang "Nhập tên mới" để tạo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: relevantPartners.length,
                          itemBuilder: (context, index) {
                            final partner = relevantPartners[index];
                            final isSelected = selectedId == partner.id;

                            return Card(
                              color: isSelected
                                  ? accentColor.withValues(alpha: 0.12)
                                  : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? accentColor
                                      : accentColor.withValues(alpha: 0.15),
                                  child: Icon(
                                    isBuy ? Icons.directions_boat : Icons.store,
                                    color: isSelected ? Colors.white : accentColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  partner.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                subtitle: partner.phone.isNotEmpty
                                    ? Text(partner.phone)
                                    : null,
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: accentColor)
                                    : null,
                                onTap: () {
                                  setDialogState(() => selectedId = partner.id);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ] else ...[
                    // New partner name input
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Tên $partnerLabel',
                        hintText: isBuy
                            ? 'VD: Ghe Ông Ba, Tàu Minh...'
                            : 'VD: Nhà hàng Hải Sản, Cơ sở Minh...',
                        prefixIcon: Icon(
                          isBuy ? Icons.directions_boat : Icons.store,
                          color: accentColor,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '💡 Tên sẽ được tự động lưu vào danh sách Đối tác',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: accentColor),
                onPressed: () async {
                  if (isCreatingNew) {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vui lòng nhập tên $partnerLabel'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                      return;
                    }
                    // Auto-create partner
                    final repo = context.read<PartnerRepository>();
                    final newPartner = await repo.create(
                      name: name,
                      type: partnerType,
                    );
                    // Refresh partner list
                    if (mounted) {
                      context.read<PartnerBloc>().add(const PartnersLoadRequested());
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    _proceedToCreateOrder(orderType, newPartner.id, newPartner.name);
                  } else {
                    if (selectedId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vui lòng chọn $partnerLabel'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                      return;
                    }
                    final partner = relevantPartners.firstWhere((p) => p.id == selectedId);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    _proceedToCreateOrder(orderType, partner.id, partner.name);
                  }
                },
                icon: const Icon(Icons.arrow_forward),
                label: Text(isBuy ? 'Tiếp → Tạo đơn mua' : 'Tiếp → Tạo đơn bán'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// After partner is selected, navigate to POS UI
  void _proceedToCreateOrder(String orderType, String partnerId, String partnerName) {
    setState(() {
      _viewMode = _ViewMode.createOrder;
      _createOrderType = orderType;
      _selectedPartnerId = partnerId;
      _selectedPartnerName = partnerName;
      _editingOrderId = null;
    });
    context.read<PosBloc>().add(PosSetContext(
      sessionId: _selectedSessionId!,
      orderType: orderType,
    ));
  }

  /// Edit an existing order: load its items into cart
  void _editOrder(String orderId, String orderType, String? partnerId, String? partnerName) {
    setState(() {
      _viewMode = _ViewMode.createOrder;
      _createOrderType = orderType;
      _selectedPartnerId = partnerId;
      _selectedPartnerName = partnerName;
      _editingOrderId = orderId;
    });
    context.read<PosBloc>().add(PosLoadFromOrder(
      orderId: orderId,
      sessionId: _selectedSessionId!,
      orderType: orderType,
    ));
  }

  /// Delete an order with confirmation
  void _deleteOrder(String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline,
            color: Theme.of(context).colorScheme.error, size: 40),
        title: const Text('Xóa đơn hàng?'),
        content: const Text(
          'Tất cả sản phẩm trong đơn này sẽ bị xóa.\n'
          'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              context.read<TradingBloc>().add(
                TradingOrderDeleteRequested(orderId, _selectedSessionId!),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show order creation view (full screen POS-like UI)
    if (_viewMode == _ViewMode.createOrder &&
        _selectedSessionId != null &&
        _createOrderType != null) {
      return OrderCreationView(
        sessionId: _selectedSessionId!,
        orderType: _createOrderType!,
        partnerId: _selectedPartnerId,
        partnerName: _selectedPartnerName,
        editingOrderId: _editingOrderId,
        onDone: () => _goToDetail(_selectedSessionId!),
        onCancel: () => setState(() => _viewMode = _ViewMode.detail),
      );
    }

    return BlocBuilder<TradingBloc, TradingState>(
      builder: (context, state) {
        if (_viewMode == _ViewMode.detail && _selectedSessionId != null) {
          return _SessionDetailPage(
            state: state,
            sessionId: _selectedSessionId!,
            onBack: _goToList,
            onCreateBuy: () => _startCreateOrder('buy'),
            onCreateSell: () => _startCreateOrder('sell'),
            onEditOrder: _editOrder,
            onDeleteOrder: _deleteOrder,
          );
        }

        return _SessionListPage(
          state: state,
          onSelectSession: _goToDetail,
        );
      },
    );
  }
}

// ============================================
// SESSION LIST PAGE
// ============================================

class _SessionListPage extends StatelessWidget {
  final TradingState state;
  final ValueChanged<String> onSelectSession;

  const _SessionListPage({
    required this.state,
    required this.onSelectSession,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao dịch'),
        actions: [
          AnimatedRefreshButton(
            onPressed: () {
              context.read<TradingBloc>().add(const TradingSessionsLoadRequested());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Phiên mới'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (state.status == TradingStatus.loading && state.sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Chưa có phiên giao dịch nào',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Tạo phiên mới để bắt đầu mua vào / bán ra',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: state.sessions.length,
      itemBuilder: (context, index) {
        final session = state.sessions[index];
        return _SessionCard(
          session: session,
          onTap: () => onSelectSession(session.id),
          onDelete: () => _confirmDelete(context, session),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo phiên giao dịch mới'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Ghi chú (tùy chọn)',
              hintText: 'VD: Phiên buổi sáng 15/03...',
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () {
              context.read<TradingBloc>().add(
                TradingSessionCreateRequested(note: noteController.text.trim()),
              );
              Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.add),
            label: const Text('Tạo phiên'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, TradingSessionModel session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline,
            color: Theme.of(context).colorScheme.error, size: 40),
        title: const Text('Xóa phiên giao dịch?'),
        content: const Text(
          'Tất cả đơn hàng trong phiên này sẽ bị xóa.\n'
          'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              context.read<TradingBloc>().add(TradingSessionDeleteRequested(session.id));
              Navigator.of(ctx).pop();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// SESSION CARD
// ============================================

class _SessionCard extends StatelessWidget {
  final TradingSessionModel session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = session.profit >= Decimal.zero;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: OceanTheme.oceanPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.receipt_long,
                        color: OceanTheme.oceanPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppFormatters.dateTime(session.createdAt),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (session.note.isNotEmpty)
                          Text(session.note,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${session.orderCount} đơn',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MetricChip(label: 'Mua vào', value: AppFormatters.currency(session.totalBuy), color: OceanTheme.buyBlue),
                  const SizedBox(width: 8),
                  _MetricChip(label: 'Bán ra', value: AppFormatters.currency(session.totalSell), color: OceanTheme.sellGreen),
                  const SizedBox(width: 8),
                  _MetricChip(label: 'Lãi', value: AppFormatters.currency(session.profit),
                      color: isProfit ? OceanTheme.profitGold : OceanTheme.lossRed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
            Text(value, style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700, color: color),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ============================================
// SESSION DETAIL PAGE (with buy/sell FABs)
// ============================================

class _SessionDetailPage extends StatelessWidget {
  final TradingState state;
  final String sessionId;
  final VoidCallback onBack;
  final VoidCallback onCreateBuy;
  final VoidCallback onCreateSell;
  final void Function(String orderId, String orderType, String? partnerId, String? partnerName) onEditOrder;
  final void Function(String orderId) onDeleteOrder;

  const _SessionDetailPage({
    required this.state,
    required this.sessionId,
    required this.onBack,
    required this.onCreateBuy,
    required this.onCreateSell,
    required this.onEditOrder,
    required this.onDeleteOrder,
  });

  @override
  Widget build(BuildContext context) {
    final session = state.currentSession;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
        title: Text(session != null
            ? 'Phiên ${AppFormatters.dateTime(session.createdAt)}'
            : 'Chi tiết phiên'),
        actions: [
          _AnimatedRefreshButton(
            onPressed: () {
              if (session != null) {
                context.read<TradingBloc>().add(TradingSessionDetailRequested(session.id));
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: session != null
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Export invoice button
                    if (state.currentOrders.isNotEmpty) ...[
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.picture_as_pdf,
                          label: 'Xuất HĐ',
                          gradient: const [Color(0xFFE53935), Color(0xFFFF7043)],
                          onPressed: () => showSessionExportDialog(
                            context: context,
                            session: session,
                            orders: state.currentOrders,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    // Buy order button
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.shopping_cart,
                        label: 'Đơn mua vào',
                        gradient: [OceanTheme.buyBlue, OceanTheme.buyBlue.withValues(alpha: 0.7)],
                        onPressed: onCreateBuy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Sell order button
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.storefront,
                        label: 'Đơn bán ra',
                        gradient: [OceanTheme.sellGreen, OceanTheme.sellGreen.withValues(alpha: 0.7)],
                        onPressed: onCreateSell,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: _SessionDetailContent(
        state: state,
        session: session,
        onEditOrder: onEditOrder,
        onDeleteOrder: onDeleteOrder,
      ),
    );
  }
}

// ============================================
// SESSION DETAIL CONTENT
// ============================================

class _SessionDetailContent extends StatefulWidget {
  final TradingState state;
  final TradingSessionModel? session;
  final void Function(String orderId, String orderType, String? partnerId, String? partnerName) onEditOrder;
  final void Function(String orderId) onDeleteOrder;

  const _SessionDetailContent({
    required this.state,
    this.session,
    required this.onEditOrder,
    required this.onDeleteOrder,
  });

  @override
  State<_SessionDetailContent> createState() => _SessionDetailContentState();
}

class _SessionDetailContentState extends State<_SessionDetailContent> {
  String _filter = 'all'; // 'all', 'buy', 'sell'
  bool _showAll = false;
  static const _previewLimit = 7;

  List<TradeOrderWithDetails> get _filteredOrders {
    final orders = widget.state.currentOrders;
    if (_filter == 'buy') return orders.where((o) => o.order.orderType == 'buy').toList();
    if (_filter == 'sell') return orders.where((o) => o.order.orderType == 'sell').toList();
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.status == TradingStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final session = widget.state.currentSession;
    if (session == null) {
      return const Center(child: Text('Không tìm thấy phiên'));
    }

    final isProfit = session.profit >= Decimal.zero;
    final allOrders = widget.state.currentOrders;
    final buyCount = allOrders.where((o) => o.order.orderType == 'buy').length;
    final sellCount = allOrders.where((o) => o.order.orderType == 'sell').length;

    final filtered = _filteredOrders;
    final displayOrders = _showAll ? filtered : filtered.take(_previewLimit).toList();
    final hasMore = filtered.length > _previewLimit && !_showAll;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _SummaryTile(label: 'Tổng mua vào', value: AppFormatters.currency(session.totalBuy), color: OceanTheme.buyBlue),
              const SizedBox(width: 12),
              _SummaryTile(label: 'Tổng bán ra', value: AppFormatters.currency(session.totalSell), color: OceanTheme.sellGreen),
              const SizedBox(width: 12),
              _SummaryTile(label: 'Lợi nhuận', value: AppFormatters.currency(session.profit),
                  color: isProfit ? OceanTheme.profitGold : OceanTheme.lossRed),
            ],
          ),
          const SizedBox(height: 24),

          // Note
          if (session.note.isNotEmpty) ...[
            Card(child: ListTile(leading: const Icon(Icons.note), title: Text(session.note))),
            const SizedBox(height: 16),
          ],

          // Filter chips + order count
          Row(
            children: [
              Text('Đơn hàng (${allOrders.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'Tất cả (${allOrders.length})',
                selected: _filter == 'all',
                color: OceanTheme.oceanPrimary,
                onTap: () => setState(() { _filter = 'all'; _showAll = false; }),
              ),
              _FilterChip(
                label: 'Mua vào ($buyCount)',
                selected: _filter == 'buy',
                color: OceanTheme.buyBlue,
                onTap: () => setState(() { _filter = 'buy'; _showAll = false; }),
              ),
              _FilterChip(
                label: 'Bán ra ($sellCount)',
                selected: _filter == 'sell',
                color: OceanTheme.sellGreen,
                onTap: () => setState(() { _filter = 'sell'; _showAll = false; }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (filtered.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_outlined, size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text(_filter == 'all' ? 'Chưa có đơn hàng' : 'Không có đơn ${_filter == 'buy' ? 'mua' : 'bán'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      if (_filter == 'all') ...[
                        const SizedBox(height: 4),
                        Text('Bấm nút bên dưới để tạo đơn mua vào hoặc bán ra',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else ...[
            ...displayOrders.map((order) => _buildOrderCard(context, order)),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showAll = true),
                    icon: const Icon(Icons.expand_more),
                    label: Text('Xem tất cả ${filtered.length} đơn'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, TradeOrderWithDetails order) {
    final isBuy = order.order.orderType == 'buy';
    final accentColor = isBuy ? OceanTheme.buyBlue : OceanTheme.sellGreen;
    final subtotal = (Decimal.fromInt(order.order.subtotalInCents) /
            Decimal.fromInt(100))
        .toDecimal();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: accentColor.withValues(alpha: 0.15),
            child: Icon(
              isBuy ? Icons.shopping_cart : Icons.storefront,
              color: accentColor,
            ),
          ),
          title: Text(
            '${isBuy ? "Mua vào" : "Bán ra"}${order.partnerName != null ? " - ${order.partnerName}" : ""}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order.items.length} sản phẩm • ${AppFormatters.dateTime(order.order.createdAt)}',
              ),
              Text(
                AppFormatters.currency(subtotal),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: accentColor),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.receipt_outlined, color: OceanTheme.oceanPrimary, size: 22),
                tooltip: 'Xuat hoa don',
                onPressed: () {
                  final session = widget.session ?? widget.state.currentSession;
                  if (session == null) return;
                  showSingleOrderInvoice(
                    context: context,
                    order: order,
                    session: session,
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: accentColor, size: 22),
                tooltip: 'Chỉnh sửa đơn',
                onPressed: () => widget.onEditOrder(
                  order.order.id,
                  order.order.orderType,
                  order.order.partnerId,
                  order.partnerName,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error, size: 22),
                tooltip: 'Xóa đơn',
                onPressed: () => widget.onDeleteOrder(order.order.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(color: selected ? color : Colors.transparent),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800, color: color),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// ACTION BUTTON (bottom bar)
// ============================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// ANIMATED REFRESH BUTTON
// ============================================

class _AnimatedRefreshButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedRefreshButton({required this.onPressed});

  @override
  State<_AnimatedRefreshButton> createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<_AnimatedRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    _controller.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handlePress,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  OceanTheme.oceanPrimary.withValues(alpha: 0.1),
                  OceanTheme.oceanFoam.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: OceanTheme.oceanPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
