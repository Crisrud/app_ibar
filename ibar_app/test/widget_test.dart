import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ibar_app/main.dart';
import 'package:ibar_app/services/protheus_auth.dart';
import 'package:ibar_app/services/token_storage.dart';
import 'package:provider/provider.dart';

class _MemoryTokenStorage implements TokenStorage {
  _MemoryTokenStorage([this.token]);

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async {
    token = value;
  }

  @override
  Future<void> deleteToken() async {
    token = null;
  }
}

void main() {
  testWidgets('renders the IBAR login screen', (WidgetTester tester) async {
    final auth = ProtheusAuth(
      tokenStorage: _MemoryTokenStorage(),
      client: MockClient((_) async => http.Response('', 500)),
    );
    addTearDown(auth.dispose);

    await _pumpApp(tester, auth);

    expect(find.text('Bem-vindo!'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('restores a saved session to the home screen', (
    WidgetTester tester,
  ) async {
    final auth = ProtheusAuth(
      tokenStorage: _MemoryTokenStorage('saved-token'),
      client: MockClient((_) async => http.Response('', 500)),
    );
    addTearDown(auth.dispose);

    await _pumpApp(tester, auth);

    expect(find.text('IBAR'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}

Future<void> _pumpApp(WidgetTester tester, ProtheusAuth auth) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(value: auth, child: const MyApp()),
  );
  await tester.pump();
  await tester.pump();
}
