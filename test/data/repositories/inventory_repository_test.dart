/// Unit tests for InventoryRepository.
///
/// Tests computed inventory logic: buy/sell/adjustment calculations,
/// stock status determination, and time period filtering.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fishcash_pos/data/database/daos/trade_order_dao.dart';
import 'package:fishcash_pos/data/repositories/inventory_repository.dart';

class MockTradeOrderDao extends Mock implements TradeOrderDao {}

void main() {
  late MockTradeOrderDao mockDao;
  late InventoryRepository repository;

  setUp(() {
    mockDao = MockTradeOrderDao();
    repository = InventoryRepository(mockDao);
  });

  group('InventoryRepository', () {
    group('getInventorySummary', () {
      test('should return empty list when no products have orders', () async {
        when(() => mockDao.getStockByProduct(from: any(named: 'from'), to: any(named: 'to')))
            .thenAnswer((_) async => []);

        final result = await repository.getInventorySummary();

        expect(result, isEmpty);
        verify(() => mockDao.getStockByProduct(from: null, to: null)).called(1);
      });

      test('should calculate stock correctly (buy - sell + adjustments)', () async {
        when(() => mockDao.getStockByProduct(from: any(named: 'from'), to: any(named: 'to')))
            .thenAnswer((_) async => [
                  {
                    'productId': 'p1',
                    'productName': 'Tôm sú',
                    'productUnit': 'kg',
                    'categoryId': 'c1',
                    'isActive': true,
                    'buyGrams': 5000, // 5 kg
                    'sellGrams': 2000, // 2 kg
                    'adjGrams': -500, // -0.5 kg adjustment
                  },
                ]);

        final result = await repository.getInventorySummary();

        expect(result.length, 1);
        final item = result.first;
        expect(item.productName, 'Tôm sú');
        expect(item.buyQuantity.toDouble(), 5.0);
        expect(item.sellQuantity.toDouble(), 2.0);
        expect(item.adjustmentQuantity.toDouble(), -0.5);
        expect(item.stockQuantity.toDouble(), 2.5); // 5 - 2 + (-0.5)
      });

      test('should detect StockStatus.sufficient when stock > 20% of buy', () async {
        when(() => mockDao.getStockByProduct(from: any(named: 'from'), to: any(named: 'to')))
            .thenAnswer((_) async => [
                  {
                    'productId': 'p1',
                    'productName': 'Cá lóc',
                    'productUnit': 'kg',
                    'categoryId': 'c1',
                    'isActive': true,
                    'buyGrams': 10000,
                    'sellGrams': 5000,
                    'adjGrams': 0,
                  },
                ]);

        final result = await repository.getInventorySummary();
        expect(result.first.status, StockStatus.sufficient);
      });

      test('should detect StockStatus.low when stock <= 20% of buy', () async {
        when(() => mockDao.getStockByProduct(from: any(named: 'from'), to: any(named: 'to')))
            .thenAnswer((_) async => [
                  {
                    'productId': 'p1',
                    'productName': 'Cua',
                    'productUnit': 'kg',
                    'categoryId': 'c1',
                    'isActive': true,
                    'buyGrams': 10000,
                    'sellGrams': 8500,
                    'adjGrams': 0,
                  },
                ]);

        final result = await repository.getInventorySummary();
        expect(result.first.status, StockStatus.low);
      });

      test('should detect StockStatus.empty when stock is zero', () async {
        when(() => mockDao.getStockByProduct(from: any(named: 'from'), to: any(named: 'to')))
            .thenAnswer((_) async => [
                  {
                    'productId': 'p1',
                    'productName': 'Mực',
                    'productUnit': 'kg',
                    'categoryId': 'c1',
                    'isActive': true,
                    'buyGrams': 5000,
                    'sellGrams': 5000,
                    'adjGrams': 0,
                  },
                ]);

        final result = await repository.getInventorySummary();
        expect(result.first.status, StockStatus.empty);
      });

      test('should detect StockStatus.negative when oversold', () async {
        when(() => mockDao.getStockByProduct(from: any(named: 'from'), to: any(named: 'to')))
            .thenAnswer((_) async => [
                  {
                    'productId': 'p1',
                    'productName': 'Ghẹ',
                    'productUnit': 'kg',
                    'categoryId': 'c1',
                    'isActive': true,
                    'buyGrams': 3000,
                    'sellGrams': 5000,
                    'adjGrams': 0,
                  },
                ]);

        final result = await repository.getInventorySummary();
        expect(result.first.status, StockStatus.negative);
      });

      test('should pass date range for thisMonth period', () async {
        when(() => mockDao.getStockByProduct(from: any(named: 'from'), to: any(named: 'to')))
            .thenAnswer((_) async => []);

        await repository.getInventorySummary(period: InventoryPeriod.thisMonth);

        final captured = verify(() => mockDao.getStockByProduct(
              from: captureAny(named: 'from'),
              to: captureAny(named: 'to'),
            )).captured;

        expect(captured[0], isNotNull); // from
        expect(captured[1], isNotNull); // to
        expect((captured[0] as DateTime).day, 1); // first day of month
      });
    });

    group('getSessionBalance', () {
      test('should calculate balance per product in session', () async {
        when(() => mockDao.getSessionStockBalance('session1'))
            .thenAnswer((_) async => [
                  {
                    'productId': 'p1',
                    'productName': 'Tôm',
                    'productUnit': 'kg',
                    'buyGrams': 3000,
                    'sellGrams': 1000,
                  },
                ]);

        final result = await repository.getSessionBalance('session1');

        expect(result.length, 1);
        expect(result.first.buyQuantity.toDouble(), 3.0);
        expect(result.first.sellQuantity.toDouble(), 1.0);
        expect(result.first.balance.toDouble(), 2.0); // surplus
      });
    });
  });
}
