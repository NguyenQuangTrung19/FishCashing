/// Repository for debt (công nợ) management.
///
/// Computes debt from Orders + Payments:
/// Debt per partner = SUM(order subtotals) - SUM(payments)
library;

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:uuid/uuid.dart';

// === MODELS ===

/// Debt summary for one partner
class DebtSummary {
  final String partnerId;
  final String partnerName;
  final String partnerPhone;
  final String partnerType; // 'supplier' or 'buyer'
  final Decimal totalOrder; // tổng giá trị đơn hàng
  final Decimal totalPaid; // tổng đã thanh toán
  final Decimal debt; // totalOrder - totalPaid

  DebtSummary({
    required this.partnerId,
    required this.partnerName,
    required this.partnerPhone,
    required this.partnerType,
    required this.totalOrder,
    required this.totalPaid,
    required this.debt,
  });

  bool get isFullyPaid => debt <= Decimal.zero;

  String get debtDisplay => AppFormatters.currency(debt);
  String get totalOrderDisplay => AppFormatters.currency(totalOrder);
  String get totalPaidDisplay => AppFormatters.currency(totalPaid);
}

/// Order detail with payment info (for partner detail view)
class DebtOrderDetail {
  final String orderId;
  final String orderType; // 'buy' or 'sell'
  final Decimal subtotal;
  final Decimal totalPaid;
  final Decimal remaining; // subtotal - totalPaid
  final String note;
  final DateTime orderDate;
  final String? sessionId;

  DebtOrderDetail({
    required this.orderId,
    required this.orderType,
    required this.subtotal,
    required this.totalPaid,
    required this.remaining,
    required this.note,
    required this.orderDate,
    this.sessionId,
  });

  bool get isFullyPaid => remaining <= Decimal.zero;
}

// === REPOSITORY ===

class DebtRepository {
  final TradeOrderDao _dao;
  static const _uuid = Uuid();

  DebtRepository(this._dao);

  Decimal _centsToCurrency(int cents) {
    return (Decimal.fromInt(cents) / Decimal.fromInt(100))
        .toDecimal(scaleOnInfinitePrecision: 2);
  }

  /// Get all receivables (khách nợ mình — from sell orders)
  Future<List<DebtSummary>> getReceivables() async {
    return _getDebt('receivable');
  }

  /// Get all payables (mình nợ NCC — from buy orders)
  Future<List<DebtSummary>> getPayables() async {
    return _getDebt('payable');
  }

  Future<List<DebtSummary>> _getDebt(String debtType) async {
    final rows = await _dao.getDebtByPartner(debtType);

    return rows.map((row) {
      final totalOrder = _centsToCurrency(row['totalOrderCents'] as int);
      final totalPaid = _centsToCurrency(row['totalPaidCents'] as int);

      return DebtSummary(
        partnerId: row['partnerId'] as String,
        partnerName: row['partnerName'] as String,
        partnerPhone: row['partnerPhone'] as String,
        partnerType: row['partnerType'] as String,
        totalOrder: totalOrder,
        totalPaid: totalPaid,
        debt: totalOrder - totalPaid,
      );
    }).toList();
  }

  /// Get order details for a specific partner
  Future<List<DebtOrderDetail>> getPartnerOrders(String partnerId) async {
    final rows = await _dao.getPartnerOrdersWithPayments(partnerId);

    return rows.map((row) {
      final subtotal = _centsToCurrency(row['subtotalCents'] as int);
      final totalPaid = _centsToCurrency(row['totalPaidCents'] as int);

      return DebtOrderDetail(
        orderId: row['orderId'] as String,
        orderType: row['orderType'] as String,
        subtotal: subtotal,
        totalPaid: totalPaid,
        remaining: subtotal - totalPaid,
        note: row['orderNote'] as String,
        orderDate: row['orderDate'] as DateTime,
        sessionId: row['sessionId'] as String?,
      );
    }).toList();
  }

  /// Record a payment against an order
  Future<void> addPayment({
    required String orderId,
    required int amountInCents,
    String note = '',
  }) async {
    await _dao.insertPayment(
      PaymentsCompanion.insert(
        id: _uuid.v4(),
        orderId: orderId,
        amountInCents: amountInCents,
        note: Value(note),
      ),
    );
  }
}
