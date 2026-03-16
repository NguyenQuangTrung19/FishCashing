/// HTTP API client for FishCash backend.
///
/// Handles base URL, JWT token, and JSON (de)serialization.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _tokenKey = 'fishcash_jwt_token';
  static const String _serverUrlKey = 'fishcash_server_url';
  static const String _lastSyncKey = 'fishcash_last_sync';
  static const String _userKey = 'fishcash_user';

  SharedPreferences? _prefs;
  bool _initialized = false;

  // Singleton
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  SharedPreferences get _p {
    assert(_initialized, 'ApiClient.init() must be called first');
    return _prefs!;
  }

  // --- Server URL ---
  String get serverUrl =>
      _p.getString(_serverUrlKey) ?? 'http://localhost:3000';
  Future<void> setServerUrl(String url) =>
      _p.setString(_serverUrlKey, url);

  // --- JWT Token ---
  String? get token => _p.getString(_tokenKey);
  bool get isLoggedIn => token != null;
  Future<void> setToken(String token) =>
      _p.setString(_tokenKey, token);
  Future<void> clearToken() => _p.remove(_tokenKey);

  // --- User ---
  Map<String, dynamic>? get user {
    final raw = _p.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
  Future<void> setUser(Map<String, dynamic> user) =>
      _p.setString(_userKey, jsonEncode(user));
  Future<void> clearUser() => _p.remove(_userKey);

  // --- Last Sync ---
  String? get lastSyncAt => _p.getString(_lastSyncKey);
  Future<void> setLastSyncAt(String ts) =>
      _p.setString(_lastSyncKey, ts);

  // --- HTTP helpers ---
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token case final t?) 'Authorization': 'Bearer $t',
      };

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      Uri.parse('$serverUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$serverUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$serverUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final errorBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {'message': 'Unknown error'};

    throw ApiException(
      statusCode: response.statusCode,
      message: errorBody['message']?.toString() ?? 'Request failed',
    );
  }

  // --- Auth shortcuts ---
  Future<Map<String, dynamic>> register({
    required String email,
    required String name,
    required String password,
    String? storeName,
  }) async {
    final result = await post('/api/v1/auth/register', {
      'email': email,
      'name': name,
      'password': password,
      if (storeName != null) 'storeName': storeName,
    });
    await setToken(result['accessToken'] as String);
    await setUser(result['user'] as Map<String, dynamic>);
    return result;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
    await setToken(result['accessToken'] as String);
    await setUser(result['user'] as Map<String, dynamic>);
    return result;
  }

  Future<void> logout() async {
    await clearToken();
    await clearUser();
    await _p.remove(_lastSyncKey);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
