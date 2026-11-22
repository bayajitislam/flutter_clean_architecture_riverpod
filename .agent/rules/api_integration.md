# API integration

All HTTP goes through `dioProvider` in `lib/core/network/dio_provider.dart`.

- Data sources live in `data/datasources` and return models, not widgets.
- Convert models to entities inside the repository implementation.
- Map `DioException` with `mapDioException`. Do not parse a raw response in a screen.
- Read the base URL from `AppEnv`. An empty `API_BASE_URL` selects `FakeAuthRemoteDataSource`.
- Attach the bearer token only in `AuthInterceptor`.
- Pass a Dio `CancelToken` into a data source when the caller can dispose the screen first.
- The debug logger records the method, path, and status code through `AppLogger`. It must not record headers, query strings, or bodies.

## Do not

```dart
final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
```

## Do

```dart
final response = await dio.post<Object?>(
  '/auth/sign-in',
  data: <String, String>{'email': email, 'password': password},
  cancelToken: cancelToken,
);
```

Do not invent endpoints. The template's only real route is `POST /auth/sign-in`, and it stays unused until `API_BASE_URL` is set. The feature generator's remote source throws `UnimplementedError` until a real path is approved.
