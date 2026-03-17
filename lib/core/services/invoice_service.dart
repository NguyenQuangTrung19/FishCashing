/// Invoice PDF generation service for FishCash POS.
///
/// Uses NotoSans fonts for full Vietnamese diacritical support.
/// Features:
/// - Invoice codes: PGD (session), HDM (buy), HDB (sell), HD (individual)
/// - Buy/sell grouping with separators for "all" mode
/// - Profit only shown in "all" (internal summary) mode
/// - Premium styled PDF with colored sections
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/core/utils/unit_converter.dart';
import 'package:fishcash_pos/core/constants/app_constants.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/repositories/trading_session_repository.dart';
import 'package:fishcash_pos/data/repositories/debt_repository.dart';

/// Filter mode for invoice export
enum InvoiceFilter { all, buy, sell }

// =============================================
// FONTS
// =============================================

/// Vietnamese-compatible fonts for PDF
class InvoiceFonts {
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font italic;
  final pw.Font boldItalic;

  const InvoiceFonts({
    required this.regular,
    required this.bold,
    required this.italic,
    required this.boldItalic,
  });

  static Future<InvoiceFonts> load() async {
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final italic = await PdfGoogleFonts.notoSansItalic();
    final boldItalic = await PdfGoogleFonts.notoSansBoldItalic();
    return InvoiceFonts(
      regular: regular,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
    );
  }

  pw.ThemeData get theme => pw.ThemeData(
        defaultTextStyle: pw.TextStyle(font: regular, fontBold: bold),
      );

