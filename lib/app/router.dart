/// GoRouter configuration for FishCash POS.
///
/// Defines all routes with a ShellRoute for persistent navigation.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fishcash_pos/presentation/shared/app_shell.dart';
import 'package:fishcash_pos/presentation/dashboard/pages/dashboard_page.dart';
import 'package:fishcash_pos/presentation/categories/pages/category_page.dart';
import 'package:fishcash_pos/presentation/products/pages/product_page.dart';
import 'package:fishcash_pos/presentation/partners/pages/partner_page.dart';
import 'package:fishcash_pos/presentation/trading/pages/trading_page.dart';
import 'package:fishcash_pos/presentation/finance/pages/finance_page.dart';
import 'package:fishcash_pos/presentation/inventory/pages/inventory_page.dart';
import 'package:fishcash_pos/presentation/debt/pages/debt_page.dart';
import 'package:fishcash_pos/presentation/settings/pages/settings_page.dart';
import 'package:fishcash_pos/presentation/sync/pages/sync_settings_page.dart';

/// Navigation destination definition
class AppDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;

  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });
}

/// All navigation destinations (6 items)
const List<AppDestination> appDestinations = [
  AppDestination(
    label: 'Tổng quan',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    path: '/',
  ),
  AppDestination(
    label: 'Giao dịch',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    path: '/trading',
  ),
  AppDestination(
    label: 'Sản phẩm',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    path: '/products',
  ),
  AppDestination(
    label: 'Danh mục',
    icon: Icons.category_outlined,
    selectedIcon: Icons.category,
    path: '/categories',
  ),
  AppDestination(
    label: 'Đối tác',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    path: '/partners',
  ),
  AppDestination(
    label: 'Tài chính',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
    path: '/finance',
  ),
  AppDestination(
    label: 'Kho hàng',
    icon: Icons.warehouse_outlined,
    selectedIcon: Icons.warehouse,
    path: '/inventory',
  ),
  AppDestination(
    label: 'Công nợ',
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance,
    path: '/debt',
  ),
  AppDestination(
    label: 'Cài đặt',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    path: '/settings',
  ),
  AppDestination(
    label: 'Đồng bộ',
    icon: Icons.cloud_sync_outlined,
    selectedIcon: Icons.cloud_sync,
    path: '/sync',
  ),
];

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardPage(),
          ),
        ),
        GoRoute(
          path: '/trading',
          pageBuilder: (context, state) {
            final sessionId = state.uri.queryParameters['sessionId'];
            return NoTransitionPage(
              child: TradingPage(initialSessionId: sessionId),
            );
          },
        ),
        GoRoute(
          path: '/products',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProductPage(),
          ),
        ),
        GoRoute(
          path: '/categories',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CategoryPage(),
          ),
        ),
        GoRoute(
          path: '/partners',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PartnerPage(),
          ),
        ),
        GoRoute(
          path: '/finance',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FinancePage(),
          ),
        ),
        GoRoute(
          path: '/inventory',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: InventoryPage(),
          ),
        ),
        GoRoute(
          path: '/debt',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DebtPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsPage(),
          ),
        ),
        GoRoute(
          path: '/sync',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SyncSettingsPage(),
          ),
        ),
      ],
    ),
  ],
);
