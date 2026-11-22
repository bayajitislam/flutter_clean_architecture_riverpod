import 'dart:async';

import 'package:flutter_clean_architecture_riverpod/features/auth/data/providers/auth_data_providers.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/credentials.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/usecases/read_session.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/usecases/sign_in.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/usecases/sign_out.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:flutter_clean_architecture_riverpod/features/auth/presentation/providers/auth_state.dart';

final signInProvider = Provider<SignIn>((ref) {
  return SignIn(ref.watch(authRepositoryProvider));
});

final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});

final readSessionProvider = Provider<ReadSession>((ref) {
  return ReadSession(ref.watch(authRepositoryProvider));
});

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(restore());
    return const AuthState();
  }

  Future<void> restore() async {
    final result = await ref.read(readSessionProvider).call();
    if (!ref.mounted) {
      return;
    }
    state = result.fold(
      onSuccess: (session) {
        return AuthState(
          status: session == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          session: session,
        );
      },
      onFailure: (failure) {
        return AuthState(status: AuthStatus.unauthenticated, failure: failure);
      },
    );
  }

  Future<bool> signIn(Credentials credentials) async {
    state = state.copyWith(isSubmitting: true, failure: null);
    final result = await ref.read(signInProvider).call(credentials);
    if (!ref.mounted) {
      return false;
    }
    return result.fold(
      onSuccess: (session) {
        state = AuthState(status: AuthStatus.authenticated, session: session);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isSubmitting: false,
          failure: failure,
        );
        return false;
      },
    );
  }

  Future<void> signOut() async {
    final result = await ref.read(signOutProvider).call();
    if (!ref.mounted) {
      return;
    }
    state = result.fold(
      onSuccess: (_) => const AuthState(status: AuthStatus.unauthenticated),
      onFailure: (failure) {
        return state.copyWith(isSubmitting: false, failure: failure);
      },
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
