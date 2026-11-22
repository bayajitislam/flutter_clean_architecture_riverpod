import 'dart:async';

import 'package:flutter_clean_architecture_riverpod/core/errors/failure.dart';
import 'package:flutter_clean_architecture_riverpod/core/errors/result.dart';

/// One in-flight list request for a [Notifier].
///
/// [schedule] waits until after `build` returns before calling [load], so the
/// notifier does not change `state` while Riverpod is still building it.
/// A second [run] is ignored until the current request finishes. Results are
/// dropped when [mounted] is false or a newer request has replaced this one.
class RequestGate {
  var _inFlight = false;
  var _generation = 0;

  void schedule(Future<void> Function() load) {
    Future<void>.microtask(() {
      unawaited(load());
    });
  }

  Future<void> run<T>({
    required bool Function() mounted,
    required bool alreadyLoading,
    required void Function() markLoading,
    required Future<Result<List<T>>> Function() request,
    required void Function(List<T> items) onSuccess,
    required void Function(Failure failure) onFailure,
    void Function(Object error, StackTrace stackTrace)? onUnexpected,
  }) async {
    if (!mounted() || _inFlight) {
      return;
    }
    _inFlight = true;
    final generation = ++_generation;
    try {
      if (mounted() && !alreadyLoading) {
        markLoading();
      }
      final result = await request();
      if (!mounted() || generation != _generation) {
        return;
      }
      result.fold(onSuccess: onSuccess, onFailure: onFailure);
    } on Object catch (error, stackTrace) {
      if (!mounted() || generation != _generation) {
        return;
      }
      onUnexpected?.call(error, stackTrace);
      onFailure(const UnknownFailure());
    } finally {
      if (generation == _generation) {
        _inFlight = false;
      }
    }
  }
}
