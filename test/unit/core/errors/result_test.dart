import 'package:flutter_clean_architecture_riverpod/core/errors/failure.dart';
import 'package:flutter_clean_architecture_riverpod/core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('fold returns the success value', () {
      const result = Result<int>.success(2);

      expect(result.fold(onSuccess: (value) => value, onFailure: (_) => -1), 2);
    });

    test('fold returns the failure branch', () {
      const result = Result<int>.failure(ValidationFailure('Enter an email'));

      expect(
        result.fold(
          onSuccess: (value) => value,
          onFailure: (failure) => failure.message,
        ),
        'Enter an email',
      );
      expect(result, isA<ErrorResult<int>>());
    });
  });
}
