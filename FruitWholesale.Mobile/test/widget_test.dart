import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fruit_wholesale_mobile/core/api/api_client.dart';
import 'package:fruit_wholesale_mobile/core/auth/auth_service.dart';
import 'package:fruit_wholesale_mobile/core/auth/token_storage.dart';
import 'package:fruit_wholesale_mobile/features/auth/login_screen.dart';

void main() {
  testWidgets('shows the login form when not authenticated', (tester) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage);
    final authService = AuthService(apiClient, tokenStorage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: apiClient),
          ChangeNotifierProvider.value(value: authService),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
