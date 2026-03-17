/// HTTP API client for FishCash backend.
///
/// Handles base URL, API key (JWT), and JSON (de)serialization.
/// Online-first: all data operations go through this client.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _apiKeyKey = 'fishcash_api_key';
  static const String _serverUrlKey = 'fishcash_server_url';
  static const String _storeIdKey = 'fishcash_store_id';
  static const String _storeNameKey = 'fishcash_store_name';

  /// Default production URL — Render.com deployment
  static const String _defaultServerUrl = 'http://localhost:3000';

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
      _p.getString(_serverUrlKey) ?? _defaultServerUrl;
  Future<void> setServerUrl(String url) =>
      _p.setString(_serverUrlKey, url);

  // --- API Key (long-lived JWT) ---
  String? get apiKey => _p.getString(_apiKeyKey);
  bool get isSetup => apiKey != null;
  Future<void> setApiKey(String key) =>
      _p.setString(_apiKeyKey, key);
  Future<void> clearApiKey() => _p.remove(_apiKeyKey);

  // --- Store Info ---
  String? get storeId => _p.getString(_storeIdKey);
  String? get storeName => _p.getString(_storeNameKey);

  // --- HTTP headers ---
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (apiKey case final k?) 'Authorization': 'Bearer $k',
      };

  // --- HTTP helpers ---
  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      Uri.parse('$serverUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await http.get(
      Uri.parse('$serverUrl$path'),
      headers: _headers,
    );
    return _handleListResponse(response);
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

  Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('$serverUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$serverUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }

    final errorBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {'message': 'Unknown error'};

    throw ApiException(
      statusCode: response.statusCode,
      message: errorBody['message']?.toString() ?? 'Request failed',
    );
  }

  List<dynamic> _handleListResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return [];
      return jsonDecode(response.body) as List<dynamic>;
    }

    final errorBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {'message': 'Unknown error'};

    throw ApiException(
      statusCode: response.statusCode,
      message: errorBody['message']?.toString() ?? 'Request failed',
    );
  }

  // --- Store Setup (replaces login/register) ---
  Future<Map<String, dynamic>> setupStore({
    required String storeName,
    String? phone,
    String? address,
  }) async {
    final result = await post('/api/v1/auth/setup', {
      'storeName': storeName,
      if (phone case final p?) 'phone': p,
      if (address case final a?) 'address': a,
    });

    // Save API key and store info
    await setApiKey(result['apiKey'] as String);
    await _p.setString(_storeIdKey, result['storeId'] as String);
    await _p.setString(_storeNameKey, result['storeName'] as String);

    return result;
  }

  /// Reset all stored data (for testing or re-setup)
  Future<void> resetAll() async {
    await clearApiKey();
    await _p.remove(_storeIdKey);
    await _p.remove(_storeNameKey);
    await _p.remove(_serverUrlKey);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
