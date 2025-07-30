import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ibar_app/screens/login_screen.dart';
import 'package:provider/provider.dart';

import '../services/protheus_auth.dart';

class Catraca extends StatefulWidget {
  const Catraca({super.key});

  @override
  State<Catraca> createState() => _Catraca();
}

class _Catraca extends State<Catraca> {
  final TextEditingController _matriculaController = TextEditingController();
  bool _atraso = false;
  bool _compensar = false;
  bool _horaextra = false;
  bool _isLoading = false;
  String? _errorMessage;

  final MaskedTextController _horaInicialController =  MaskedTextController(mask: '00.00');
  final MaskedTextController _horaFinalController =  MaskedTextController(mask: '00.00');



  String? _validateHora(String value) {
    final parts = value.split('.');
    if (parts.length == 2) {
      final intPart = int.tryParse(parts[0]) ?? 0;
      final decimalPart = int.tryParse(parts[1]) ?? 0;

      _isLoading = true;
      if (intPart > 23) {
        _isLoading = false;
        return 'O número inteiro não pode ser maior que 23';
      }
      if (decimalPart > 59) {
        _isLoading = false;
        return 'As casas decimais não podem ser maiores que 59';
      }
    }
    return null;
  }


  @override
  void dispose() {
    _matriculaController.dispose();
    _horaInicialController.dispose();
    _horaFinalController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    const String url = 'http://187.50.41.226:10099/api/oauth2/v1/token';
    const String username = 'CRISTIANOS';
    const String password = '121001';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'grant_type': 'password',
          'username': username,
          'password': password,

        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['access_token'];
      } else {
        throw Exception('Falha ao obter token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na conexão: $e');
    }
  }

  Future<void> _liberarCatraca() async {
    final protheusAuth = Provider.of<ProtheusAuth>(context, listen: false);
    final _token = protheusAuth.token;
    print('Token: ${protheusAuth.token}');
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faça login primeiro'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_matriculaController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, digite a matrícula';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Obter o token de acesso

      //final String? token = await _getToken();

      if (_token == null) {
        throw Exception('Não foi possível obter o token de acesso');
      }
      // 2. Determinar o tipo com base nos checkboxes
      final String tipo = _atraso ? '2' : '5';

      // 3. Construir a URL com os parâmetros
      final Uri liberacaoUrl = Uri.parse('http://187.50.41.226:10099/catraca')
          .replace(queryParameters: {
        'cmat': _matriculaController.text,
        'ctipo': tipo,
      });

      final response = await http.post(
          (liberacaoUrl),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          }
      );

      if (response.statusCode == 200) {
        // Sucesso na liberação
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catraca liberada para matrícula: ${_matriculaController.text}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Falha ao liberar catraca: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro: $e';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liberação de Catraca'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _matriculaController,
              decoration: const InputDecoration(
                hintText: 'Digite a Matricula...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  title: const Text('Atraso'),
                  value: _atraso,
                  onChanged: (bool? value) {
                    setState(() {
                      _atraso = value ?? false;
                      if (_atraso) {
                        _compensar = false; // Desmarca compensar se atraso for marcado
                        _horaextra = false; // Desmarca hora extra se atraso for marcado
                      }

                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Compensar'),
                  value: _compensar,
                  onChanged: (bool? value) {
                    setState(() {
                      _compensar = value ?? false;
                      if (_compensar) {
                        _atraso = false; // Desmarca atraso se compensar for marcado
                        _horaextra = false; // Desmarca hora extra se compensar for marcado
                      }
                    });
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: const Text('Hora Extra'),
                      value: _horaextra,
                      onChanged: (bool? value) {
                        setState(() {
                          _horaextra = value ?? false;
                          if (_horaextra) {
                            _atraso = false; // Uncheck "Atraso" if "Hora Extra" is checked
                            _compensar = false; // Uncheck "Compensar" if "Hora Extra" is checked
                          }
                        });
                      },
                    ),
                    if (_horaextra) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _horaInicialController,
                        decoration: InputDecoration(
                          labelText: 'Hora Inicial',
                          hintText: 'Digite a hora inicial (ex: 08.00)',
                          border: OutlineInputBorder(),
                          errorText: _validateHora(_horaInicialController.text),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _horaFinalController,
                        decoration: InputDecoration(
                          labelText: 'Hora Final',
                          hintText: 'Digite a hora final (ex: 12.00)',
                          border: OutlineInputBorder(),
                          errorText: _validateHora(_horaFinalController.text),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _liberarCatraca,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Liberar a Catraca'),
            ),
          ],
        ),
      ),
    );
  }
}