  pw.TextStyle style({
    double? fontSize,
    pw.FontWeight? fontWeight,
    pw.FontStyle? fontStyle,
    PdfColor? color,
    double? letterSpacing,
  }) {
    pw.Font f = regular;
    if (fontWeight == pw.FontWeight.bold &&
        fontStyle == pw.FontStyle.italic) {
      f = boldItalic;
    } else if (fontWeight == pw.FontWeight.bold) {
      f = bold;
    } else if (fontStyle == pw.FontStyle.italic) {
      f = italic;
    }
    return pw.TextStyle(
      font: f,
      fontBold: bold,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}

// =============================================
// INVOICE CODES
// =============================================

class InvoiceCode {
  InvoiceCode._();

  /// Session code: PGD + ddMMyyyy + 3-digit index
  /// Example: PGD15032026001
  static String session(DateTime date, {int index = 1}) {
    return 'PGD${_dateStr(date)}${_idx(index)}';
  }

  /// All buy orders invoice: HDM + ddMMyyyy + 3-digit index
  static String buyInvoice(DateTime date, {int index = 1}) {
    return 'HDM${_dateStr(date)}${_idx(index)}';
  }

  /// All sell orders invoice: HDB + ddMMyyyy + 3-digit index
  static String sellInvoice(DateTime date, {int index = 1}) {
    return 'HDB${_dateStr(date)}${_idx(index)}';
  }

  /// Individual order invoice: HD + ddMMyyyy + 3-digit index
  static String orderInvoice(DateTime date, {int index = 1}) {
    return 'HD${_dateStr(date)}${_idx(index)}';
  }

  /// Generate code based on filter
  static String forFilter(InvoiceFilter filter, DateTime date,
      {int index = 1}) {
    switch (filter) {
      case InvoiceFilter.all:
        return session(date, index: index);
      case InvoiceFilter.buy:
        return buyInvoice(date, index: index);
      case InvoiceFilter.sell:
        return sellInvoice(date, index: index);
    }
  }

  static String _dateStr(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd$mm$yyyy';
  }

  static String _idx(int i) => i.toString().padLeft(3, '0');
}

// =============================================
// INVOICE SERVICE
// =============================================

class InvoiceService {
  InvoiceService._();

  // Brand colors
  static const _brandDark = PdfColor.fromInt(0xFF023E8A);
  static const _brandPrimary = PdfColor.fromInt(0xFF0077B6);
  static const _buyColor = PdfColor.fromInt(0xFF1565C0);
  static const _sellColor = PdfColor.fromInt(0xFF2E7D32);
  static const _profitColor = PdfColor.fromInt(0xFFF4A261);
  static const _lossColor = PdfColor.fromInt(0xFFD32F2F);
  static const _buyBg = PdfColor.fromInt(0xFFE3F2FD);
  static const _sellBg = PdfColor.fromInt(0xFFE8F5E9);
  static const _accentBg = PdfColor.fromInt(0xFFF0F7FF);

  // =============================================
  // SESSION INVOICE (all / buy-only / sell-only)
  // =============================================

  static Future<pw.Document> generateSessionInvoice({
    required InvoiceFonts fonts,
    required TradingSessionModel session,
    required List<TradeOrderWithDetails> orders,
    InvoiceFilter filter = InvoiceFilter.all,
    String storeName = 'FishCash POS',
    String storeAddress = '',
    String storePhone = '',
    String storeLogoPath = '',
    int sessionIndex = 1,
  }) async {
    final invoiceCode =
        InvoiceCode.forFilter(filter, session.createdAt, index: sessionIndex);

    final logoBytes = await _loadLogo(storeLogoPath);

    final pdf = pw.Document(
      author: storeName,
      title: '$invoiceCode - ${_filterTitle(filter)}',
      theme: fonts.theme,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _buildHeader(
          fonts: fonts,
          logoBytes: logoBytes,
          invoiceCode: invoiceCode,
          title: _filterTitle(filter),
          subtitle:
              'Ngày: ${AppFormatters.dateTime(session.createdAt)}',
          storeName: storeName,
          storeAddress: storeAddress,
          storePhone: storePhone,
        ),
        footer: (ctx) => _buildFooter(ctx, storeName, fonts),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          // Summary bar
          widgets.add(_buildSummaryBar(session, filter, fonts));
          widgets.add(pw.SizedBox(height: 14));

          // Note
          if (session.note.isNotEmpty) {
            widgets.add(_buildNoteBox(session.note, fonts));
            widgets.add(pw.SizedBox(height: 14));
          }

          if (filter == InvoiceFilter.all) {
            // === ALL MODE: group buy first, then sell ===
            final buyOrders =
                orders.where((o) => o.order.orderType == 'buy').toList();
            final sellOrders =
                orders.where((o) => o.order.orderType == 'sell').toList();

            if (buyOrders.isNotEmpty) {
              widgets.add(_buildSectionHeader(
                  'ĐƠN MUA VÀO', '${buyOrders.length} đơn', _buyColor, fonts));
              widgets.add(pw.SizedBox(height: 8));
              for (var i = 0; i < buyOrders.length; i++) {
                widgets.add(_buildOrderSection(buyOrders[i], i + 1, fonts));
              }
            }

            if (buyOrders.isNotEmpty && sellOrders.isNotEmpty) {
              // Force sell section to start on a NEW PAGE
              widgets.add(pw.NewPage());
            }

            if (sellOrders.isNotEmpty) {
              widgets.add(_buildSectionHeader('ĐƠN BÁN RA',
                  '${sellOrders.length} đơn', _sellColor, fonts));
              widgets.add(pw.SizedBox(height: 8));
              for (var i = 0; i < sellOrders.length; i++) {
                widgets
                    .add(_buildOrderSection(sellOrders[i], i + 1, fonts));
              }
            }
          } else {
            // === BUY or SELL ONLY: simple list ===
            final filtered = filter == InvoiceFilter.buy
                ? orders.where((o) => o.order.orderType == 'buy').toList()
                : orders.where((o) => o.order.orderType == 'sell').toList();

            for (var i = 0; i < filtered.length; i++) {
              widgets.add(_buildOrderSection(filtered[i], i + 1, fonts));
            }
          }

          // Grand total
          widgets.add(pw.SizedBox(height: 12));
          widgets.add(_buildGrandTotalBar(orders, filter, fonts));
          widgets.add(pw.SizedBox(height: 20));
          widgets.add(_buildSignatureArea(fonts));

          return widgets;
        },
      ),
    );

    return pdf;
  }

  // =============================================
  // SINGLE ORDER INVOICE
  // =============================================

