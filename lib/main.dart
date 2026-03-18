/// Entry point for FishCash POS application.
///
/// Sets up dependency injection (database, API client, repositories, BLoCs)
/// and launches the app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fishcash_pos/app/app.dart';
import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/repositories/category_repository.dart';
import 'package:fishcash_pos/data/repositories/product_repository.dart';
import 'package:fishcash_pos/data/repositories/partner_repository.dart';
import 'package:fishcash_pos/data/repositories/trade_order_repository.dart';
import 'package:fishcash_pos/data/repositories/trading_session_repository.dart';
import 'package:fishcash_pos/data/repositories/dashboard_repository.dart';
import 'package:fishcash_pos/data/repositories/store_info_repository.dart';
import 'package:fishcash_pos/data/repositories/finance_repository.dart';
import 'package:fishcash_pos/data/repositories/inventory_repository.dart';
import 'package:fishcash_pos/data/repositories/debt_repository.dart';
import 'package:fishcash_pos/presentation/categories/bloc/category_bloc.dart';
import 'package:fishcash_pos/presentation/categories/bloc/category_event_state.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_bloc.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_event_state.dart';
import 'package:fishcash_pos/presentation/partners/bloc/partner_bloc.dart';
import 'package:fishcash_pos/presentation/pos/bloc/pos_bloc.dart';
import 'package:fishcash_pos/presentation/trading/bloc/trading_bloc.dart';
import 'package:fishcash_pos/presentation/settings/bloc/store_info_bloc.dart';
import 'package:fishcash_pos/presentation/finance/bloc/finance_bloc.dart';
import 'package:fishcash_pos/presentation/inventory/bloc/inventory_bloc.dart';
import 'package:fishcash_pos/presentation/debt/bloc/debt_bloc.dart';
import 'package:fishcash_pos/core/theme/theme_notifier.dart';
import 'package:fishcash_pos/core/services/api_client.dart';
import 'package:fishcash_pos/core/services/sync_service.dart';
import 'package:fishcash_pos/presentation/sync/bloc/sync_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database (local SQLite cache)
  final database = AppDatabase();

  // Initialize API client (online-first)
  final apiClient = ApiClient();

  // Initialize repositories (DAO for cache, ApiClient for server)
  final categoryRepository = CategoryRepository(database.categoryDao);
  final productRepository = ProductRepository(database.productDao);
  final partnerRepository = PartnerRepository(database.partnerDao);
  final tradeOrderRepository = TradeOrderRepository(
    database.tradeOrderDao,
    database.tradingSessionDao,
  );
  final tradingSessionRepository =
      TradingSessionRepository(database.tradingSessionDao);
  final dashboardRepository =
      DashboardRepository(database.tradingSessionDao);
  final storeInfoRepository = StoreInfoRepository(database.storeInfoDao);
  final financeRepository = FinanceRepository(database.tradeOrderDao);
  final inventoryRepository = InventoryRepository(database.tradeOrderDao);
  final debtRepository = DebtRepository(database.tradeOrderDao);

  // Initialize sync service
  final syncService = SyncService(
    api: apiClient,
    syncDao: database.syncDao,
  );


  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: partnerRepository),
        RepositoryProvider.value(value: tradeOrderRepository),
        RepositoryProvider.value(value: tradingSessionRepository),
        RepositoryProvider.value(value: dashboardRepository),
        RepositoryProvider.value(value: storeInfoRepository),
        RepositoryProvider.value(value: financeRepository),
        RepositoryProvider.value(value: inventoryRepository),
        RepositoryProvider.value(value: debtRepository),
        RepositoryProvider.value(value: apiClient),
        RepositoryProvider.value(value: syncService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CategoryBloc>(
            create: (_) => CategoryBloc(categoryRepository)
              ..add(const CategoriesLoadRequested()),
          ),
          BlocProvider<ProductBloc>(
            create: (_) => ProductBloc(productRepository)
              ..add(const ProductsLoadRequested()),
          ),
          BlocProvider<PartnerBloc>(
            create: (_) => PartnerBloc(partnerRepository)
              ..add(const PartnersLoadRequested()),
          ),
          BlocProvider<PosBloc>(
            create: (_) => PosBloc(tradeOrderRepository),
          ),
          BlocProvider<TradingBloc>(
            create: (_) =>
                TradingBloc(tradingSessionRepository, tradeOrderRepository)
                  ..add(const TradingSessionsLoadRequested()),
          ),
          BlocProvider<StoreInfoBloc>(
            create: (_) => StoreInfoBloc(storeInfoRepository)
              ..add(const StoreInfoLoadRequested()),
          ),
          BlocProvider<FinanceBloc>(
            create: (_) => FinanceBloc(financeRepository)
              ..add(const FinanceLoadRequested()),
          ),
          BlocProvider<InventoryBloc>(
            create: (_) => InventoryBloc(inventoryRepository)
              ..add(const InventoryLoadRequested()),
          ),
          BlocProvider<DebtBloc>(
            create: (_) => DebtBloc(debtRepository)
              ..add(const DebtLoadRequested()),
          ),
          BlocProvider<ConnectionBloc>(
            create: (_) => ConnectionBloc(
              api: apiClient,
              syncService: syncService,
            )..add(const ConnectionInitRequested()),
          ),
        ],
        child: FishCashApp(themeNotifier: themeNotifier),
      ),
    ),
  );
}
