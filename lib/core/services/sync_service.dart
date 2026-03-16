/// Sync service — pushes local changes to server and pulls remote changes.
///
/// Uses timestamp-based sync with last-write-wins conflict resolution.
import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:fishcash_pos/core/services/api_client.dart';
import 'package:fishcash_pos/data/database/app_database.dart';

class SyncService {
  final ApiClient _api;
  final AppDatabase _db;

  SyncService({required ApiClient api, required AppDatabase db})
      : _api = api,
        _db = db;

  /// Full sync: push local changes then pull remote changes.
  Future<SyncResult> fullSync() async {
    if (!_api.isLoggedIn) {
      return SyncResult(success: false, error: 'Chưa đăng nhập');
    }

    try {
      // Step 1: Push local changes
      final pushResult = await _pushChanges();

      // Step 2: Pull remote changes
      final pullResult = await _pullChanges();

      // Update last sync timestamp
      final serverTime = pullResult['serverTime'] as String?;
      if (serverTime != null) {
        await _api.setLastSyncAt(serverTime);
      }

      return SyncResult(
        success: true,
        pushed: pushResult,
        pulled: pullResult,
      );
    } catch (e) {
      log('Sync error: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// Push local records to server.
  Future<Map<String, dynamic>> _pushChanges() async {
    final lastSync = _api.lastSyncAt;
    final changes = <Map<String, dynamic>>[];

    // Collect categories
    await _collectSyncableTable<Category>(
      'categories',
      _db.select(_db.categories),
      (tbl) => tbl.updatedAt,
      lastSync,
      changes,
      _categoryToJson,
    );

    // Collect products
    await _collectSyncableTable<Product>(
      'products',
      _db.select(_db.products),
      (tbl) => tbl.updatedAt,
      lastSync,
      changes,
      _productToJson,
    );

    // Collect partners
    await _collectSyncableTable<Partner>(
      'partners',
      _db.select(_db.partners),
      (tbl) => tbl.updatedAt,
      lastSync,
      changes,
      _partnerToJson,
    );

    // Collect trading sessions
    await _collectSyncableTable<TradingSession>(
      'trading_sessions',
      _db.select(_db.tradingSessions),
      (tbl) => tbl.updatedAt,
      lastSync,
      changes,
      _sessionToJson,
    );

    // Collect trade orders
    await _collectSyncableTable<TradeOrder>(
      'trade_orders',
      _db.select(_db.tradeOrders),
      (tbl) => tbl.updatedAt,
      lastSync,
      changes,
      _orderToJson,
    );

    if (changes.isEmpty) return {'skipped': true};

    return await _api.post('/api/v1/sync/push', {
      'changes': changes,
      'lastSyncAt': lastSync,
    });
  }

  /// Helper: collect records from a syncable table.
  Future<void> _collectSyncableTable<T extends DataClass>(
    String tableName,
    SimpleSelectStatement<HasResultSet, T> query,
    GeneratedColumn<DateTime> Function(dynamic tbl) getUpdatedAt,
    String? lastSync,
    List<Map<String, dynamic>> changes,
    Map<String, dynamic> Function(T record) toJson,
  ) async {
    final records = await query.get();
    final filtered = lastSync != null
        ? records.where((r) {
            final json = toJson(r);
            final updatedAt = json['updatedAt'] as String?;
            if (updatedAt == null) return true;
            return DateTime.parse(updatedAt).isAfter(DateTime.parse(lastSync));
          }).toList()
        : records;

    if (filtered.isNotEmpty) {
      changes.add({
        'table': tableName,
        'records': filtered.map(toJson).toList(),
      });
    }
  }

  /// Pull remote records from server.
  Future<Map<String, dynamic>> _pullChanges() async {
    final lastSync = _api.lastSyncAt;
    final path = lastSync != null
        ? '/api/v1/sync/pull?since=$lastSync'
        : '/api/v1/sync/pull';

    final result = await _api.get(path);
    final changes = result['changes'] as Map<String, dynamic>?;

    if (changes != null) {
      for (final entry in changes.entries) {
        final records = entry.value as List<dynamic>;
        await _applyRemoteChanges(entry.key, records);
      }
    }

    return result;
  }

  /// Apply remote records to local database.
  Future<void> _applyRemoteChanges(
      String tableName, List<dynamic> records) async {
    for (final record in records) {
      try {
        final map = record as Map<String, dynamic>;
        await _upsertRecord(tableName, map);
      } catch (e) {
        log('Error applying remote change for $tableName: $e');
      }
    }
  }

  /// Upsert a record into local SQLite.
  Future<void> _upsertRecord(
      String tableName, Map<String, dynamic> data) async {
    final id = data['id'] as String;

    switch (tableName) {
      case 'categories':
        await _db.into(_db.categories).insertOnConflictUpdate(
              CategoriesCompanion.insert(
                id: id,
                name: data['name'] as String? ?? '',
                description: Value(data['description'] as String? ?? ''),
                isActive: Value(data['isActive'] as bool? ?? true),
                createdAt:
                    Value(DateTime.parse(data['createdAt'] as String)),
                updatedAt:
                    Value(DateTime.parse(data['updatedAt'] as String)),
              ),
            );
        break;

      case 'products':
        await _db.into(_db.products).insertOnConflictUpdate(
              ProductsCompanion.insert(
                id: id,
                categoryId: data['categoryId'] as String? ?? '',
                name: data['name'] as String? ?? '',
                priceInCents: data['priceInCents'] as int? ?? 0,
                unit: Value(data['unit'] as String? ?? 'kg'),
                imagePath: Value(data['imagePath'] as String? ?? ''),
                isActive: Value(data['isActive'] as bool? ?? true),
                createdAt:
                    Value(DateTime.parse(data['createdAt'] as String)),
                updatedAt:
                    Value(DateTime.parse(data['updatedAt'] as String)),
              ),
            );
        break;

      case 'partners':
        await _db.into(_db.partners).insertOnConflictUpdate(
              PartnersCompanion.insert(
                id: id,
                name: data['name'] as String? ?? '',
                type: data['type'] as String? ?? 'supplier',
                phone: Value(data['phone'] as String? ?? ''),
                address: Value(data['address'] as String? ?? ''),
                note: Value(data['note'] as String? ?? ''),
                isActive: Value(data['isActive'] as bool? ?? true),
                createdAt:
                    Value(DateTime.parse(data['createdAt'] as String)),
                updatedAt:
                    Value(DateTime.parse(data['updatedAt'] as String)),
              ),
            );
        break;

      case 'trading_sessions':
        await _db.into(_db.tradingSessions).insertOnConflictUpdate(
              TradingSessionsCompanion.insert(
                id: id,
                note: Value(data['note'] as String? ?? ''),
                totalBuyInCents:
                    Value(data['totalBuyInCents'] as int? ?? 0),
                totalSellInCents:
                    Value(data['totalSellInCents'] as int? ?? 0),
                profitInCents:
                    Value(data['profitInCents'] as int? ?? 0),
                createdAt:
                    Value(DateTime.parse(data['createdAt'] as String)),
                updatedAt:
                    Value(DateTime.parse(data['updatedAt'] as String)),
              ),
            );
        break;

      case 'trade_orders':
        await _db.into(_db.tradeOrders).insertOnConflictUpdate(
              TradeOrdersCompanion.insert(
                id: id,
                sessionId: Value(data['sessionId'] as String?),
                partnerId: Value(data['partnerId'] as String?),
                orderType: data['orderType'] as String? ?? 'pos',
                subtotalInCents:
                    Value(data['subtotalInCents'] as int? ?? 0),
                note: Value(data['note'] as String? ?? ''),
                createdAt:
                    Value(DateTime.parse(data['createdAt'] as String)),
                updatedAt:
                    Value(DateTime.parse(data['updatedAt'] as String)),
              ),
            );
        break;

      default:
        log('Unhandled table for upsert: $tableName');
    }
  }

  // --- JSON converters ---
  Map<String, dynamic> _categoryToJson(Category r) => {
        'id': r.id,
        'name': r.name,
        'description': r.description,
        'isActive': r.isActive,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _productToJson(Product r) => {
        'id': r.id,
        'categoryId': r.categoryId,
        'name': r.name,
        'priceInCents': r.priceInCents,
        'unit': r.unit,
        'imagePath': r.imagePath,
        'isActive': r.isActive,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _partnerToJson(Partner r) => {
        'id': r.id,
        'name': r.name,
        'type': r.type,
        'phone': r.phone,
        'address': r.address,
        'note': r.note,
        'isActive': r.isActive,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _sessionToJson(TradingSession r) => {
        'id': r.id,
        'note': r.note,
        'totalBuyInCents': r.totalBuyInCents,
        'totalSellInCents': r.totalSellInCents,
        'profitInCents': r.profitInCents,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _orderToJson(TradeOrder r) => {
        'id': r.id,
        'sessionId': r.sessionId,
        'partnerId': r.partnerId,
        'orderType': r.orderType,
        'subtotalInCents': r.subtotalInCents,
        'note': r.note,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };
}

class SyncResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? pushed;
  final Map<String, dynamic>? pulled;

  SyncResult({
    required this.success,
    this.error,
    this.pushed,
    this.pulled,
  });
}
