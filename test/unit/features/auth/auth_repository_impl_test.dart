import 'package:flutter_clean_architecture_riverpod/core/errors/failure.dart';
import 'package:flutter_clean_architecture_riverpod/core/errors/result.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/fake_auth_remote_data_source.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/credentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/memory_token_storage.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  group('AuthRepositoryImpl', () {
    test('signIn stores the session from the fake source', () async {
      final storage = MemoryTokenStorage();
      final repository = AuthRepositoryImpl(
        remote: const FakeAuthRemoteDataSource(),
        tokenStorage: storage,
      );

      final result = await repository.signIn(
        const Credentials(email: 'person@example.com', password: 'password1'),
      );

      final session = result.fold(
        onSuccess: (value) => value,
        onFailure: (_) => null,
      );
      final stored = await storage.readSession();
      expect(session?.email, 'person@example.com');
      expect(stored?.token, 'fake-token');
      expect(stored?.email, 'person@example.com');
    });

    test('signIn returns a validation failure for a blank email', () async {
      final repository = AuthRepositoryImpl(
        remote: const FakeAuthRemoteDataSource(),
        tokenStorage: MemoryTokenStorage(),
      );

      final result = await repository.signIn(
        const Credentials(email: ' ', password: 'password1'),
      );

      final failure = result.fold(
        onSuccess: (_) => null,
        onFailure: (value) => value,
      );
      expect(failure, isA<ValidationFailure>());
    });

    test(
      'signOut clears a stored session without calling the remote',
      () async {
        final remote = MockAuthRemoteDataSource();
        final storage = MemoryTokenStorage();
        await storage.writeSession(
          token: 'secret',
          email: 'person@example.com',
        );
        final repository = AuthRepositoryImpl(
          remote: remote,
          tokenStorage: storage,
        );

        final result = await repository.signOut();

        expect(result, isA<Success<bool>>());
        expect(await storage.readSession(), isNull);
        verifyNever(
          () => remote.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );
  });
}
