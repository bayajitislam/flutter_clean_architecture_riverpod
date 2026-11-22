import 'package:flutter_clean_architecture_riverpod/core/storage/token_storage.dart';

class MemoryTokenStorage implements TokenStorage {
  StoredSession? session;

  @override
  Future<void> clear() async {
    session = null;
  }

  @override
  Future<StoredSession?> readSession() async => session;

  @override
  Future<void> writeSession({
    required String token,
    required String email,
  }) async {
    session = StoredSession(token: token, email: email);
  }
}
