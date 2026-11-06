import 'package:flutter/material.dart';
import 'package:ibar_app/screens/home_screen.dart';
import 'package:ibar_app/screens/login_screen.dart';
import 'package:ibar_app/services/protheus_auth.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => ProtheusAuth())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreSession();
    });
  }

  Future<void> _restoreSession() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<ProtheusAuth>(context, listen: false);
    try {
      await auth.restoreSession();
    } catch (_) {
      // The error is shown below so a storage failure is not mistaken for logout.
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<ProtheusAuth>(context, listen: false);
    return MaterialApp(
      title: 'IBAR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:
          _isLoading || !auth.isInitialized
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : auth.sessionError != null
              ? Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(auth.sessionError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _restoreSession,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              : auth.token != null
              ? const HomeScreen()
              : const LoginScreen(),
    );
  }
}
