/// Invoice Export Dialog — Vietnamese UI with 4 export modes.
///
/// Flow: Bottom sheet → output choice → caller generates PDF.
/// "Chọn lẻ" mode: each selected order → separate PDF file.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:decimal/decimal.dart';

import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/services/invoice_service.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/repositories/trading_session_repository.dart';
import 'package:fishcash_pos/data/repositories/store_info_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// === DATA CLASSES ===

enum OutputType { savePdf, printPreview }

class _ExportChoice {
  final InvoiceFilter filter;
  final OutputType output;
  const _ExportChoice({required this.filter, required this.output});
}

// === PUBLIC API ===

/// Show the export bottom sheet, then handle generation
Future<void> showSessionExportDialog({
  required BuildContext context,
  required TradingSessionModel session,
  required List<TradeOrderWithDetails> orders,
}) async {
  final choice = await showModalBottomSheet<_ExportChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _InvoiceExportSheet(
      session: session,
      orders: orders,
    ),
  );

  if (choice == null || !context.mounted) return;

  await _generateSessionAndOutput(
    context: context,
    session: session,
    orders: orders,
    choice: choice,
  );
}

/// Export a single order
Future<void> showSingleOrderInvoice({
  required BuildContext context,
  required TradeOrderWithDetails order,
  required TradingSessionModel session,
  int orderIndex = 1,
}) async {
  final outputType = await _showOutputChoice(context);
  if (outputType == null || !context.mounted) return;

  try {
    final storeRepo = context.read<StoreInfoRepository>();
    final fonts = await InvoiceFonts.load();
    final storeInfo = await storeRepo.getStoreInfo();
    final pdf = await InvoiceService.generateSingleOrderInvoice(
      fonts: fonts,
      order: order,
      orderIndex: orderIndex,
      storeName: storeInfo?.name ?? 'FishCash POS',
      storeAddress: storeInfo?.address ?? '',
      storePhone: storeInfo?.phone ?? '',
      storeLogoPath: storeInfo?.logoPath ?? '',
    );
    final bytes = await pdf.save();
    final fileName = InvoiceService.orderFileName(
      order.order.createdAt,
      index: orderIndex,
      partnerName: order.partnerName,
    );

    if (!context.mounted) return;

    if (outputType == OutputType.savePdf) {
      await _savePdfToFile(context, bytes, fileName);
    } else {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: fileName,
      );
    }
  } catch (e) {
    if (context.mounted) _showError(context, 'Lỗi khi tạo hóa đơn: $e');
  }
}

// === GENERATION ===

Future<void> _generateSessionAndOutput({
  required BuildContext context,
  required TradingSessionModel session,
  required List<TradeOrderWithDetails> orders,
  required _ExportChoice choice,
}) async {
  try {
    final storeRepo = context.read<StoreInfoRepository>();
    final fonts = await InvoiceFonts.load();
    final storeInfo = await storeRepo.getStoreInfo();

    final pdf = await InvoiceService.generateSessionInvoice(
      fonts: fonts,
      session: session,
      orders: orders,
      filter: choice.filter,
      storeName: storeInfo?.name ?? 'FishCash POS',
      storeAddress: storeInfo?.address ?? '',
      storePhone: storeInfo?.phone ?? '',
      storeLogoPath: storeInfo?.logoPath ?? '',
    );
    final bytes = await pdf.save();
    final fileName = InvoiceService.sessionFileName(
      session.createdAt,
      choice.filter,
    );

    if (!context.mounted) return;

    if (choice.output == OutputType.savePdf) {
      await _savePdfToFile(context, bytes, fileName);
    } else {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: fileName,
      );
    }
  } catch (e) {
    if (context.mounted) _showError(context, 'Lỗi khi tạo hóa đơn: $e');
  }
}

