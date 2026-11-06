import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ibar_app/screens/login_screen.dart';
import 'package:ibar_app/services/protheus_auth.dart';
import 'package:ibar_app/services/token_storage.dart';
import 'package:provider/provider.dart';

class _MemoryTokenStorage implements TokenStorage {
  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> writeToken(String value) async {}

  @override
  Future<void> deleteToken() async {}
}

void main() {
  testWidgets('login shows progress and prevents concurrent submissions', (
    WidgetTester tester,
  ) async {
    final response = Completer<http.Response>();
    var requestCount = 0;
    final auth = ProtheusAuth(
      tokenStorage: _MemoryTokenStorage(),
      client: MockClient((_) async {
        requestCount++;
        return response.future;
      }),
    );
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '  alice  ');
    await tester.enterText(fields.at(1), 'password');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final submitButton = find.byType(ElevatedButton);
    expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);

    await tester.tap(submitButton);
    await tester.pump();
    expect(requestCount, 1);

    response.complete(http.Response('', 401));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    expect(
      (tester.widget<TextFormField>(fields.at(0)).controller)!.text,
      '  alice  ',
    );
    expect(
      (tester.widget<TextFormField>(fields.at(1)).controller)!.text,
      'password',
    );
  });
}
