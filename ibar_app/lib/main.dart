import 'package:flutter/material.dart';
import 'package:ibar_app/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'package:ibar_app/screens/home_screen.dart';
import 'package:ibar_app/screens/login_screen.dart';
import 'package:ibar_app/services/api_config.dart';
import 'package:ibar_app/services/protheus_auth.dart';
import 'package:ibar_app/services/protheus_api_client.dart';
import 'package:ibar_app/services/protheus_operations_api.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProtheusAuth()),
        Provider<ApiConfig>(create: (_) => ApiConfig.development()),
        Provider<ProtheusApiClient>(
          create:
              (context) => ProtheusApiClient(
                config: context.read<ApiConfig>(),
                httpClient: http.Client(),
              ),
          dispose: (_, client) => client.close(),
        ),
        Provider<ProtheusOperationsApi>(
          create:
              (context) => ProtheusOperationsApi(
                config: context.read<ApiConfig>(),
                client: context.read<ProtheusApiClient>(),
              ),
        ),
      ],
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          primary: AppColors.primaryColor,
          surface: AppColors.surfaceColor,
        ),
        scaffoldBackgroundColor: AppColors.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceColor,
          foregroundColor: AppColors.primaryDarkColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.primaryDarkColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceColor,
          elevation: 1,
          shadowColor: AppColors.cardShadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderColor),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 1.5,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: AppColors.primaryDarkColor,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: AppColors.primaryDarkColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: AppColors.mutedColor, height: 1.45),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:
          _isLoading || !auth.isInitialized
              ? Scaffold(
                body: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Preparando seu acesso...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              : auth.sessionError != null
              ? Scaffold(
                body: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 44,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              auth.sessionError!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _restoreSession,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
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
