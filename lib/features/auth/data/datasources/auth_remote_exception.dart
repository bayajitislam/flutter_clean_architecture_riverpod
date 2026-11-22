/// Expected rejection from an auth data source.
final class AuthRemoteException implements Exception {
  const AuthRemoteException(this.message);

  final String message;

  @override
  String toString() => message;
}
