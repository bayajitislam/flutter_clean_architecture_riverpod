import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/fake_auth_remote_data_source.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/providers/auth_data_providers.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_token_storage.dart';

void main() {
  testWidgets('login screen rejects an empty form', (tester) async {
    final storage = MemoryTokenStorage();
    final repository = AuthRepositoryImpl(
      remote: const FakeAuthRemoteDataSource(),
      tokenStorage: storage,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter an email'), findsOneWidget);
    expect(find.text('Enter a password'), findsOneWidget);
    expect(await storage.readSession(), isNull);
  });
}
