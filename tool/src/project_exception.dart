/// A user-facing failure from the project CLI.
class ProjectToolException implements Exception {
  ProjectToolException(this.message);

  final String message;

  @override
  String toString() => message;
}
