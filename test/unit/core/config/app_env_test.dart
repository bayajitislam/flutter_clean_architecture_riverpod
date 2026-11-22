import 'package:flutter_clean_architecture_riverpod/core/config/app_env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseAppFlavor accepts the three flavors', () {
    expect(parseAppFlavor('dev'), AppFlavor.dev);
    expect(parseAppFlavor('staging'), AppFlavor.staging);
    expect(parseAppFlavor('prod'), AppFlavor.prod);
  });

  test('parseAppFlavor rejects an unknown flavor', () {
    expect(() => parseAppFlavor('qa'), throwsStateError);
  });

  test('development may omit the API URL', () {
    const env = AppEnv(
      flavor: AppFlavor.dev,
      apiBaseUrl: '',
      appName: 'Flutter Clean Architecture Riverpod',
    );

    env.validate();

    expect(env.hasApi, isFalse);
  });

  test('staging and production require an API URL', () {
    const staging = AppEnv(
      flavor: AppFlavor.staging,
      apiBaseUrl: ' ',
      appName: 'Flutter Clean Architecture Riverpod',
    );
    const production = AppEnv(
      flavor: AppFlavor.prod,
      apiBaseUrl: '',
      appName: 'Flutter Clean Architecture Riverpod',
    );

    expect(staging.validate, throwsStateError);
    expect(production.validate, throwsStateError);
  });
}
