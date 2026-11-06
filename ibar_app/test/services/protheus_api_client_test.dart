import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ibar_app/services/api_config.dart';
import 'package:ibar_app/services/protheus_api_client.dart';

void main() {
  group('ApiConfig', () {
    test('builds development service and approval URLs', () {
      final config = ApiConfig.development();

      expect(
        config.serviceUri('/api/requisicoes'),
        Uri.parse('http://mail.ibar.com.br:10099/api/requisicoes'),
      );
      expect(
        config.approvalUri('/rest/api/ibar/aprovar'),
        Uri.parse('http://192.168.101.244:10111/rest/api/ibar/aprovar'),
      );
      expect(config.requestTimeout, const Duration(seconds: 30));
    });

    test('rejects HTTP URLs for production with an actionable message', () {
      expect(
        () => ApiConfig.production(),
        throwsA(
          isA<ProtheusApiConfigurationException>()
              .having((error) => error.message, 'message', contains('HTTPS'))
              .having(
                (error) => error.message,
                'message',
                contains('Protheus'),
              ),
        ),
      );
    });

    test('production configuration accepts HTTPS origins', () {
      final config = ApiConfig.production(
        serviceBaseUri: Uri.parse('https://protheus.example.com:10099'),
        approvalBaseUri: Uri.parse('https://protheus.example.com:10111'),
      );

      expect(config.isProduction, isTrue);
      expect(
        config.serviceUri('/api/requisicoes'),
        Uri.parse('https://protheus.example.com:10099/api/requisicoes'),
      );
    });
  });

  group('ProtheusApiClient', () {
    final config = ApiConfig.development();

    test('sends the confirmed bearer token and parses JSON', () async {
      http.Request? capturedRequest;
      final client = ProtheusApiClient(
        config: config,
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'items': [1, 2],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await client.getJson(
        config.serviceUri('/api/requisicoes'),
        token: 'access-token',
      );

      expect(capturedRequest!.headers['authorization'], 'Bearer access-token');
      expect(result, {
        'items': [1, 2],
      });
    });

    test(
      'propagates unsuccessful HTTP status as an identifiable error',
      () async {
        final client = ProtheusApiClient(
          config: config,
          httpClient: MockClient((_) async => http.Response('denied', 403)),
        );

        await expectLater(
          client.getJson(
            config.serviceUri('/api/requisicoes'),
            token: 'access-token',
          ),
          throwsA(
            isA<ProtheusApiHttpException>().having(
              (error) => error.statusCode,
              'statusCode',
              403,
            ),
          ),
        );
      },
    );

    test('reports invalid JSON as an identifiable error', () async {
      final client = ProtheusApiClient(
        config: config,
        httpClient: MockClient((_) async => http.Response('{broken', 200)),
      );

      await expectLater(
        client.getJson(
          config.serviceUri('/api/requisicoes'),
          token: 'access-token',
        ),
        throwsA(isA<ProtheusApiFormatException>()),
      );
    });

    test('never sends a bearer token to HTTP in production', () async {
      var requestSent = false;
      final secureConfig = ApiConfig.production(
        serviceBaseUri: Uri.parse('https://protheus.example.com:10099'),
        approvalBaseUri: Uri.parse('https://protheus.example.com:10111'),
      );
      final client = ProtheusApiClient(
        config: secureConfig,
        httpClient: MockClient((_) async {
          requestSent = true;
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        client.getJson(
          Uri.parse('http://protheus.example.com:10099/api/requisicoes'),
          token: 'access-token',
        ),
        throwsA(isA<ProtheusApiConfigurationException>()),
      );

      expect(requestSent, isFalse);
    });
  });
}
