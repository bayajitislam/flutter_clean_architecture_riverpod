import 'package:flutter_clean_architecture_riverpod/core/constants/storage_keys.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A persisted auth session.
///
/// Only the token and the account email are stored. Passwords are not.
class StoredSession {
  const StoredSession({required this.token, required this.email});

  final String token;
  final String email;
}

/// Reads and writes the current session token.
abstract class TokenStorage {
  Future<StoredSession?> readSession();

  Future<void> writeSession({required String token, required String email});

  Future<void> clear();
}

/// [TokenStorage] backed by the platform secure store.
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<StoredSession?> readSession() async {
    final token = await _storage.read(key: StorageKeys.authToken);
    final email = await _storage.read(key: StorageKeys.authEmail);
    if (token == null || token.isEmpty || email == null || email.isEmpty) {
      return null;
    }
    return StoredSession(token: token, email: email);
  }

  @override
  Future<void> writeSession({
    required String token,
    required String email,
  }) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
    await _storage.write(key: StorageKeys.authEmail, value: email);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: StorageKeys.authToken);
    await _storage.delete(key: StorageKeys.authEmail);
  }
}
