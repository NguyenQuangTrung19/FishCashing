/// SyncBloc — manages sync state (login, sync, connectivity).
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fishcash_pos/core/services/api_client.dart';
import 'package:fishcash_pos/core/services/sync_service.dart';

// --- Events ---
abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class SyncInitRequested extends SyncEvent {
  const SyncInitRequested();
}

class SyncLoginRequested extends SyncEvent {
  final String email;
  final String password;
  const SyncLoginRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class SyncRegisterRequested extends SyncEvent {
  final String email;
  final String name;
  final String password;
  final String? storeName;
  const SyncRegisterRequested(this.email, this.name, this.password,
      [this.storeName]);
  @override
  List<Object?> get props => [email, name, password, storeName];
}

class SyncNowRequested extends SyncEvent {
  const SyncNowRequested();
}

class SyncLogoutRequested extends SyncEvent {
  const SyncLogoutRequested();
}

class SyncServerUrlChanged extends SyncEvent {
  final String url;
  const SyncServerUrlChanged(this.url);
  @override
  List<Object?> get props => [url];
}

// --- States ---
enum SyncStatus { initial, loading, loggedOut, loggedIn, syncing, error }

class SyncState extends Equatable {
  final SyncStatus status;
  final String? email;
  final String? userName;
  final String? serverUrl;
  final String? lastSyncAt;
  final String? error;

  const SyncState({
    this.status = SyncStatus.initial,
    this.email,
    this.userName,
    this.serverUrl,
    this.lastSyncAt,
    this.error,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? email,
    String? userName,
    String? serverUrl,
    String? lastSyncAt,
    String? error,
  }) {
    return SyncState(
      status: status ?? this.status,
      email: email ?? this.email,
      userName: userName ?? this.userName,
      serverUrl: serverUrl ?? this.serverUrl,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, email, userName, serverUrl, lastSyncAt, error];
}

// --- Bloc ---
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final ApiClient _api;
  final SyncService _syncService;

  SyncBloc({required ApiClient api, required SyncService syncService})
      : _api = api,
        _syncService = syncService,
        super(const SyncState()) {
    on<SyncInitRequested>(_onInit);
    on<SyncLoginRequested>(_onLogin);
    on<SyncRegisterRequested>(_onRegister);
    on<SyncNowRequested>(_onSyncNow);
    on<SyncLogoutRequested>(_onLogout);
    on<SyncServerUrlChanged>(_onServerUrlChanged);
  }

  Future<void> _onInit(
      SyncInitRequested event, Emitter<SyncState> emit) async {
    await _api.init();
    final user = _api.user;
    if (_api.isLoggedIn && user != null) {
      emit(SyncState(
        status: SyncStatus.loggedIn,
        email: user['email'] as String?,
        userName: user['name'] as String?,
        serverUrl: _api.serverUrl,
        lastSyncAt: _api.lastSyncAt,
      ));
    } else {
      emit(SyncState(
        status: SyncStatus.loggedOut,
        serverUrl: _api.serverUrl,
      ));
    }
  }

  Future<void> _onLogin(
      SyncLoginRequested event, Emitter<SyncState> emit) async {
    emit(state.copyWith(status: SyncStatus.loading));
    try {
      final result = await _api.login(
          email: event.email, password: event.password);
      final user = result['user'] as Map<String, dynamic>;
      emit(state.copyWith(
        status: SyncStatus.loggedIn,
        email: user['email'] as String?,
        userName: user['name'] as String?,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: SyncStatus.error, error: e.message));
    } catch (e) {
      emit(state.copyWith(
          status: SyncStatus.error,
          error: 'Không thể kết nối server'));
    }
  }

  Future<void> _onRegister(
      SyncRegisterRequested event, Emitter<SyncState> emit) async {
    emit(state.copyWith(status: SyncStatus.loading));
    try {
      final result = await _api.register(
        email: event.email,
        name: event.name,
        password: event.password,
        storeName: event.storeName,
      );
      final user = result['user'] as Map<String, dynamic>;
      emit(state.copyWith(
        status: SyncStatus.loggedIn,
        email: user['email'] as String?,
        userName: user['name'] as String?,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: SyncStatus.error, error: e.message));
    } catch (e) {
      emit(state.copyWith(
          status: SyncStatus.error,
          error: 'Không thể kết nối server'));
    }
  }

  Future<void> _onSyncNow(
      SyncNowRequested event, Emitter<SyncState> emit) async {
    emit(state.copyWith(status: SyncStatus.syncing));
    try {
      final result = await _syncService.fullSync();
      if (result.success) {
        emit(state.copyWith(
          status: SyncStatus.loggedIn,
          lastSyncAt: _api.lastSyncAt,
        ));
      } else {
        emit(state.copyWith(
            status: SyncStatus.error, error: result.error));
      }
    } catch (e) {
      emit(state.copyWith(
          status: SyncStatus.error, error: 'Lỗi đồng bộ: $e'));
    }
  }

  Future<void> _onLogout(
      SyncLogoutRequested event, Emitter<SyncState> emit) async {
    await _api.logout();
    emit(const SyncState(status: SyncStatus.loggedOut));
  }

  Future<void> _onServerUrlChanged(
      SyncServerUrlChanged event, Emitter<SyncState> emit) async {
    await _api.setServerUrl(event.url);
    emit(state.copyWith(serverUrl: event.url));
  }
}
