import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

import 'package:ibar_app/screens/login_screen.dart';
import 'package:provider/provider.dart';

import '../services/protheus_auth.dart';
import '../services/protheus_api_client.dart';
import '../services/protheus_operations_api.dart';

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

  final MaskedTextController _horaInicialController = MaskedTextController(
    mask: '00.00',
  );
  final MaskedTextController _horaFinalController = MaskedTextController(
    mask: '00.00',
  );

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

  String? _sessionTokenOrLogin() {
    final token = context.read<ProtheusAuth>().token;
    if (token != null && token.isNotEmpty) return token;
    if (!mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sess\u00e3o expirada. Fa\u00e7a login novamente.'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    return null;
  }

  Future<void> _expireSession() async {
    if (!mounted) return;
    try {
      await context.read<ProtheusAuth>().logout();
    } catch (_) {
      // Continue to login even if persisted-session cleanup fails.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sess\u00e3o expirada. Fa\u00e7a login novamente.'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _liberarCatraca() async {
    if (_matriculaController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor, digite a matr\u00edcula');
      return;
    }

    if (_horaextra &&
        (_horaInicialController.text.isEmpty ||
            _horaFinalController.text.isEmpty)) {
      setState(
        () => _errorMessage = 'Preencha os hor\u00e1rios para hora extra',
      );
      return;
    }

    final token = _sessionTokenOrLogin();
    if (token == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String tipo;
      if (_atraso) {
        tipo = '2';
      } else if (_compensar) {
        tipo = '3';
      } else if (_horaextra) {
        tipo = '4';
        final horaInicialError = _validateHora(_horaInicialController.text);
        final horaFinalError = _validateHora(_horaFinalController.text);
        if (horaInicialError != null || horaFinalError != null) {
          setState(() => _errorMessage = horaInicialError ?? horaFinalError);
          return;
        }
      } else {
        tipo = '1';
      }

      await context.read<ProtheusOperationsApi>().releaseTurnstile(
        token: token,
        matricula: _matriculaController.text,
        tipo: tipo,
        horaInicial: _horaextra ? _horaInicialController.text : null,
        horaFinal: _horaextra ? _horaFinalController.text : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catraca liberada para ${_matriculaController.text}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      _matriculaController.clear();
      if (_horaextra) {
        _horaInicialController.clear();
        _horaFinalController.clear();
      }
    } catch (error) {
      if (error is ProtheusApiHttpException && error.statusCode == 401) {
        await _expireSession();
      } else if (mounted) {
        final message =
            error is ProtheusApiNetworkException
                ? 'Erro de conex\u00e3o: $error'
                : 'Falha ao liberar a catraca: $error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
        setState(() => _errorMessage = null); // Limpa após mostrar
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Liberação de Catraca')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Liberação de acesso',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Informe a matrícula e selecione o motivo da solicitação.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _matriculaController,
                            decoration: const InputDecoration(
                              labelText: 'Matrícula',
                              hintText: 'Digite a matrícula',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Atraso'),
                            value: _atraso,
                            onChanged: (bool? value) {
                              setState(() {
                                _atraso = value ?? false;
                                if (_atraso) {
                                  _compensar = false;
                                  _horaextra = false;
                                }
                              });
                            },
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Compensar'),
                            value: _compensar,
                            onChanged: (bool? value) {
                              setState(() {
                                _compensar = value ?? false;
                                if (_compensar) {
                                  _atraso = false;
                                  _horaextra = false;
                                }
                              });
                            },
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Hora Extra'),
                            value: _horaextra,
                            onChanged: (bool? value) {
                              setState(() {
                                _horaextra = value ?? false;
                                if (_horaextra) {
                                  _atraso = false;
                                  _compensar = false;
                                }
                              });
                            },
                          ),
                          if (_horaextra) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _horaInicialController,
                              decoration: InputDecoration(
                                labelText: 'Hora Inicial',
                                hintText: 'Ex.: 08.00',
                                prefixIcon: const Icon(Icons.schedule),
                                errorText: _validateHora(
                                  _horaInicialController.text,
                                ),
                              ),
                              keyboardType: TextInputType.datetime,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _horaFinalController,
                              decoration: InputDecoration(
                                labelText: 'Hora Final',
                                hintText: 'Ex.: 12.00',
                                prefixIcon: const Icon(Icons.schedule),
                                errorText: _validateHora(
                                  _horaFinalController.text,
                                ),
                              ),
                              keyboardType: TextInputType.datetime,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _liberarCatraca,
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Liberar a Catraca'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
