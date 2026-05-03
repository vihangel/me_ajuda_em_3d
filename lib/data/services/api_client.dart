import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import 'token_service.dart';

/// Central API client with automatic Bearer token and 401 refresh.
class ApiClient {
  ApiClient(this._tokenService, {http.Client? client})
    : _client = client ?? http.Client();

  final TokenService _tokenService;
  final http.Client _client;

  /// Called when a token refresh fails — the session is expired.
  VoidCallback? onSessionExpired;

  String get _baseUrl => ApiConfig.baseUrl;

  // -------------------------------------------------------------------------
  // Public HTTP methods
  // -------------------------------------------------------------------------

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParams);
    final headers = await _headers();
    final response = await _client.get(uri, headers: headers);
    return _handleResponse(response, () => get(path, queryParams: queryParams));
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final headers = await _headers(json: true);
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, () => post(path, body));
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final headers = await _headers(json: true);
    final response = await _client.put(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, () => put(path, body));
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final headers = await _headers(json: true);
    final response = await _client.patch(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, () => patch(path, body));
  }

  Future<void> delete(String path) async {
    final headers = await _headers();
    final response = await _client.delete(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    );
    await _handleResponse(response, () => delete(path));
  }

  // -------------------------------------------------------------------------
  // Headers
  // -------------------------------------------------------------------------

  Future<Map<String, String>> _headers({bool json = false}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = await _tokenService.getAccessToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // -------------------------------------------------------------------------
  // Response handling + 401 refresh
  // -------------------------------------------------------------------------

  Future<dynamic> _handleResponse(
    http.Response response,
    Future<dynamic> Function() retry,
  ) async {
    if (response.statusCode >= 400) {
      // Guard against non-JSON error bodies (e.g. HTML from a proxy or 404).
      dynamic body;
      try {
        body = response.body.isNotEmpty ? jsonDecode(response.body) : const {};
      } catch (_) {
        body = const {};
      }
      final message =
          (body is Map ? body['error'] : null) ?? 'Erro desconhecido';

      // Intercept expired-token 401 and try a transparent refresh.
      if (response.statusCode == 401 && message == 'Token expirado') {
        final refreshed = await _tryRefresh();
        if (refreshed) return retry();
        return null;
      }

      throw ApiException(statusCode: response.statusCode, message: message);
    }

    if (response.body.isEmpty) return null;

    // Guard against non-JSON success bodies.
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Resposta invalida do servidor (nao e JSON).',
      );
    }
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null) {
      await _handleSessionExpired();
      return false;
    }
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.authBaseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _tokenService.saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
        return true;
      }
    } catch (_) {
      // Network or parse error during refresh — treat as failure.
    }
    await _handleSessionExpired();
    return false;
  }

  Future<void> _handleSessionExpired() async {
    await _tokenService.clearTokens();
    onSessionExpired?.call();
  }
}

/// Exception thrown by [ApiClient] on non-2xx responses.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