/// Export MULTIPLE individual orders as separate files
Future<void> _exportIndividualOrders({
  required BuildContext context,
  required List<TradeOrderWithDetails> selectedOrders,
  required OutputType outputType,
}) async {
  if (outputType == OutputType.savePdf) {
    // Pick a FOLDER, then save each PDF inside
    final folderPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Chọn thư mục lưu hóa đơn',
    );
    if (folderPath == null || !context.mounted) return;

    try {
      final fonts = await InvoiceFonts.load();
      int savedCount = 0;

      for (var i = 0; i < selectedOrders.length; i++) {
        final order = selectedOrders[i];
        final pdf = await InvoiceService.generateSingleOrderInvoice(
          fonts: fonts,
          order: order,
          orderIndex: i + 1,
        );
        final bytes = await pdf.save();
        final fileName = InvoiceService.orderFileName(
          order.order.createdAt,
          index: i + 1,
          partnerName: order.partnerName,
        );

        final file = File('$folderPath/$fileName');
        await file.writeAsBytes(bytes);
        savedCount++;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã lưu $savedCount hóa đơn vào: $folderPath',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: OceanTheme.sellGreen,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Lỗi: $e');
    }
  } else {
    // Print preview: show each one sequentially
    try {
      final fonts = await InvoiceFonts.load();

      for (var i = 0; i < selectedOrders.length; i++) {
        if (!context.mounted) return;
        final order = selectedOrders[i];
        final pdf = await InvoiceService.generateSingleOrderInvoice(
          fonts: fonts,
          order: order,
          orderIndex: i + 1,
        );
        final bytes = await pdf.save();
        final fileName = InvoiceService.orderFileName(
          order.order.createdAt,
          index: i + 1,
          partnerName: order.partnerName,
        );

        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: fileName,
        );
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Lỗi: $e');
    }
  }
}

// === OUTPUT CHOICE ===

Future<OutputType?> _showOutputChoice(BuildContext context) {
  return showDialog<OutputType>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFFF7043)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.output, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Chọn cách xuất',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OutputCard(
              icon: Icons.save_alt,
              color: const Color(0xFFE53935),
              title: 'Lưu file PDF',
              subtitle: 'Chọn vị trí lưu trên máy tính',
              onTap: () => Navigator.of(ctx).pop(OutputType.savePdf),
            ),
            const SizedBox(height: 10),
            _OutputCard(
              icon: Icons.print,
              color: OceanTheme.oceanDeep,
              title: 'Xem trước & In',
              subtitle: 'Xem hóa đơn trước khi in',
              onTap: () => Navigator.of(ctx).pop(OutputType.printPreview),
            ),
          ],
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
}

