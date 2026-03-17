/// Sync service — handles push/pull sync with the backend server.
///
/// Flow:
/// 1. Push: collect unsynced local records → POST /api/v1/sync/push
/// 2. Pull: GET /api/v1/sync/pull?since=lastSyncAt → upsert into SQLite
/// 3. Auto-sync on app start and after mutations
library;

import 'dart:developer' as dev;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishcash_pos/core/services/api_client.dart';
import 'package:fishcash_pos/data/database/daos/sync_dao.dart';

/// Sync status for UI display
enum SyncStatus { idle, syncing, success, error }

class SyncService {
  final ApiClient _api;
  final SyncDao _syncDao;

  static const String _lastSyncKey = 'fishcash_last_sync_at';

  SyncService({required ApiClient api, required SyncDao syncDao})
      : _api = api,
        _syncDao = syncDao;

  /// Get last sync timestamp from SharedPreferences
  Future<String?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey);
  }

  /// Save last sync timestamp
  Future<void> _saveLastSyncAt(String serverTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, serverTime);
  }

  /// Full sync: push local changes, then pull server changes
  Future<SyncResult> fullSync() async {
    if (!_api.isSetup) {
      return SyncResult(
        success: false,
        error: 'Chưa thiết lập cửa hàng. Vui lòng setup trước.',
      );
    }

    try {
      dev.log('[Sync] Starting full sync...');

      // Step 1: Push local changes to server
      final pushResult = await push();

      // Step 2: Pull server changes to local
      final pullResult = await pull();

      dev.log('[Sync] Full sync complete. '
          'Pushed: ${pushResult.recordsPushed}, '
          'Pulled: ${pullResult.recordsPulled}');

      return SyncResult(
        success: true,
        recordsPushed: pushResult.recordsPushed,
        recordsPulled: pullResult.recordsPulled,
      );
    } catch (e) {
      dev.log('[Sync] Full sync failed: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// Push local unsynced records to server
  Future<SyncResult> push() async {
    if (!_api.isSetup) {
      return SyncResult(success: false, error: 'Not setup');
    }

    try {
      final changes = <Map<String, dynamic>>[];

      for (final tableName in _syncDao.syncableTableNames) {
        final records = await _syncDao.getUnsyncedRecords(tableName);
        if (records.isNotEmpty) {
          // Convert DateTime fields from int (epoch seconds) to ISO strings
          final convertedRecords = records.map((r) {
            return _convertDateFieldsToIso(r);
          }).toList();

          changes.add({
            'table': tableName,
            'records': convertedRecords,
          });
        }
      }

      if (changes.isEmpty) {
        dev.log('[Sync] No local changes to push');
        return SyncResult(success: true, recordsPushed: 0);
      }

      dev.log('[Sync] Pushing ${changes.length} tables with changes...');

      final response = await _api.post('/api/v1/sync/push', {
        'changes': changes,
      });

      // Mark records as synced
      int totalPushed = 0;
      final results = response['results'] as Map<String, dynamic>?;
      if (results != null) {
        for (final entry in results.entries) {
          final tableName = entry.key;
          final tableResult = entry.value as Map<String, dynamic>;
          final accepted = tableResult['accepted'] as int? ?? 0;
          totalPushed += accepted;

          // Find the change for this table and mark accepted records
          final tableChange = changes.firstWhere(
            (c) => c['table'] == tableName,
            orElse: () => {'records': []},
          );
          final records = tableChange['records'] as List;
          final ids = records
              .map((r) => r['id']?.toString())
              .where((id) => id != null)
              .cast<String>()
              .toList();
          if (ids.isNotEmpty) {
            await _syncDao.markAsSynced(tableName, ids);
          }
        }
      }

      dev.log('[Sync] Pushed $totalPushed records');
      return SyncResult(success: true, recordsPushed: totalPushed);
    } catch (e) {
      dev.log('[Sync] Push failed: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// Pull server changes and upsert into local database
  Future<SyncResult> pull() async {
    if (!_api.isSetup) {
      return SyncResult(success: false, error: 'Not setup');
    }

    try {
      final lastSync = await getLastSyncAt();
      final queryParams = lastSync != null ? '?since=$lastSync' : '';

      dev.log('[Sync] Pulling changes since: ${lastSync ?? 'beginning'}');

      final response = await _api.get('/api/v1/sync/pull$queryParams');
      final changes = response['changes'] as Map<String, dynamic>?;
      final serverTime = response['serverTime'] as String?;

      int totalPulled = 0;

      if (changes != null) {
        for (final entry in changes.entries) {
          final tableName = entry.key;
          final records = entry.value as List<dynamic>;

          for (final record in records) {
            final recordMap = record as Map<String, dynamic>;
            // Remove server-only fields
            recordMap.remove('userId');
            recordMap.remove('isDeleted');
            // Convert ISO date strings to epoch seconds for SQLite
            final converted = _convertDateFieldsToEpoch(recordMap);
            // Set syncedAt to now
            converted['synced_at'] =
                DateTime.now().millisecondsSinceEpoch ~/ 1000;

            await _syncDao.upsertFromServer(tableName, converted);
            totalPulled++;
          }
        }
      }

      // Save the server time as last sync point
      if (serverTime != null) {
        await _saveLastSyncAt(serverTime);
      }

      dev.log('[Sync] Pulled $totalPulled records');
      return SyncResult(success: true, recordsPulled: totalPulled);
    } catch (e) {
      dev.log('[Sync] Pull failed: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// Convert Drift's integer timestamps (epoch seconds) to ISO strings for server
  Map<String, dynamic> _convertDateFieldsToIso(Map<String, dynamic> record) {
    final result = Map<String, dynamic>.from(record);
    const dateFields = [
      'created_at',
      'updated_at',
      'synced_at',
    ];
    for (final field in dateFields) {
      if (result[field] is int) {
        final epoch = result[field] as int;
        result[field] =
            DateTime.fromMillisecondsSinceEpoch(epoch * 1000).toIso8601String();
      }
    }
    // Convert snake_case to camelCase for server
    return _snakeToCamelCase(result);
  }

  /// Convert ISO date strings from server to epoch seconds for SQLite
  Map<String, dynamic> _convertDateFieldsToEpoch(Map<String, dynamic> record) {
    final result = <String, dynamic>{};
    // Convert camelCase from server to snake_case for SQLite
    for (final entry in record.entries) {
      final snakeKey = _camelToSnake(entry.key);
      var value = entry.value;

      // Try to parse ISO date strings
      if (value is String && _looksLikeIsoDate(value)) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          value = parsed.millisecondsSinceEpoch ~/ 1000;
        }
      }

      result[snakeKey] = value;
    }
    return result;
  }

  /// Convert map keys from snake_case to camelCase
  Map<String, dynamic> _snakeToCamelCase(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      final camelKey = entry.key.replaceAllMapped(
        RegExp(r'_([a-z])'),
        (m) => m.group(1)!.toUpperCase(),
      );
      result[camelKey] = entry.value;
    }
    return result;
  }

  /// Convert a single camelCase string to snake_case
  String _camelToSnake(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }

  /// Check if a string looks like an ISO 8601 date
  bool _looksLikeIsoDate(String value) {
    return value.length >= 10 &&
        RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(value);
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int recordsPushed;
  final int recordsPulled;
  final String? error;

  SyncResult({
    required this.success,
    this.recordsPushed = 0,
    this.recordsPulled = 0,
    this.error,
  });

  @override
  String toString() {
    if (!success) return 'SyncResult(error: $error)';
    return 'SyncResult(pushed: $recordsPushed, pulled: $recordsPulled)';
  }
}
