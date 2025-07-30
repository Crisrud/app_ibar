import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProtheusAuth with ChangeNotifier {

  String? _mensagem;
  String? _token;

  String? get token => _token;

  final _url = "http://187.50.41.226:10099/api/oauth2/v1/token";


  get mensagemErro {
    return _mensagem;
  }

  get url {
    return _url;
  }

  Future<bool> signUp(String usuario, String pass) async {
    String sUri = _url;
    try {
      final response = await http.post(
        Uri.parse(sUri),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'grant_type': 'password',
          'username': usuario,
          'password': pass,

        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        _token = data['access_token'];
        notifyListeners();
        return true;
      } else {
        _mensagem = 'Usuário ou senha inválidos: ${response.statusCode}';
        _token = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _mensagem = 'Erro na conexão: $e';
      _token = null;
      notifyListeners();
      return false;
    }

  }

  void logout() {
    _token = null;
    notifyListeners();
  }

}
