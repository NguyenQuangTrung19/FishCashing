/// ConnectionBloc — manages store setup + server connectivity.
///
/// Replaces the old SyncBloc. No login/register needed.
/// User just enters store info → auto-provision on server.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fishcash_pos/core/services/api_client.dart';

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

// --- States ---
enum ConnectionStatus { initial, loading, connected, needsSetup, error }

class ServerConnectionState extends Equatable {
  final ConnectionStatus status;
  final String? storeName;
  final String? storeId;
  final String? serverUrl;
  final String? error;

  const ServerConnectionState({
    this.status = ConnectionStatus.initial,
    this.storeName,
    this.storeId,
    this.serverUrl,
    this.error,
  });

  bool get isSetup => storeId != null;

  ServerConnectionState copyWith({
    ConnectionStatus? status,
    String? storeName,
    String? storeId,
    String? serverUrl,
    String? error,
  }) {
    return ServerConnectionState(
      status: status ?? this.status,
      storeName: storeName ?? this.storeName,
      storeId: storeId ?? this.storeId,
      serverUrl: serverUrl ?? this.serverUrl,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, storeName, storeId, serverUrl, error];
}

// --- Bloc ---
class ConnectionBloc extends Bloc<ConnectionEvent, ServerConnectionState> {
  final ApiClient _api;

  ConnectionBloc({required ApiClient api})
      : _api = api,
        super(const ServerConnectionState()) {
    on<ConnectionInitRequested>(_onInit);
    on<StoreSetupRequested>(_onSetupStore);
    on<ServerUrlChanged>(_onServerUrlChanged);
    on<ConnectionResetRequested>(_onReset);
  }

  Future<void> _onInit(
      ConnectionInitRequested event, Emitter<ServerConnectionState> emit) async {
    await _api.init();

    if (_api.isSetup) {
      emit(ServerConnectionState(
        status: ConnectionStatus.connected,
        storeName: _api.storeName,
        storeId: _api.storeId,
        serverUrl: _api.serverUrl,
      ));
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
}
