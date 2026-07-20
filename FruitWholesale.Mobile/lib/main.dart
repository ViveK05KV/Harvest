import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';

void main() {
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);
  final authService = AuthService(apiClient, tokenStorage);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        ChangeNotifierProvider.value(value: authService),
      ],
      child: const FruitWholesaleApp(),
    ),
  );
}

class FruitWholesaleApp extends StatefulWidget {
  const FruitWholesaleApp({super.key});

  @override
  State<FruitWholesaleApp> createState() => _FruitWholesaleAppState();
}

class _FruitWholesaleAppState extends State<FruitWholesaleApp> {
  @override
  void initState() {
    super.initState();
    context.read<AuthService>().restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit Wholesale',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isRestoring) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return auth.isAuthenticated ? const HomeShell() : const LoginScreen();
        },
      ),
    );
  }
}
