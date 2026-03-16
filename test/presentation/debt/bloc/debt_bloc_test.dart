/// Unit tests for DebtBloc.
///
/// Tests load receivables/payables, add payment, and partner detail.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:decimal/decimal.dart';
import 'package:fishcash_pos/data/repositories/debt_repository.dart';
import 'package:fishcash_pos/presentation/debt/bloc/debt_bloc.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

void main() {
  late MockDebtRepository mockRepo;

  final sampleReceivables = [
    DebtSummary(
      partnerId: 'p1',
      partnerName: 'Nhà hàng ABC',
      partnerPhone: '0901234567',
      partnerType: 'buyer',
      totalOrder: Decimal.fromInt(50000),
      totalPaid: Decimal.fromInt(30000),
      debt: Decimal.fromInt(20000),
    ),
  ];

  final samplePayables = [
    DebtSummary(
      partnerId: 'p2',
      partnerName: 'Ghe Ông Ba',
      partnerPhone: '0987654321',
      partnerType: 'supplier',
      totalOrder: Decimal.fromInt(100000),
      totalPaid: Decimal.zero,
      debt: Decimal.fromInt(100000),
    ),
  ];

  final sampleOrders = [
    DebtOrderDetail(
      orderId: 'o1',
      orderType: 'sell',
      subtotal: Decimal.fromInt(30000),
      totalPaid: Decimal.fromInt(10000),
      remaining: Decimal.fromInt(20000),
      note: '',
      orderDate: DateTime(2026, 3, 16),
      sessionId: 's1',
    ),
  ];

  setUp(() {
    mockRepo = MockDebtRepository();
  });

  group('DebtBloc', () {
    blocTest<DebtBloc, DebtState>(
      'emits [loading, loaded] when DebtLoadRequested succeeds',
      build: () {
        when(() => mockRepo.getReceivables())
            .thenAnswer((_) async => sampleReceivables);
        when(() => mockRepo.getPayables())
            .thenAnswer((_) async => samplePayables);
        return DebtBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const DebtLoadRequested()),
      expect: () => [
        isA<DebtState>()
            .having((s) => s.status, 'status', DebtStatus.loading),
        isA<DebtState>()
            .having((s) => s.status, 'status', DebtStatus.loaded)
            .having(
                (s) => s.receivables.length, 'receivables.length', 1)
            .having((s) => s.payables.length, 'payables.length', 1),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'emits error state when load fails',
      build: () {
        when(() => mockRepo.getReceivables())
            .thenThrow(Exception('DB error'));
        return DebtBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const DebtLoadRequested()),
      expect: () => [
        isA<DebtState>()
            .having((s) => s.status, 'status', DebtStatus.loading),
        isA<DebtState>()
            .having((s) => s.status, 'status', DebtStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', isNotNull),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'loads partner orders on DebtPartnerDetailRequested',
      build: () {
        when(() => mockRepo.getPartnerOrders('p1'))
            .thenAnswer((_) async => sampleOrders);
        return DebtBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const DebtPartnerDetailRequested('p1')),
      expect: () => [
        isA<DebtState>()
            .having((s) => s.partnerOrders.length, 'partnerOrders.length', 1)
            .having((s) => s.selectedPartnerId, 'selectedPartnerId', 'p1'),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'adds payment and reloads on DebtPaymentAdded',
      build: () {
        when(() => mockRepo.addPayment(
              orderId: 'o1',
              amountInCents: 1500000,
              note: 'Tiền mặt',
            )).thenAnswer((_) async {});
        when(() => mockRepo.getReceivables())
            .thenAnswer((_) async => []);
        when(() => mockRepo.getPayables())
            .thenAnswer((_) async => []);
        return DebtBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const DebtPaymentAdded(
        orderId: 'o1',
        amountInCents: 1500000,
        note: 'Tiền mặt',
      )),
      verify: (_) {
        verify(() => mockRepo.addPayment(
              orderId: 'o1',
              amountInCents: 1500000,
              note: 'Tiền mặt',
            )).called(1);
      },
    );
  });
}
