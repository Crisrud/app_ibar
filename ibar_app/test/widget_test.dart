import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ibar_app/main.dart';
import 'package:ibar_app/screens/queries_screen.dart';
import 'package:ibar_app/screens/workflow_screen.dart';
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

  testWidgets('shows visible validation when login fields are empty', (
    WidgetTester tester,
  ) async {
    final auth = ProtheusAuth(
      tokenStorage: _MemoryTokenStorage(),
      client: MockClient((_) async => http.Response('', 500)),
    );
    addTearDown(auth.dispose);

    await _pumpApp(tester, auth);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Por favor, digite seu usuário'), findsOneWidget);
    expect(find.text('Por favor, digite sua senha'), findsOneWidget);
  });

  testWidgets('preserves username spaces in the authentication request', (
    WidgetTester tester,
  ) async {
    String? submittedUsername;
    final auth = ProtheusAuth(
      tokenStorage: _MemoryTokenStorage(),
      client: MockClient((request) async {
        submittedUsername = request.headers['username'];
        return http.Response('', 401);
      }),
    );
    addTearDown(auth.dispose);

    await _pumpApp(tester, auth);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '  user  ');
    await tester.enterText(fields.at(1), 'password');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(submittedUsername, '  user  ');
  });

  testWidgets('shows an unavailable state instead of a fake query form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: QueriesScreen()));

    expect(
      find.text('Esta funcionalidade ainda não está integrada.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Pesquisar'), findsNothing);
  });

  testWidgets('shows an unavailable state instead of sample workflow records', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WorkflowScreen()));

    expect(
      find.text('Esta funcionalidade ainda não está integrada.'),
      findsOneWidget,
    );
    expect(find.textContaining('Processo #'), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('login validation remains usable on a narrow screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = ProtheusAuth(
      tokenStorage: _MemoryTokenStorage(),
      client: MockClient((_) async => http.Response('', 500)),
    );
    addTearDown(auth.dispose);

    await _pumpApp(tester, auth);
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Por favor, digite seu usuário'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu navigation keeps a single app bar and returns home', (
    WidgetTester tester,
  ) async {
    final auth = ProtheusAuth(
      tokenStorage: _MemoryTokenStorage('saved-token'),
      client: MockClient((_) async => http.Response('', 500)),
    );
    addTearDown(auth.dispose);

    await _pumpApp(tester, auth);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Workflow')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Esta funcionalidade ainda não está integrada.'),
      findsOneWidget,
    );
    expect(find.byType(AppBar), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo!'), findsOneWidget);
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
