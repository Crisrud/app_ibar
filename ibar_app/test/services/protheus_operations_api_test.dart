import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ibar_app/services/api_config.dart';
import 'package:ibar_app/services/protheus_api_client.dart';
import 'package:ibar_app/services/protheus_operations_api.dart';

void main() {
  const token = 'session-access-token';
  final config = ApiConfig.development();

  test('loads open requisitions through the shared client', () async {
    http.Request? capturedRequest;
    final api = _createApi(config, (request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'items': [
            {'id': 42},
          ],
        }),
        200,
      );
    });

    final result = await api.getOpenRequisitions(token: token);

    expect(
      capturedRequest!.url,
      Uri.parse(
        'http://mail.ibar.com.br:10099/api/ibar/wsrequisicoes?ctipo=abertas',
      ),
    );
    expect(capturedRequest!.method, 'GET');
    expect(capturedRequest!.headers['authorization'], 'Bearer $token');
    expect(result, [
      {'id': 42},
    ]);
  });

  test('approves each requested item using its item id', () async {
    http.Request? capturedRequest;
    final api = _createApi(config, (request) async {
      capturedRequest = request;
      return http.Response('', 200);
    });

    await api.approveItem(itemId: 73, token: token);

    expect(
      capturedRequest!.url,
      Uri.parse(
        'http://192.168.101.244:10111/rest/api/ibar/wsaprovarrequisicao',
      ),
    );
    expect(capturedRequest!.method, 'POST');
    expect(capturedRequest!.headers['authorization'], 'Bearer $token');
    expect(jsonDecode(capturedRequest!.body), {'id': 73, 'acao': 'aprovar'});
  });

  test(
    'rejects a requisition using its requisition id and justification',
    () async {
      http.Request? capturedRequest;
      final api = _createApi(config, (request) async {
        capturedRequest = request;
        return http.Response('', 200);
      });

      await api.rejectRequisition(
        requisitionId: 'REQ-9',
        justification: 'Duplicada',
        token: token,
      );

      expect(
        capturedRequest!.url,
        Uri.parse(
          'http://192.168.101.244:10111/rest/api/ibar/wsrejeitarrequisicao',
        ),
      );
      expect(capturedRequest!.headers['authorization'], 'Bearer $token');
      expect(jsonDecode(capturedRequest!.body), {
        'id': 'REQ-9',
        'acao': 'rejeitar',
        'justificativa': 'Duplicada',
      });
    },
  );

  test(
    'releases the turnstile with existing type and hour query keys',
    () async {
      http.Request? capturedRequest;
      final api = _createApi(config, (request) async {
        capturedRequest = request;
        return http.Response('', 200);
      });

      await api.releaseTurnstile(
        token: token,
        matricula: '00123',
        tipo: '4',
        horaInicial: '08.00',
        horaFinal: '12.30',
      );

      expect(
        capturedRequest!.url,
        Uri.parse(
          'http://mail.ibar.com.br:10099/catraca'
          '?cmat=00123&ctipo=4&hinicial=08.00&hfinal=12.30',
        ),
      );
      expect(capturedRequest!.headers['authorization'], 'Bearer $token');
      expect(capturedRequest!.method, 'POST');
      expect(capturedRequest!.body, isEmpty);
    },
  );

  test('does not report success for a non-200 operation response', () async {
    final api = _createApi(config, (_) async => http.Response('', 201));

    await expectLater(
      api.approveItem(itemId: 73, token: token),
      throwsA(
        isA<ProtheusApiHttpException>().having(
          (error) => error.statusCode,
          'statusCode',
          201,
        ),
      ),
    );
  });

  test('reports invalid requisition JSON explicitly', () async {
    final api = _createApi(config, (_) async => http.Response('{broken', 200));

    await expectLater(
      api.getOpenRequisitions(token: token),
      throwsA(isA<ProtheusApiFormatException>()),
    );
  });

  test('reports a network failure explicitly', () async {
    final api = _createApi(
      config,
      (_) async => throw http.ClientException('Connection failed'),
    );

    await expectLater(
      api.approveItem(itemId: 73, token: token),
      throwsA(isA<ProtheusApiNetworkException>()),
    );
  });
}

ProtheusOperationsApi _createApi(
  ApiConfig config,
  Future<http.Response> Function(http.Request) handler,
) {
  return ProtheusOperationsApi(
    config: config,
    client: ProtheusApiClient(config: config, httpClient: MockClient(handler)),
  );
}