  static Future<pw.Document> generateSingleOrderInvoice({
    required InvoiceFonts fonts,
    required TradeOrderWithDetails order,
    String storeName = 'FishCash POS',
    String storeAddress = '',
    String storePhone = '',
    String storeLogoPath = '',
    int orderIndex = 1,
  }) async {
    final isBuy = order.order.orderType == 'buy';
    final invoiceCode = InvoiceCode.orderInvoice(
      order.order.createdAt,
      index: orderIndex,
    );
    final title = isBuy ? 'HÓA ĐƠN MUA HÀNG' : 'HÓA ĐƠN BÁN HÀNG';

    final logoBytes = await _loadLogo(storeLogoPath);

    final pdf = pw.Document(
      author: storeName,
      title: '$invoiceCode - $title',
      theme: fonts.theme,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(
              fonts: fonts,
              logoBytes: logoBytes,
              invoiceCode: invoiceCode,
              title: title,
              subtitle:
                  'Ngày: ${AppFormatters.dateTime(order.order.createdAt)}',
              storeName: storeName,
              storeAddress: storeAddress,
              storePhone: storePhone,
            ),
            pw.SizedBox(height: 20),
            _buildInfoRow(order, fonts),
            pw.SizedBox(height: 16),
            _buildItemsTable(order.items, isBuy, fonts),
            pw.SizedBox(height: 14),
            _buildSubtotalBox(order.order.subtotalInCents, isBuy, fonts),
            pw.Spacer(),
            _buildSignatureArea(fonts),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Xuất ngày: ${AppFormatters.dateTime(DateTime.now())}',
                  style: fonts.style(fontSize: 8, color: PdfColors.grey500),
                ),
                pw.Text(storeName,
                    style:
                        fonts.style(fontSize: 8, color: PdfColors.grey500)),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  // =============================================
  // FILE NAMING
  // =============================================

  /// File name for session/filter invoices: just the code
  static String sessionFileName(DateTime date, InvoiceFilter filter,
      {int index = 1}) {
    return '${InvoiceCode.forFilter(filter, date, index: index)}.pdf';
  }

  /// File name for individual order: code + partner name
  static String orderFileName(
    DateTime date, {
    int index = 1,
    String? partnerName,
  }) {
    final code = InvoiceCode.orderInvoice(date, index: index);
    if (partnerName != null && partnerName.isNotEmpty) {
      final safeName = partnerName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      return '${code}_$safeName.pdf';
    }
    return '$code.pdf';
  }

  // =============================================
  // PRIVATE: LOGO LOADER
  // =============================================

  /// Load logo bytes from custom path or fallback to default asset.
  static Future<Uint8List> _loadLogo(String customPath) async {
    if (customPath.isNotEmpty) {
      final file = File(customPath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }
    // Fallback to default asset logo
    return (await rootBundle.load('assets/images/logo_icon.png'))
        .buffer
        .asUint8List();
  }

  // =============================================
  // PRIVATE: HEADER
  // =============================================

  static pw.Widget _buildHeader({
    required InvoiceFonts fonts,
    required Uint8List logoBytes,
    required String invoiceCode,
    required String title,
    required String subtitle,
    String storeName = '',
    String storeAddress = '',
    String storePhone = '',
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _brandDark,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(
                pw.MemoryImage(logoBytes),
                width: 180,
                fit: pw.BoxFit.contain,
              ),
            ],
          ),
          // Store name
          if (storeName.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(storeName,
                style: fonts.style(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 0.5,
                )),
          ],
          // Store contact info
          if (storeAddress.isNotEmpty || storePhone.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            if (storeAddress.isNotEmpty)
              pw.Text(storeAddress,
                  style: fonts.style(fontSize: 9, color: PdfColors.grey300)),
            if (storePhone.isNotEmpty)
              pw.Text('SĐT: $storePhone',
                  style: fonts.style(fontSize: 9, color: PdfColors.grey300)),
          ],
          pw.SizedBox(height: 6),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: pw.BoxDecoration(
              color: _brandPrimary,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(title,
                style: fonts.style(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 1,
                )),
          ),
          pw.SizedBox(height: 6),
          // Invoice code
          pw.Text('Mã: $invoiceCode',
              style: fonts.style(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.yellow100,
              )),
          pw.SizedBox(height: 4),
          pw.Text(subtitle,
              style: fonts.style(fontSize: 10, color: PdfColors.grey300)),
        ],
      ),
    );
  }

  // =============================================
  // PRIVATE: FOOTER
  // =============================================

  static pw.Widget _buildFooter(
      pw.Context context, String storeName, InvoiceFonts fonts) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Xuất ngày: ${AppFormatters.dateTime(DateTime.now())}',
              style: fonts.style(fontSize: 8, color: PdfColors.grey500)),
          pw.Text(
              'Trang ${context.pageNumber}/${context.pagesCount}',
              style: fonts.style(fontSize: 8, color: PdfColors.grey500)),
          pw.Text(storeName,
              style: fonts.style(fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  // =============================================
  // PRIVATE: SUMMARY BAR
  // =============================================

  static pw.Widget _buildSummaryBar(
    TradingSessionModel session,
    InvoiceFilter filter,
    InvoiceFonts fonts,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _accentBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFBBDEFB)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          if (filter == InvoiceFilter.all || filter == InvoiceFilter.buy)
            _summaryPill('TỔNG MUA VÀO',
                AppFormatters.currency(session.totalBuy), _buyColor, _buyBg,
                fonts),
          if (filter == InvoiceFilter.all || filter == InvoiceFilter.sell)
            _summaryPill('TỔNG BÁN RA',
                AppFormatters.currency(session.totalSell), _sellColor, _sellBg,
                fonts),
          // Profit ONLY in "all" mode (internal summary)
          if (filter == InvoiceFilter.all)
            _summaryPill(
              'LỢI NHUẬN',
              AppFormatters.currency(session.profit),
              session.profit >= Decimal.zero ? _profitColor : _lossColor,
              PdfColors.grey100,
              fonts,
            ),
        ],
      ),
    );
  }

  static pw.Widget _summaryPill(String label, String value,
      PdfColor textColor, PdfColor bgColor, InvoiceFonts fonts) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: bgColor, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(children: [
        pw.Text(label,
            style: fonts.style(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
                letterSpacing: 0.5)),
        pw.SizedBox(height: 3),
        pw.Text(value,
            style: fonts.style(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: textColor)),
      ]),
    );
  }

  // =============================================
  // PRIVATE: SECTION HEADER + SEPARATOR
  // =============================================

  static pw.Widget _buildSectionHeader(
      String title, String count, PdfColor color, InvoiceFonts fonts) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title,
              style: fonts.style(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 12,
                letterSpacing: 0.5,
              )),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Text(count,
                style: fonts.style(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
          ),
        ],
      ),
    );
  }



  // =============================================
  // PRIVATE: NOTE BOX
  // =============================================

  static pw.Widget _buildNoteBox(String note, InvoiceFonts fonts) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF8E1),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFFFE082)),
      ),
      child: pw.Text('Ghi chú: $note', style: fonts.style(fontSize: 10)),
    );
  }

  // =============================================
  // PRIVATE: INFO ROW (single order)
  // =============================================

  static pw.Widget _buildInfoRow(
      TradeOrderWithDetails order, InvoiceFonts fonts) {
    final isBuy = order.order.orderType == 'buy';
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: isBuy ? _buyBg : _sellBg,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(children: [
        if (order.partnerName != null) ...[
          pw.Text(isBuy ? 'Nhà cung cấp: ' : 'Khách hàng: ',
              style:
                  fonts.style(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text(order.partnerName!,
              style: fonts.style(fontSize: 10)),
          pw.SizedBox(width: 20),
        ],
        pw.Text('Loại: ',
            style:
                fonts.style(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: pw.BoxDecoration(
            color: isBuy ? _buyColor : _sellColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(isBuy ? 'MUA' : 'BÁN',
              style: fonts.style(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              )),
        ),
      ]),
    );
  }

  // =============================================
  // PRIVATE: ORDER SECTION
  // =============================================

  static pw.Widget _buildOrderSection(
    TradeOrderWithDetails order,
    int orderNumber,
    InvoiceFonts fonts,
  ) {
    final isBuy = order.order.orderType == 'buy';
    final accentColor = isBuy ? _buyColor : _sellColor;
    final bgColor = isBuy ? _buyBg : _sellBg;
    final typeLabel = isBuy ? 'MUA VÀO' : 'BÁN RA';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: accentColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(7),
                topRight: pw.Radius.circular(7),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Đơn #$orderNumber — $typeLabel',
                    style: fonts.style(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 11,
                    )),
                if (order.partnerName != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(order.partnerName!,
                        style: fonts.style(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                          color: accentColor,
                        )),
                  ),
              ],
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: bgColor,
            child: pw.Text(
              'Thời gian: ${AppFormatters.dateTime(order.order.createdAt)}',
              style: fonts.style(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4),
            child: _buildItemsTable(order.items, isBuy, fonts),
          ),
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: bgColor,
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(7),
                bottomRight: pw.Radius.circular(7),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Tổng đơn:  ',
                    style: fonts.style(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    _formatCurrency(order.order.subtotalInCents),
                    style: fonts.style(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // PRIVATE: ITEMS TABLE
  // =============================================

  static pw.Widget _buildItemsTable(
    List<OrderItemWithProduct> items,
    bool isBuy,
    InvoiceFonts fonts,
  ) {
    final headerColor = isBuy ? _buyColor : _sellColor;
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder(
        horizontalInside:
            const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        left: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        right: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      headerStyle: fonts.style(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: headerColor),
      headerAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      cellStyle: fonts.style(fontSize: 9),
      cellPadding:
          const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      oddRowDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF9FAFB)),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.8),
        3: const pw.FlexColumnWidth(1.8),
        4: const pw.FlexColumnWidth(2),
      },
      headers: ['#', 'Sản phẩm', 'Số lượng', 'Đơn giá', 'Thành tiền'],
      data: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final baseQty = _gramsToDecimal(item.item.quantityInGrams);
        final displayUnit = item.item.unit;
        // Convert base quantity (kg) to display unit (e.g. tấn, tạ, yến)
        final displayQty = UnitConverter.convertQuantity(
              baseQty, UnitConstants.kg, displayUnit,
            ) ??
            baseQty;
        return [
          '${i + 1}',
          item.productName,
          '${AppFormatters.quantity(displayQty)} $displayUnit',
          _formatCurrency(item.item.unitPriceInCents),
          _formatCurrency(item.item.lineTotalInCents),
        ];
      }).toList(),
    );
  }

  // =============================================
  // PRIVATE: SUBTOTAL / GRAND TOTAL
  // =============================================

  static pw.Widget _buildSubtotalBox(
      int subtotalInCents, bool isBuy, InvoiceFonts fonts) {
    final color = isBuy ? _buyColor : _sellColor;
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: pw.BoxDecoration(
          color: color, borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Text(
          'TỔNG CỘNG: ${_formatCurrency(subtotalInCents)}',
          style: fonts.style(
            fontWeight: pw.FontWeight.bold,
            fontSize: 15,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildGrandTotalBar(
    List<TradeOrderWithDetails> orders,
    InvoiceFilter filter,
    InvoiceFonts fonts,
  ) {
    final buyTotal = orders
        .where((o) => o.order.orderType == 'buy')
        .fold<int>(0, (s, o) => s + o.order.subtotalInCents);
    final sellTotal = orders
        .where((o) => o.order.orderType == 'sell')
        .fold<int>(0, (s, o) => s + o.order.subtotalInCents);
    final total =
        orders.fold<int>(0, (s, o) => s + o.order.subtotalInCents);

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _brandDark, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            if (buyTotal > 0 &&
                (filter == InvoiceFilter.all || filter == InvoiceFilter.buy))
              _totalItem('Tổng mua', _formatCurrency(buyTotal), fonts),
            if (sellTotal > 0 &&
                (filter == InvoiceFilter.all || filter == InvoiceFilter.sell))
              _totalItem('Tổng bán', _formatCurrency(sellTotal), fonts),
          ],
        ),
        if (buyTotal > 0 || sellTotal > 0) pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _brandPrimary,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('TỔNG CỘNG (${orders.length} đơn):   ',
                  style: fonts.style(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                    color: PdfColors.white,
                  )),
              pw.Text(_formatCurrency(total),
                  style: fonts.style(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    color: PdfColors.white,
                  )),
            ],
          ),
        ),
      ]),
    );
  }

  static pw.Widget _totalItem(
      String label, String value, InvoiceFonts fonts) {
    return pw.Column(children: [
      pw.Text(label,
          style: fonts.style(fontSize: 9, color: PdfColors.grey300)),
      pw.SizedBox(height: 2),
      pw.Text(value,
          style: fonts.style(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          )),
    ]);
  }

  // =============================================
  // PRIVATE: SIGNATURE
  // =============================================

  static pw.Widget _buildSignatureArea(InvoiceFonts fonts) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          _signatureBlock('Người mua', fonts),
          _signatureBlock('Người bán', fonts),
        ],
      ),
    );
  }

  static pw.Widget _signatureBlock(String label, InvoiceFonts fonts) {
    return pw.Column(children: [
      pw.Text(label,
          style:
              fonts.style(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      pw.SizedBox(height: 4),
      pw.Text('(Ký, ghi rõ họ tên)',
          style: fonts.style(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey500)),
      pw.SizedBox(height: 40),
      pw.Container(width: 120, height: 1, color: PdfColors.grey400),
    ]);
  }

  // =============================================
  // HELPERS
  // =============================================

  static String _filterTitle(InvoiceFilter filter) {
    switch (filter) {
      case InvoiceFilter.all:
        return 'BẢN TÓM TẮT PHIÊN GIAO DỊCH';
      case InvoiceFilter.buy:
        return 'HÓA ĐƠN MUA HÀNG — PHIÊN GIAO DỊCH';
      case InvoiceFilter.sell:
        return 'HÓA ĐƠN BÁN HÀNG — PHIÊN GIAO DỊCH';
    }
  }

  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VNĐ',
    decimalDigits: 0,
  );

  static String _formatCurrency(int cents) {
    return _currencyFormat.format(cents / 100);
  }

  static Decimal _gramsToDecimal(int grams) {
    return (Decimal.fromInt(grams) / Decimal.fromInt(1000)).toDecimal(
      scaleOnInfinitePrecision: 3,
    );
  }

  // =============================================
  // DEBT INVOICE
  // =============================================

  /// Generate a debt statement PDF for a partner
  static Future<Uint8List> generateDebtInvoice({
    required InvoiceFonts fonts,
    required String partnerName,
    required List<DebtOrderDetail> orders,
    required Decimal totalDebt,
    required String storeName,
    String storeAddress = '',
    String storePhone = '',
    String? storeLogoPath,
  }) async {
    final pdf = pw.Document(theme: fonts.theme);
    final now = DateTime.now();
    final code = 'CN${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';

    // Load logo if available
    pw.ImageProvider? logoImage;
    if (storeLogoPath != null && storeLogoPath.isNotEmpty) {
      try {
        final logoFile = File(storeLogoPath);
        if (await logoFile.exists()) {
          final bytes = await logoFile.readAsBytes();
          logoImage = pw.MemoryImage(bytes);
        }
      } catch (_) {}
    }

    // Calculate totals
    final totalOrder = orders.fold(Decimal.zero, (s, o) => s + o.subtotal);
    final totalPaid = orders.fold(Decimal.zero, (s, o) => s + o.totalPaid);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null) ...[
                    pw.Image(logoImage, width: 70, height: 70),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(storeName,
                            style: fonts.style(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: _brandDark)),
                        if (storeAddress.isNotEmpty)
                          pw.Text(storeAddress,
                              style:
                                  fonts.style(fontSize: 9, color: PdfColors.grey700)),
                        if (storePhone.isNotEmpty)
                          pw.Text('ĐT: $storePhone',
                              style:
                                  fonts.style(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('BẢNG CÔNG NỢ',
                          style: fonts.style(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFFD32F2F))),
                      pw.SizedBox(height: 4),
                      pw.Text('Mã: $code',
                          style: fonts.style(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text(
                          'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}',
                          style: fonts.style(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Partner info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFF3E0),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('Đối tác: ',
                        style: fonts.style(fontSize: 11, color: PdfColors.grey800)),
                    pw.Text(partnerName,
                        style: fonts.style(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Orders table
              pw.Text('CHI TIẾT ĐƠN HÀNG',
                  style: fonts.style(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _brandDark)),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE3F2FD)),
                headerStyle: fonts.style(
                    fontSize: 9, fontWeight: pw.FontWeight.bold, color: _brandDark),
                cellStyle: fonts.style(fontSize: 9),
                headerAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
                headers: ['#', 'Ngày', 'Loại', 'Tổng đơn', 'Đã trả', 'Còn nợ'],
                data: [
                  for (int i = 0; i < orders.length; i++)
                    [
                      '${i + 1}',
                      DateFormat('dd/MM/yyyy').format(orders[i].orderDate),
                      orders[i].orderType == 'buy' ? 'Mua' : 'Bán',
                      _currencyFormat.format(orders[i].subtotal.toDouble()),
                      _currencyFormat.format(orders[i].totalPaid.toDouble()),
                      _currencyFormat.format(orders[i].remaining.toDouble()),
                    ],
                ],
              ),
              pw.SizedBox(height: 16),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: totalDebt > Decimal.zero
                      ? const PdfColor.fromInt(0xFFFFEBEE)
                      : const PdfColor.fromInt(0xFFE8F5E9),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                    color: totalDebt > Decimal.zero
                        ? const PdfColor.fromInt(0xFFD32F2F)
                        : const PdfColor.fromInt(0xFF2E7D32),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Tổng giá trị đơn: ${_currencyFormat.format(totalOrder.toDouble())}',
                            style: fonts.style(fontSize: 10)),
                        pw.Text('Đã thanh toán: ${_currencyFormat.format(totalPaid.toDouble())}',
                            style: fonts.style(fontSize: 10, color: PdfColors.green800)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('TỔNG CÔNG NỢ',
                            style: fonts.style(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700)),
                        pw.Text(
                          _currencyFormat.format(totalDebt.toDouble()),
                          style: fonts.style(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: totalDebt > Decimal.zero
                                ? const PdfColor.fromInt(0xFFD32F2F)
                                : const PdfColor.fromInt(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Signature area
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Người lập',
                          style: fonts.style(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 40),
                      pw.Text('(Ký, ghi rõ họ tên)',
                          style: fonts.style(
                              fontSize: 8, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Đối tác xác nhận',
                          style: fonts.style(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 40),
                      pw.Text('(Ký, ghi rõ họ tên)',
                          style: fonts.style(
                              fontSize: 8, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // =============================================
  // DEBT SUMMARY — tóm tắt only (no signatures)
  // =============================================

  /// Generate a debt summary PDF (summary table only).
  /// Page 1: Summary table of all receivables + payables.
  static Future<Uint8List> generateDebtSummaryWithSignatures({
    required InvoiceFonts fonts,
    required List<DebtSummary> receivables,
    required List<DebtSummary> payables,
    required String storeName,
    String storeAddress = '',
    String storePhone = '',
    String? storeLogoPath,
  }) async {
    final pdf = pw.Document(theme: fonts.theme);
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // Load logo
    pw.ImageProvider? logoImage;
    if (storeLogoPath != null && storeLogoPath.isNotEmpty) {
      try {
        final logoFile = File(storeLogoPath);
        if (await logoFile.exists()) {
          final bytes = await logoFile.readAsBytes();
          logoImage = pw.MemoryImage(bytes);
        }
      } catch (_) {}
    }

    final totalReceivable =
        receivables.fold(Decimal.zero, (s, d) => s + d.debt);
    final totalPayable = payables.fold(Decimal.zero, (s, d) => s + d.debt);
    final netDebt = totalReceivable - totalPayable;

    // ---- PAGE 1: Summary table ----
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null) ...[
                    pw.Image(logoImage, width: 70, height: 70),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(storeName,
                            style: fonts.style(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: _brandDark)),
                        if (storeAddress.isNotEmpty)
                          pw.Text(storeAddress,
                              style: fonts.style(
                                  fontSize: 9, color: PdfColors.grey700)),
                        if (storePhone.isNotEmpty)
                          pw.Text('ĐT: $storePhone',
                              style: fonts.style(
                                  fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('TÓM TẮT CÔNG NỢ',
                          style: fonts.style(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: _brandDark)),
                      pw.SizedBox(height: 4),
                      pw.Text('Ngày: $dateStr',
                          style: fonts.style(
                              fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Receivables table
              if (receivables.isNotEmpty) ...[
                pw.Text('PHẢI THU (Khách nợ mình)',
                    style: fonts.style(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF2E7D32))),
                pw.SizedBox(height: 6),
                _debtSummaryTable(fonts, receivables),
                pw.SizedBox(height: 6),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                      'Tổng phải thu: ${_currencyFormat.format(totalReceivable.toDouble())}',
                      style: fonts.style(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF2E7D32))),
                ),
                pw.SizedBox(height: 16),
              ],

              // Payables table
              if (payables.isNotEmpty) ...[
                pw.Text('PHẢI TRẢ (Mình nợ NCC)',
                    style: fonts.style(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFFD32F2F))),
                pw.SizedBox(height: 6),
                _debtSummaryTable(fonts, payables),
                pw.SizedBox(height: 6),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                      'Tổng phải trả: ${_currencyFormat.format(totalPayable.toDouble())}',
                      style: fonts.style(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFFD32F2F))),
                ),
                pw.SizedBox(height: 16),
              ],

              pw.Divider(),
              pw.SizedBox(height: 8),

              // Net balance
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF0F7FF),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: _brandPrimary),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('CÂN ĐỐI CÔNG NỢ',
                        style: fonts.style(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _brandDark)),
                    pw.Text(
                      _currencyFormat.format(netDebt.toDouble()),
                      style: fonts.style(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: netDebt > Decimal.zero
                            ? const PdfColor.fromInt(0xFF2E7D32)
                            : const PdfColor.fromInt(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                netDebt > Decimal.zero
                    ? '(Bạn đang được nợ nhiều hơn)'
                    : netDebt < Decimal.zero
                        ? '(Bạn đang nợ nhiều hơn)'
                        : '(Cân bằng)',
                style: fonts.style(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // =============================================
  // PARTNER SIGNATURE SHEET — 1 partner
  // =============================================

  /// Generate a signature sheet PDF for a single partner.
  static Future<Uint8List> generatePartnerSignatureSheet({
    required InvoiceFonts fonts,
    required DebtSummary partner,
    required String debtType,
    required String storeName,
    String storeAddress = '',
    String storePhone = '',
    String? storeLogoPath,
  }) async {
    final pdf = pw.Document(theme: fonts.theme);
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // Load logo
    pw.ImageProvider? logoImage;
    if (storeLogoPath != null && storeLogoPath.isNotEmpty) {
      try {
        final logoFile = File(storeLogoPath);
        if (await logoFile.exists()) {
          final bytes = await logoFile.readAsBytes();
          logoImage = pw.MemoryImage(bytes);
        }
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null) ...[
                    pw.Image(logoImage, width: 70, height: 70),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(storeName,
                            style: fonts.style(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: _brandDark)),
                        if (storeAddress.isNotEmpty)
                          pw.Text(storeAddress,
                              style: fonts.style(
                                  fontSize: 9, color: PdfColors.grey700)),
                        if (storePhone.isNotEmpty)
                          pw.Text('ĐT: $storePhone',
                              style: fonts.style(
                                  fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Text('Ngày: $dateStr',
                      style: fonts.style(
                          fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 20),

              pw.Center(
                child: pw.Text('GIẤY XÁC NHẬN CÔNG NỢ',
                    style: fonts.style(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: _brandDark)),
              ),
              pw.SizedBox(height: 24),

              // Partner info
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFF3E0),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('Đối tác: ',
                            style: fonts.style(
                                fontSize: 12, color: PdfColors.grey800)),
                        pw.Text(partner.partnerName,
                            style: fonts.style(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    if (partner.partnerPhone.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('SĐT: ${partner.partnerPhone}',
                          style: fonts.style(
                              fontSize: 10, color: PdfColors.grey700)),
                    ],
                    pw.SizedBox(height: 4),
                    pw.Text('Loại: $debtType',
                        style: fonts.style(
                            fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Debt details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Tổng giá trị đơn hàng:',
                          style: fonts.style(fontSize: 11)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          _currencyFormat
                              .format(partner.totalOrder.toDouble()),
                          style: fonts.style(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Đã thanh toán:',
                          style: fonts.style(
                              fontSize: 11, color: PdfColors.green800)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          _currencyFormat
                              .format(partner.totalPaid.toDouble()),
                          style: fonts.style(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('CÒN NỢ:',
                          style: fonts.style(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFFD32F2F))),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          _currencyFormat.format(partner.debt.toDouble()),
                          style: fonts.style(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFFD32F2F))),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Confirmation text
              pw.Text(
                'Hai bên xác nhận số công nợ trên là chính xác. '
                'Bên nợ cam kết thanh toán đầy đủ theo thỏa thuận.',
                style: fonts.style(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 50),

              // Signature area
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('ĐẠI DIỆN CỬA HÀNG',
                          style: fonts.style(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('($storeName)',
                          style: fonts.style(
                              fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 60),
                      pw.Container(
                        width: 160,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColors.grey400, width: 0.5)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('(Ký, ghi rõ họ tên)',
                          style: fonts.style(
                              fontSize: 8,
                              fontStyle: pw.FontStyle.italic,
                              color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('ĐỐI TÁC XÁC NHẬN',
                          style: fonts.style(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('(${partner.partnerName})',
                          style: fonts.style(
                              fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 60),
                      pw.Container(
                        width: 160,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColors.grey400, width: 0.5)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('(Ký, ghi rõ họ tên)',
                          style: fonts.style(
                              fontSize: 8,
                              fontStyle: pw.FontStyle.italic,
                              color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Helper: build debt summary table for PDF
  static pw.Widget _debtSummaryTable(
      InvoiceFonts fonts, List<DebtSummary> debts) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE3F2FD)),
      headerStyle: fonts.style(
          fontSize: 9, fontWeight: pw.FontWeight.bold, color: _brandDark),
      cellStyle: fonts.style(fontSize: 9),
      headerAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      headers: ['#', 'Đối tác', 'Tổng đơn', 'Đã trả', 'Còn nợ'],
      data: [
        for (int i = 0; i < debts.length; i++)
          [
            '${i + 1}',
            debts[i].partnerName,
            _currencyFormat.format(debts[i].totalOrder.toDouble()),
            _currencyFormat.format(debts[i].totalPaid.toDouble()),
            _currencyFormat.format(debts[i].debt.toDouble()),
          ],
      ],
    );
  }
}