/// Save PDF bytes to a user-chosen file location
Future<void> _savePdfToFile(
  BuildContext context,
  List<int> bytes,
  String defaultName,
) async {
  try {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Lưu hóa đơn PDF',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    final path = result.endsWith('.pdf') ? result : '$result.pdf';
    await File(path).writeAsBytes(bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Đã lưu: $path',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          backgroundColor: OceanTheme.sellGreen,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) _showError(context, 'Không thể lưu file: $e');
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

// === BOTTOM SHEET ===

class _InvoiceExportSheet extends StatefulWidget {
  final TradingSessionModel session;
  final List<TradeOrderWithDetails> orders;

  const _InvoiceExportSheet({required this.session, required this.orders});

  @override
  State<_InvoiceExportSheet> createState() => _InvoiceExportSheetState();
}

class _InvoiceExportSheetState extends State<_InvoiceExportSheet> {
  final Set<String> _selectedOrderIds = {};
  bool _isSelectMode = false;

  int get _buyCount =>
      widget.orders.where((o) => o.order.orderType == 'buy').length;
  int get _sellCount =>
      widget.orders.where((o) => o.order.orderType == 'sell').length;

  /// For session-level exports: show output choice, then pop with _ExportChoice
  Future<void> _selectAndExport(InvoiceFilter filter) async {
    final outputType = await _showOutputChoice(context);
    if (outputType == null || !mounted) return;

    Navigator.of(context).pop(_ExportChoice(
      filter: filter,
      output: outputType,
    ));
  }

  /// For individual order exports: handle separately (multiple files)
  Future<void> _selectAndExportIndividual() async {
    if (_selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn ít nhất 1 đơn hàng'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final outputType = await _showOutputChoice(context);
    if (outputType == null || !mounted) return;

    final selectedOrders = widget.orders
        .where((o) => _selectedOrderIds.contains(o.order.id))
        .toList();

    // Close sheet first
    Navigator.of(context).pop();

    // Then export each order as separate file (from parent context)
    if (!mounted) return;
    await _exportIndividualOrders(
      context: context,
      selectedOrders: selectedOrders,
      outputType: outputType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sessionCode = InvoiceCode.session(widget.session.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.picture_as_pdf,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xuất hóa đơn',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        'Mã phiên: $sessionCode • ${widget.orders.length} đơn',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xuất nhanh',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  // Option 1: All (summary)
                  _ExportTile(
                    icon: Icons.summarize,
                    gradient: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    title: 'Bản tóm tắt phiên',
                    subtitle:
                        '${widget.orders.length} đơn (Mua: $_buyCount, Bán: $_sellCount) + lợi nhuận',
                    onTap: widget.orders.isNotEmpty
                        ? () => _selectAndExport(InvoiceFilter.all)
                        : null,
                  ),
                  const SizedBox(height: 8),

                  // Option 2: Buy only
                  _ExportTile(
                    icon: Icons.shopping_cart_outlined,
                    gradient: [OceanTheme.buyBlue, const Color(0xFF64B5F6)],
                    title: 'Tất cả đơn mua vào',
                    subtitle: '$_buyCount đơn mua',
                    onTap: _buyCount > 0
                        ? () => _selectAndExport(InvoiceFilter.buy)
                        : null,
                  ),
                  const SizedBox(height: 8),

                  // Option 3: Sell only
                  _ExportTile(
                    icon: Icons.storefront_outlined,
                    gradient: [OceanTheme.sellGreen, const Color(0xFF81C784)],
                    title: 'Tất cả đơn bán ra',
                    subtitle: '$_sellCount đơn bán',
                    onTap: _sellCount > 0
                        ? () => _selectAndExport(InvoiceFilter.sell)
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // Option 4: Select individual
                  Row(
                    children: [
                      Text('Chọn lẻ từng đơn',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (!_isSelectMode)
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _isSelectMode = true),
                          icon: const Icon(Icons.checklist, size: 18),
                          label: const Text('Chọn đơn'),
                        )
                      else ...[
                        TextButton(
                          onPressed: () => setState(() {
                            _isSelectMode = false;
                            _selectedOrderIds.clear();
                          }),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 4),
                        FilledButton.icon(
                          onPressed: _selectedOrderIds.isNotEmpty
                              ? _selectAndExportIndividual
                              : null,
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: Text(
                              'Xuất ${_selectedOrderIds.length} đơn riêng'),
                        ),
                      ],
                    ],
                  ),

                  if (_isSelectMode) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Mỗi đơn được chọn sẽ được xuất thành 1 file PDF riêng biệt',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectableOrderList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableOrderList() {
    return Column(
      children: widget.orders.map((order) {
        final isBuy = order.order.orderType == 'buy';
        final isSelected = _selectedOrderIds.contains(order.order.id);
        final accentColor = isBuy ? OceanTheme.buyBlue : OceanTheme.sellGreen;
        final subtotal = (Decimal.fromInt(order.order.subtotalInCents) /
                Decimal.fromInt(100))
            .toDecimal();

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 6),
          color: isSelected
              ? accentColor.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: ListTile(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedOrderIds.remove(order.order.id);
                } else {
                  _selectedOrderIds.add(order.order.id);
                }
              });
            },
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected
                    ? Icons.check
                    : (isBuy ? Icons.shopping_cart : Icons.storefront),
                color: isSelected ? Colors.white : accentColor,
                size: 20,
              ),
            ),
            title: Text(
              '${isBuy ? "Mua vào" : "Bán ra"}${order.partnerName != null ? " — ${order.partnerName}" : ""}',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              '${order.items.length} sản phẩm • ${AppFormatters.currency(subtotal)}',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedOrderIds.add(order.order.id);
                  } else {
                    _selectedOrderIds.remove(order.order.id);
                  }
                });
              },
              activeColor: accentColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// === WIDGETS ===

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ExportTile({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: enabled
                    ? gradient[0].withValues(alpha: 0.25)
                    : cs.outlineVariant.withValues(alpha: 0.3),
              ),
              color: enabled
                  ? gradient[0].withValues(alpha: 0.04)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: enabled
                        ? LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: enabled ? null : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color:
                                enabled ? cs.onSurface : cs.onSurfaceVariant,
                          )),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
                if (enabled)
                  Icon(Icons.chevron_right,
                      color: gradient[0].withValues(alpha: 0.6))
                else
                  Icon(Icons.block, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OutputCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        trailing: Icon(Icons.arrow_forward_ios, color: color, size: 16),
      ),
    );
  }
}
