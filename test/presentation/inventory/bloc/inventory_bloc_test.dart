/// Unit tests for InventoryBloc.
///
/// Tests load, period change, and stock reset events.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:decimal/decimal.dart';
import 'package:fishcash_pos/data/repositories/inventory_repository.dart';
import 'package:fishcash_pos/presentation/inventory/bloc/inventory_bloc.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepo;

  final sampleItems = [
    InventoryItem(
      productId: 'p1',
      productName: 'Tôm sú',
      unit: 'kg',
      categoryId: 'c1',
      isActive: true,
      buyQuantity: Decimal.fromInt(10),
      sellQuantity: Decimal.fromInt(4),
      adjustmentQuantity: Decimal.zero,
      stockQuantity: Decimal.fromInt(6),
    ),
    InventoryItem(
      productId: 'p2',
      productName: 'Cá lóc',
      unit: 'kg',
      categoryId: 'c1',
      isActive: true,
      buyQuantity: Decimal.fromInt(5),
      sellQuantity: Decimal.fromInt(5),
      adjustmentQuantity: Decimal.zero,
      stockQuantity: Decimal.zero,
    ),
  ];

  setUp(() {
    mockRepo = MockInventoryRepository();
  });

  group('InventoryBloc', () {
    blocTest<InventoryBloc, InventoryState>(
      'emits [loading, loaded] when InventoryLoadRequested succeeds',
      build: () {
        when(() => mockRepo.getInventorySummary(period: InventoryPeriod.all))
            .thenAnswer((_) async => sampleItems);
        return InventoryBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const InventoryLoadRequested()),
      expect: () => [
        isA<InventoryState>()
            .having((s) => s.status, 'status', InventoryStatus.loading),
        isA<InventoryState>()
            .having((s) => s.status, 'status', InventoryStatus.loaded)
            .having((s) => s.items.length, 'items.length', 2),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'loads with thisMonth period',
      build: () {
        when(() => mockRepo.getInventorySummary(
                period: InventoryPeriod.thisMonth))
            .thenAnswer((_) async => [sampleItems.first]);
        return InventoryBloc(mockRepo);
      },
      act: (bloc) =>
          bloc.add(const InventoryLoadRequested(period: InventoryPeriod.thisMonth)),
      expect: () => [
        isA<InventoryState>()
            .having((s) => s.status, 'status', InventoryStatus.loading),
        isA<InventoryState>()
            .having((s) => s.status, 'status', InventoryStatus.loaded)
            .having((s) => s.items.length, 'items.length', 1)
            .having((s) => s.currentPeriod, 'currentPeriod',
                InventoryPeriod.thisMonth),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits error state when load fails',
      build: () {
        when(() => mockRepo.getInventorySummary(period: InventoryPeriod.all))
            .thenThrow(Exception('Database error'));
        return InventoryBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const InventoryLoadRequested()),
      expect: () => [
        isA<InventoryState>()
            .having((s) => s.status, 'status', InventoryStatus.loading),
        isA<InventoryState>()
            .having((s) => s.status, 'status', InventoryStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', isNotNull),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'resets stock and reloads on InventoryResetStock',
      build: () {
        when(() => mockRepo.resetProductStock(
              productId: 'p1',
              currentStockInGrams: 6000,
              reason: 'Thanh lý',
            )).thenAnswer((_) async {});
        when(() => mockRepo.getInventorySummary(period: InventoryPeriod.all))
            .thenAnswer((_) async => [sampleItems.last]); // after reset
        return InventoryBloc(mockRepo);
      },
      act: (bloc) => bloc.add(InventoryResetStock(
        productId: 'p1',
        currentStockInGrams: 6000,
        reason: 'Thanh lý',
        currentPeriod: InventoryPeriod.all,
      )),
      verify: (_) {
        verify(() => mockRepo.resetProductStock(
              productId: 'p1',
              currentStockInGrams: 6000,
              reason: 'Thanh lý',
            )).called(1);
      },
    );
  });
}
