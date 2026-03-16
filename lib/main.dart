/// Entry point for FishCash POS application.
///
/// Sets up dependency injection (database, repositories, BLoCs)
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
import 'package:fishcash_pos/presentation/categories/bloc/category_bloc.dart';
import 'package:fishcash_pos/presentation/categories/bloc/category_event_state.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_bloc.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_event_state.dart';
import 'package:fishcash_pos/presentation/partners/bloc/partner_bloc.dart';
import 'package:fishcash_pos/presentation/pos/bloc/pos_bloc.dart';
import 'package:fishcash_pos/presentation/trading/bloc/trading_bloc.dart';
import 'package:fishcash_pos/presentation/settings/bloc/store_info_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final database = AppDatabase();

  // Initialize repositories
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

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: partnerRepository),
        RepositoryProvider.value(value: tradeOrderRepository),
        RepositoryProvider.value(value: tradingSessionRepository),
        RepositoryProvider.value(value: dashboardRepository),
        RepositoryProvider.value(value: storeInfoRepository),
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
        ],
        child: const FishCashApp(),
      ),
    ),
  );
}
