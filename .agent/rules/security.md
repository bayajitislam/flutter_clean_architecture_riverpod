# Security

- Tokens go in `TokenStorage` (`FlutterSecureStorage`). Passwords are not stored.
- Theme and other preferences go in `PreferencesStorage`.
- Environment values come from `--dart-define-from-file`. Commit `env/*.json.example` only.
- Development may omit `API_BASE_URL` and use the fake auth source. Staging and production throw at startup when `API_BASE_URL` is empty. An unknown `FLAVOR` throws.
- `env/*.json`, `key.properties`, and keystores are gitignored.
- `RedactingLogInterceptor` logs the method, path, and status code through `AppLogger.api`. It does not log the `Authorization` header, query, or body.
- Features call `AppLogger`. They do not construct another logger or call `DevLog` directly.
- Development logs every level. Staging logs warnings and errors. Production disables logging. Release builds drop `flutter_devlog` calls because they live inside `assert`.
- Validate email and password before `SignIn` runs.
- Do not turn off certificate checks, lint rules, or tests to get past a failure.
- Report a vulnerability privately, as `SECURITY.md` describes. Do not open a public issue for it.

The rename CLI will not edit `google-services.json`, `GoogleService-Info.plist`, entitlements, or URL schemes. Changing the bundle id does not register a new Firebase app or provisioning profile.
