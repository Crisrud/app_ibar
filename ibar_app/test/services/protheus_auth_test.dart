import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ibar_app/services/api_config.dart';
import 'package:ibar_app/services/protheus_auth.dart';
import 'package:ibar_app/services/token_storage.dart';

class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this.token]);

  String? token;
  Object? readError;
  Object? writeError;
  Object? deleteError;

  @override
  Future<String?> readToken() async {
    if (readError != null) throw readError!;
    return token;
  }

  @override
  Future<void> writeToken(String value) async {
    if (writeError != null) throw writeError!;
    token = value;
  }

  @override
  Future<void> deleteToken() async {
    if (deleteError != null) throw deleteError!;
    token = null;
  }
}

void main() {
  test(
    'release authentication blocks HTTP before sending credentials',
    () async {
      var requestCount = 0;
      final config = ApiConfig.production(
        serviceBaseUri: Uri.parse('http://mail.ibar.com.br:10099'),
        approvalBaseUri: Uri.parse('http://192.168.101.244:10111'),
      );
      final auth = ProtheusAuth(
        config: config,
        tokenStorage: MemoryTokenStorage(),
        client: MockClient((_) async {
          requestCount++;
          return http.Response('', 200);
        }),
      );

      expect(
        await auth.signUp('safe-test-user', 'safe-test-password'),
        isFalse,
      );
      expect(auth.mensagemErro, contains('HTTPS'));
      expect(auth.mensagemErro, contains('Protheus team'));
      expect(requestCount, 0);
    },
  );

  test(
    'development authentication uses the original URL and credential format',
    () async {
      http.Request? capturedRequest;
      final auth = ProtheusAuth(
        config: ApiConfig.development(),
        tokenStorage: MemoryTokenStorage(),
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response('', 401);
        }),
      );

      expect(
        await auth.signUp('safe-test-user', 'safe-test-password'),
        isFalse,
      );

      expect(
        capturedRequest!.url,
        Uri.parse('http://mail.ibar.com.br:10099/api/oauth2/v1/token'),
      );
      expect(
        capturedRequest!.headers['content-type'],
        'application/x-www-form-urlencoded',
      );
      expect(capturedRequest!.headers['grant_type'], 'password');
      expect(capturedRequest!.headers['username'], 'safe-test-user');
      expect(capturedRequest!.headers['password'], 'safe-test-password');
    },
  );

  test('restores a saved token when initializing the session', () async {
    final storage = MemoryTokenStorage('saved-token');
    final auth = ProtheusAuth(
      tokenStorage: storage,
      client: MockClient((_) async => http.Response('', 500)),
    );

    await auth.restoreSession();

    expect(auth.token, 'saved-token');
  });

  test(
    'does not restore an empty stored token as an authenticated session',
    () async {
      final storage = MemoryTokenStorage('');
      final auth = ProtheusAuth(
        tokenStorage: storage,
        client: MockClient((_) async => http.Response('', 500)),
      );

      await auth.restoreSession();

      expect(auth.token, isNull);
      expect(storage.token, isNull);
    },
  );

  test(
    'discards an expired restored token without showing an authenticated session',
    () async {
      final expiration =
          DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 - 60;
      final payload = base64Url.encode(
        utf8.encode(jsonEncode({'exp': expiration})),
      );
      final storage = MemoryTokenStorage('header.$payload.signature');
      final auth = ProtheusAuth(
        tokenStorage: storage,
        client: MockClient((_) async => http.Response('', 500)),
      );

      await auth.restoreSession();

      expect(auth.token, isNull);
      expect(storage.token, isNull);
    },
  );

  test('reports secure-storage errors during startup', () async {
    final storage =
        MemoryTokenStorage()..readError = StateError('storage unavailable');
    final auth = ProtheusAuth(
      tokenStorage: storage,
      client: MockClient((_) async => http.Response('', 500)),
    );

    await expectLater(auth.restoreSession(), throwsA(isA<StateError>()));

    expect(auth.sessionError, contains('storage unavailable'));
    expect(auth.isInitialized, isTrue);
  });

  test('logout removes the persisted token', () async {
    final storage = MemoryTokenStorage('saved-token');
    final auth = ProtheusAuth(
      tokenStorage: storage,
      client: MockClient((_) async => http.Response('', 500)),
    );
    await auth.restoreSession();

    await auth.logout();

    expect(storage.token, isNull);
    expect(auth.token, isNull);
  });

  test('surfaces secure-storage failures when persisting a token', () async {
    final storage =
        MemoryTokenStorage()..writeError = StateError('storage unavailable');
    final auth = ProtheusAuth(
      tokenStorage: storage,
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'access_token': 'fresh-token'}), 200),
      ),
    );

    expect(await auth.signUp('user', 'password'), isFalse);
    expect(auth.mensagemErro, contains('Erro ao salvar'));
    expect(storage.token, isNull);
  });

  test(
    'keeps the active session and reports logout storage failures',
    () async {
      final storage = MemoryTokenStorage('saved-token');
      final auth = ProtheusAuth(
        tokenStorage: storage,
        client: MockClient((_) async => http.Response('', 500)),
      );
      await auth.restoreSession();
      storage.deleteError = StateError('storage unavailable');

      await expectLater(auth.logout(), throwsA(isA<StateError>()));

      expect(auth.token, 'saved-token');
      expect(storage.token, 'saved-token');
    },
  );

  test('successful authentication persists only the access token', () async {
    final storage = MemoryTokenStorage();
    final auth = ProtheusAuth(
      tokenStorage: storage,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'access_token': 'fresh-token',
            'refresh_token': 'unused',
          }),
          200,
        ),
      ),
    );

    expect(await auth.signUp('user', 'password'), isTrue);
    expect(auth.token, 'fresh-token');
    expect(storage.token, 'fresh-token');
  });
}
