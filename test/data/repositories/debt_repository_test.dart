/// Unit tests for DebtRepository.
///
/// Tests debt calculation logic: receivables, payables, payments.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/repositories/debt_repository.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:drift/drift.dart';

class MockTradeOrderDao extends Mock implements TradeOrderDao {}

// Required for mocktail to register fallback value for PaymentsCompanion
class FakePaymentsCompanion extends Fake implements PaymentsCompanion {}

void main() {
  late MockTradeOrderDao mockDao;
  late DebtRepository repository;

  setUpAll(() {
    registerFallbackValue(FakePaymentsCompanion());
  });

  setUp(() {
    mockDao = MockTradeOrderDao();
    repository = DebtRepository(mockDao);
  });

  group('DebtRepository', () {
    group('getReceivables', () {
      test('should return receivables from sell orders', () async {
        when(() => mockDao.getDebtByPartner('receivable'))
            .thenAnswer((_) async => [
                  {
                    'partnerId': 'partner1',
                    'partnerName': 'Nhà hàng ABC',
                    'partnerPhone': '0901234567',
                    'partnerType': 'buyer',
                    'totalOrderCents': 5000000, // 50,000 đ
                    'totalPaidCents': 3000000, // 30,000 đ
                  },
                ]);

        final result = await repository.getReceivables();

        expect(result.length, 1);
        expect(result.first.partnerName, 'Nhà hàng ABC');
        expect(result.first.totalOrder.toDouble(), 50000.0);
        expect(result.first.totalPaid.toDouble(), 30000.0);
        expect(result.first.debt.toDouble(), 20000.0);
        expect(result.first.isFullyPaid, false);
      });

      test('should return empty list when no receivables', () async {
        when(() => mockDao.getDebtByPartner('receivable'))
            .thenAnswer((_) async => []);

        final result = await repository.getReceivables();
        expect(result, isEmpty);
      });

      test('should detect fully paid partner', () async {
        when(() => mockDao.getDebtByPartner('receivable'))
            .thenAnswer((_) async => [
                  {
                    'partnerId': 'partner1',
                    'partnerName': 'Nhà hàng XYZ',
                    'partnerPhone': '',
                    'partnerType': 'buyer',
                    'totalOrderCents': 5000000,
                    'totalPaidCents': 5000000,
                  },
                ]);

        final result = await repository.getReceivables();
        expect(result.first.isFullyPaid, true);
        expect(result.first.debt.toDouble(), 0.0);
      });
    });

    group('getPayables', () {
      test('should return payables from buy orders', () async {
        when(() => mockDao.getDebtByPartner('payable'))
            .thenAnswer((_) async => [
                  {
                    'partnerId': 'supplier1',
                    'partnerName': 'Ghe Ông Ba',
                    'partnerPhone': '0987654321',
                    'partnerType': 'supplier',
                    'totalOrderCents': 10000000,
                    'totalPaidCents': 0,
                  },
                ]);

        final result = await repository.getPayables();

        expect(result.length, 1);
        expect(result.first.partnerName, 'Ghe Ông Ba');
        expect(result.first.debt.toDouble(), 100000.0);
        expect(result.first.isFullyPaid, false);
      });
    });

    group('getPartnerOrders', () {
      test('should return orders with payment status', () async {
        when(() => mockDao.getPartnerOrdersWithPayments('partner1'))
            .thenAnswer((_) async => [
                  {
                    'orderId': 'order1',
                    'orderType': 'sell',
                    'subtotalCents': 3000000,
                    'orderNote': 'Đơn bán 1',
                    'orderDate': DateTime(2026, 3, 16),
                    'sessionId': 'session1',
                    'totalPaidCents': 1000000,
                  },
                  {
                    'orderId': 'order2',
                    'orderType': 'sell',
                    'subtotalCents': 2000000,
                    'orderNote': '',
                    'orderDate': DateTime(2026, 3, 15),
                    'sessionId': null,
                    'totalPaidCents': 2000000,
                  },
                ]);

        final result = await repository.getPartnerOrders('partner1');

        expect(result.length, 2);
        // Order 1: partially paid
        expect(result[0].subtotal.toDouble(), 30000.0);
        expect(result[0].totalPaid.toDouble(), 10000.0);
        expect(result[0].remaining.toDouble(), 20000.0);
        expect(result[0].isFullyPaid, false);
        // Order 2: fully paid
        expect(result[1].isFullyPaid, true);
      });
    });

    group('addPayment', () {
      test('should call dao.insertPayment with correct data', () async {
        when(() => mockDao.insertPayment(any())).thenAnswer((_) async {});

        await repository.addPayment(
          orderId: 'order1',
          amountInCents: 1500000,
          note: 'Trả tiền mặt',
        );

        verify(() => mockDao.insertPayment(any())).called(1);
      });
    });
  });
}
