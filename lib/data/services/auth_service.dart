import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import 'token_service.dart';

/// Handles login and registration against /api/auth.
class AuthService {
  AuthService(this._tokenService, {http.Client? client})
    : _client = client ?? http.Client();

  final TokenService _tokenService;
  final http.Client _client;

  String get _authUrl => ApiConfig.authBaseUrl;

  bool get isLoggedIn => _tokenService.hasTokens;

  Future<void> login({required String email, required String password}) async {
    final http.Response res;
    try {
      res = await _client.post(
        Uri.parse('$_authUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
    } catch (e) {
      throw AuthException('Servidor indisponivel. Tente novamente.');
    }
    if (res.statusCode != 200) {
      dynamic body;
      try {
        body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      } catch (_) {
        body = {};
      }
      throw AuthException(
        (body is Map ? body['error']?.toString() : null) ??
            'Erro ao fazer login',
      );
    }
    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      throw AuthException('Resposta invalida do servidor.');
    }
    await _tokenService.saveTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final http.Response res;
    try {
      res = await _client.post(
        Uri.parse('$_authUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
    } catch (e) {
      throw AuthException('Servidor indisponivel. Tente novamente.');
    }
    if (res.statusCode != 201 && res.statusCode != 200) {
      dynamic body;
      try {
        body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      } catch (_) {
        body = {};
      }
      throw AuthException(
        (body is Map ? body['error']?.toString() : null) ??
            'Erro ao criar conta',
      );
    }
    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      throw AuthException('Resposta invalida do servidor.');
    }
    await _tokenService.saveTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
  }

  Future<void> logout() async {
    await _tokenService.clearTokens();
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
