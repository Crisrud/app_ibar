import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'token_storage.dart';

class ProtheusAuth with ChangeNotifier {
  ProtheusAuth({TokenStorage? tokenStorage, http.Client? client})
    : _tokenStorage = tokenStorage ?? SecureTokenStorage(),
      _client = client ?? http.Client();

  String? _mensagem;
  String? _token;
  String? _sessionError;
  bool _isInitialized = false;
  bool _isRestoring = false;

  final TokenStorage _tokenStorage;
  final http.Client _client;
  final String _url = 'http://187.50.41.226:10099/api/oauth2/v1/token';

  String? get token => _token;
  String? get mensagemErro => _mensagem;
  String get url => _url;
  String? get sessionError => _sessionError;
  bool get isInitialized => _isInitialized;
  bool get isRestoring => _isRestoring;

  Future<void> restoreSession() async {
    _isRestoring = true;
    _isInitialized = false;
    _sessionError = null;
    notifyListeners();

    try {
      final savedToken = await _tokenStorage.readToken();
      if (savedToken != null &&
          (savedToken.trim().isEmpty || _isExpired(savedToken))) {
        await _tokenStorage.deleteToken();
        _token = null;
      } else {
        _token = savedToken;
      }
    } catch (error) {
      _token = null;
      _sessionError = 'Erro ao restaurar sessão: $error';
      rethrow;
    } finally {
      _isRestoring = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> signUp(String usuario, String pass) async {
    http.Response response;
    try {
      response = await _client.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'grant_type': 'password',
          'username': usuario,
          'password': pass,
        },
      );
    } catch (error) {
      _mensagem = 'Erro na conexão: $error';
      _token = null;
      notifyListeners();
      return false;
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      _mensagem = 'Usuário ou senha inválidos: ${response.statusCode}';
      _token = null;
      notifyListeners();
      return false;
    }

    String? accessToken;
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      accessToken = data['access_token'] as String?;
    } catch (error) {
      _mensagem = 'Resposta de autenticação inválida: $error';
      _token = null;
      notifyListeners();
      return false;
    }

    if (accessToken == null || accessToken.isEmpty || _isExpired(accessToken)) {
      _mensagem =
          'Resposta de autenticação inválida: token ausente ou expirado';
      _token = null;
      notifyListeners();
      return false;
    }

    try {
      await _tokenStorage.writeToken(accessToken);
    } catch (error) {
      _mensagem = 'Erro ao salvar sessão: $error';
      _token = null;
      notifyListeners();
      return false;
    }

    _token = accessToken;
    _mensagem = null;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
    _token = null;
    _mensagem = null;
    _sessionError = null;
    notifyListeners();
  }

  bool _isExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return false;

    try {
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic> || payload['exp'] is! num) {
        return false;
      }
      final expiry = (payload['exp'] as num) * 1000;
      return expiry <= DateTime.now().toUtc().millisecondsSinceEpoch;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
