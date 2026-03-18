/// ConnectionBloc — manages store setup + server connectivity + manual sync.
///
/// Offline-first architecture. No auto-sync.
/// User manually triggers sync via button when needed (backup to server).
library;

import 'dart:developer' as dev;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fishcash_pos/core/services/api_client.dart';
import 'package:fishcash_pos/core/services/sync_service.dart';

// --- Events ---
abstract class ConnectionEvent extends Equatable {
  const ConnectionEvent();
  @override
  List<Object?> get props => [];
}

class ConnectionInitRequested extends ConnectionEvent {
  const ConnectionInitRequested();
}

class StoreSetupRequested extends ConnectionEvent {
  final String storeName;
  final String? phone;
  final String? address;
  const StoreSetupRequested(this.storeName, {this.phone, this.address});
  @override
  List<Object?> get props => [storeName, phone, address];
}

class ServerUrlChanged extends ConnectionEvent {
  final String url;
  const ServerUrlChanged(this.url);
  @override
  List<Object?> get props => [url];
}

class ConnectionResetRequested extends ConnectionEvent {
  const ConnectionResetRequested();
}

/// Trigger a full sync (push + pull) — manual only
class SyncRequested extends ConnectionEvent {
  const SyncRequested();
}

/// Trigger only a push sync — manual only
class SyncPushRequested extends ConnectionEvent {
  const SyncPushRequested();
}

// --- States ---
enum ConnectionStatus { initial, loading, connected, needsSetup, error }
enum DataSyncStatus { idle, syncing, success, error }

class ServerConnectionState extends Equatable {
  final ConnectionStatus status;
  final String? storeName;
  final String? storeId;
  final String? serverUrl;
  final String? error;

  // Sync-related fields
  final DataSyncStatus syncStatus;
  final String? lastSyncAt;
  final String? syncError;
  final int lastPushed;
  final int lastPulled;

  const ServerConnectionState({
    this.status = ConnectionStatus.initial,
    this.storeName,
    this.storeId,
    this.serverUrl,
    this.error,
    this.syncStatus = DataSyncStatus.idle,
    this.lastSyncAt,
    this.syncError,
    this.lastPushed = 0,
    this.lastPulled = 0,
  });

  bool get isSetup => storeId != null;

  ServerConnectionState copyWith({
    ConnectionStatus? status,
    String? storeName,
    String? storeId,
    String? serverUrl,
    String? error,
    DataSyncStatus? syncStatus,
    String? lastSyncAt,
    String? syncError,
    int? lastPushed,
    int? lastPulled,
  }) {
    return ServerConnectionState(
      status: status ?? this.status,
      storeName: storeName ?? this.storeName,
      storeId: storeId ?? this.storeId,
      serverUrl: serverUrl ?? this.serverUrl,
      error: error,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncError: syncError,
      lastPushed: lastPushed ?? this.lastPushed,
      lastPulled: lastPulled ?? this.lastPulled,
    );
  }

  @override
  List<Object?> get props => [
        status, storeName, storeId, serverUrl, error,
        syncStatus, lastSyncAt, syncError, lastPushed, lastPulled,
      ];
}

// --- Bloc ---
class ConnectionBloc extends Bloc<ConnectionEvent, ServerConnectionState> {
  final ApiClient _api;
  final SyncService? _syncService;

  ConnectionBloc({
    required ApiClient api,
    SyncService? syncService,
  })  : _api = api,
        _syncService = syncService,
        super(const ServerConnectionState()) {
    on<ConnectionInitRequested>(_onInit);
    on<StoreSetupRequested>(_onSetupStore);
    on<ServerUrlChanged>(_onServerUrlChanged);
    on<ConnectionResetRequested>(_onReset);
    on<SyncRequested>(_onSyncRequested);
    on<SyncPushRequested>(_onSyncPush);
  }

  Future<void> _onInit(
      ConnectionInitRequested event, Emitter<ServerConnectionState> emit) async {
    await _api.init();

    if (_api.isSetup) {
      final lastSync = await _syncService?.getLastSyncAt();

      emit(ServerConnectionState(
        status: ConnectionStatus.connected,
        storeName: _api.storeName,
        storeId: _api.storeId,
        serverUrl: _api.serverUrl,
        lastSyncAt: lastSync,
      ));
      // No auto-sync on init — user controls sync manually
    } else {
      emit(ServerConnectionState(
        status: ConnectionStatus.needsSetup,
        serverUrl: _api.serverUrl,
      ));
    }
  }

  Future<void> _onSetupStore(
      StoreSetupRequested event, Emitter<ServerConnectionState> emit) async {
    emit(state.copyWith(status: ConnectionStatus.loading));
    try {
      final result = await _api.setupStore(
        storeName: event.storeName,
        phone: event.phone,
        address: event.address,
      );

      emit(ServerConnectionState(
        status: ConnectionStatus.connected,
        storeName: result['storeName'] as String?,
        storeId: result['storeId'] as String?,
        serverUrl: _api.serverUrl,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ConnectionStatus.error, error: e.message));
    } catch (e) {
      emit(state.copyWith(
          status: ConnectionStatus.error,
          error: 'Không thể kết nối server. Kiểm tra kết nối mạng.'));
    }
  }

  Future<void> _onServerUrlChanged(
      ServerUrlChanged event, Emitter<ServerConnectionState> emit) async {
    await _api.setServerUrl(event.url);
    emit(state.copyWith(serverUrl: event.url));
  }

  Future<void> _onReset(
      ConnectionResetRequested event, Emitter<ServerConnectionState> emit) async {
    await _api.resetAll();
    emit(const ServerConnectionState(status: ConnectionStatus.needsSetup));
  }

  /// Manual full sync: push local → pull server
  Future<void> _onSyncRequested(
      SyncRequested event, Emitter<ServerConnectionState> emit) async {
    if (_syncService == null || !_api.isSetup) return;

    emit(state.copyWith(syncStatus: DataSyncStatus.syncing));
    try {
      final result = await _syncService.fullSync();

      if (result.success) {
        final lastSync = await _syncService.getLastSyncAt();
        emit(state.copyWith(
          syncStatus: DataSyncStatus.success,
          lastSyncAt: lastSync,
          lastPushed: result.recordsPushed,
          lastPulled: result.recordsPulled,
        ));
      } else {
        emit(state.copyWith(
          syncStatus: DataSyncStatus.error,
          syncError: result.error,
        ));
      }
    } catch (e) {
      dev.log('[ConnectionBloc] Sync failed: $e');
      emit(state.copyWith(
        syncStatus: DataSyncStatus.error,
        syncError: e.toString(),
      ));
    }
  }

  /// Manual push only
  Future<void> _onSyncPush(
      SyncPushRequested event, Emitter<ServerConnectionState> emit) async {
    if (_syncService == null || !_api.isSetup) return;

    try {
      final result = await _syncService.push();
      if (result.success && result.recordsPushed > 0) {
        final lastSync = await _syncService.getLastSyncAt();
        emit(state.copyWith(
          syncStatus: DataSyncStatus.success,
          lastSyncAt: lastSync,
          lastPushed: result.recordsPushed,
        ));
      }
    } catch (e) {
      dev.log('[ConnectionBloc] Push sync failed: $e');
    }
  }
}
