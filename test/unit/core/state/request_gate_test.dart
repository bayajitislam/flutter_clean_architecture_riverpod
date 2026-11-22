import 'dart:async';

import 'package:flutter_clean_architecture_riverpod/core/errors/failure.dart';
import 'package:flutter_clean_architecture_riverpod/core/errors/result.dart';
import 'package:flutter_clean_architecture_riverpod/core/state/request_gate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestGate', () {
    test('initial load stays loading until the request finishes', () async {
      final harness = _Harness();
      final container = harness.container;

      final initial = container.read(harness.provider);

      expect(initial.isLoading, isTrue);
      expect(initial.items, isEmpty);
      expect(harness.calls, 0);

      await Future<void>.value();
      expect(harness.calls, 1);
      expect(container.read(harness.provider).isLoading, isTrue);

      harness.complete(const Result.success(['Ada']));
      await Future<void>.value();

      final loaded = container.read(harness.provider);
      expect(loaded.isLoading, isFalse);
      expect(loaded.items, ['Ada']);
      expect(loaded.failure, isNull);
      container.dispose();
    });

    test('an empty response stays a success', () async {
      final harness = _Harness();
      await Future<void>.value();
      harness.complete(const Result.success([]));
      await Future<void>.value();

      final state = harness.container.read(harness.provider);
      expect(state.items, isEmpty);
      expect(state.failure, isNull);
      expect(state.isLoading, isFalse);
      harness.container.dispose();
    });

    test(
      'a failed result is stored and an exception becomes unknown',
      () async {
        final failed = _Harness();
        await Future<void>.value();
        failed.complete(const Result.failure(ValidationFailure('no')));
        await Future<void>.value();
        expect(
          failed.container.read(failed.provider).failure,
          isA<ValidationFailure>(),
        );
        failed.container.dispose();

        final broken = _Harness();
        await Future<void>.value();
        broken.fail(StateError('boom'));
        await Future<void>.value();
        expect(
          broken.container.read(broken.provider).failure,
          isA<UnknownFailure>(),
        );
        broken.container.dispose();
      },
    );

    test('a second call does not start another request', () async {
      final harness = _Harness();
      await Future<void>.value();
      expect(harness.calls, 1);

      final duplicate = harness.container
          .read(harness.provider.notifier)
          .load();
      await Future<void>.value();
      expect(harness.calls, 1);

      harness.complete(const Result.success(['Ada']));
      await duplicate;
      await Future<void>.value();
      expect(harness.container.read(harness.provider).items, ['Ada']);

      final again = harness.container.read(harness.provider.notifier).load();
      await Future<void>.value();
      expect(harness.calls, 2);
      harness.complete(const Result.success(['Bea']));
      await again;
      expect(harness.container.read(harness.provider).items, ['Bea']);
      harness.container.dispose();
    });

    test('disposal during a request does not write state', () async {
      final harness = _Harness();
      await Future<void>.value();
      harness.container.dispose();
      harness.complete(const Result.success(['Ada']));
      await Future<void>.value();
      expect(harness.calls, 1);
    });
  });
}

class _Items {
  const _Items({this.items = const [], this.failure, this.isLoading = false});

  final List<String> items;
  final Failure? failure;
  final bool isLoading;
}

class _Harness {
  _Harness() {
    provider = NotifierProvider<_Controller, _Items>(() => _Controller(this));
    container = ProviderContainer();
    container.read(provider);
  }

  late final NotifierProvider<_Controller, _Items> provider;
  late final ProviderContainer container;
  final pending = <Completer<Result<List<String>>>>[];
  var calls = 0;

  Future<Result<List<String>>> request() {
    calls++;
    final completer = Completer<Result<List<String>>>();
    pending.add(completer);
    return completer.future;
  }

  void complete(Result<List<String>> result) {
    pending.removeAt(0).complete(result);
  }

  void fail(Object error) {
    pending.removeAt(0).completeError(error);
  }
}

class _Controller extends Notifier<_Items> {
  _Controller(this._harness);

  final _Harness _harness;
  final _requests = RequestGate();

  @override
  _Items build() {
    _requests.schedule(load);
    return const _Items(isLoading: true);
  }

  Future<void> load() {
    return _requests.run<String>(
      mounted: () => ref.mounted,
      alreadyLoading:
          state.isLoading && state.failure == null && state.items.isEmpty,
      markLoading: () => state = const _Items(isLoading: true),
      request: _harness.request,
      onSuccess: (items) => state = _Items(items: items),
      onFailure: (failure) => state = _Items(failure: failure),
    );
  }
}
