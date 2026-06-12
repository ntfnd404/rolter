import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support/test_route.dart';

/// Cancels navigation if the requested stack contains a `blocked` route.
class _BlockGuard with ChangeNotifier implements RouteGuard<TestRoute> {
  @override
  GuardResult<TestRoute> call(
    List<List<TestRoute>> history,
    List<TestRoute> requested,
    Map<String, Object?> context,
  ) => requested.any((r) => r.name == 'blocked')
      ? const GuardResult.cancel()
      : GuardResult.proceed(requested);
}

/// Redirects to `lock` while [on], remembering the intent; restores it when
/// turned off and the lock screen is requested.
class _LockGuard with ChangeNotifier implements RouteGuard<TestRoute> {
  _LockGuard({required bool initiallyOn}) : _on = initiallyOn;

  bool _on;
  List<TestRoute>? intended;

  set on(bool value) {
    _on = value;
    notifyListeners();
  }

  @override
  GuardResult<TestRoute> call(
    List<List<TestRoute>> history,
    List<TestRoute> requested,
    Map<String, Object?> context,
  ) {
    final onLock = requested.any((r) => r.name == 'lock');
    if (_on) {
      if (!onLock) {
        intended = requested;
        return const GuardResult.proceed([TestRoute('lock')]);
      }
      return GuardResult.proceed(requested);
    }
    final saved = intended;
    if (saved != null && onLock) {
      intended = null;
      return GuardResult.proceed(saved);
    }
    return GuardResult.proceed(requested);
  }
}

/// Writes a value into the shared `context` map.
class _ContextWriter with ChangeNotifier implements RouteGuard<TestRoute> {
  @override
  GuardResult<TestRoute> call(
    List<List<TestRoute>> history,
    List<TestRoute> requested,
    Map<String, Object?> context,
  ) {
    context['k'] = 'v';
    return GuardResult.proceed(requested);
  }
}

/// Records what it read from the shared `context` map.
class _ContextReader with ChangeNotifier implements RouteGuard<TestRoute> {
  Object? seen;

  @override
  GuardResult<TestRoute> call(
    List<List<TestRoute>> history,
    List<TestRoute> requested,
    Map<String, Object?> context,
  ) {
    seen = context['k'];
    return GuardResult.proceed(requested);
  }
}

/// Records the length of the `history` it is handed each run.
class _HistorySpy with ChangeNotifier implements RouteGuard<TestRoute> {
  int lastLength = -1;

  @override
  GuardResult<TestRoute> call(
    List<List<TestRoute>> history,
    List<TestRoute> requested,
    Map<String, Object?> context,
  ) {
    lastLength = history.length;
    return GuardResult.proceed(requested);
  }
}

void main() {
  List<TestRoute> identity(List<TestRoute> stack) => stack;

  group('GuardedPipeline', () {
    test('proceeds unchanged with no guards', () async {
      final pipeline = GuardedPipeline<TestRoute>(
        guards: const [],
        normalize: identity,
        currentStack: () => const [],
      );

      final out = await pipeline.call([const TestRoute('a')]);

      expect(out.map((r) => r.name), ['a']);
    });

    test('applies normalize', () async {
      final pipeline = GuardedPipeline<TestRoute>(
        guards: const [],
        normalize: (stack) => [const TestRoute('home'), ...stack],
        currentStack: () => const [],
      );

      final out = await pipeline.call([const TestRoute('a')]);

      expect(out.map((r) => r.name), ['home', 'a']);
    });

    test('a cancelling guard keeps the current stack', () async {
      final current = [const TestRoute('a')];
      final pipeline = GuardedPipeline<TestRoute>(
        guards: [_BlockGuard()],
        normalize: identity,
        currentStack: () => current,
      );

      final out = await pipeline.call([const TestRoute('blocked')]);

      expect(out.map((r) => r.name), ['a']);
    });

    test(
      'a guard can rewrite the stack (redirect) and remember intent',
      () async {
        final guard = _LockGuard(initiallyOn: true);
        final pipeline = GuardedPipeline<TestRoute>(
          guards: [guard],
          normalize: identity,
          currentStack: () => const [],
        );

        final out = await pipeline.call([const TestRoute('protected')]);

        expect(out.map((r) => r.name), ['lock']);
        expect(guard.intended!.map((r) => r.name), ['protected']);
      },
    );

    test('restores the intended stack when the guard turns off', () async {
      final guard = _LockGuard(initiallyOn: true);
      final pipeline = GuardedPipeline<TestRoute>(
        guards: [guard],
        normalize: identity,
        currentStack: () => const [],
      );

      await pipeline.call([const TestRoute('protected')]);
      guard.on = false;
      final out = await pipeline.call([const TestRoute('lock')]);

      expect(out.map((r) => r.name), ['protected']);
    });

    test('shares the context map across guards in one run', () async {
      final reader = _ContextReader();
      final pipeline = GuardedPipeline<TestRoute>(
        guards: [_ContextWriter(), reader],
        normalize: identity,
        currentStack: () => const [],
      );

      await pipeline.call([const TestRoute('a')]);

      expect(reader.seen, 'v');
    });

    test('refresh fires when a guard notifies', () {
      final guard = _LockGuard(initiallyOn: true);
      final pipeline = GuardedPipeline<TestRoute>(
        guards: [guard],
        normalize: identity,
        currentStack: () => const [],
      );
      var fired = 0;
      pipeline.refresh.addListener(() => fired++);

      guard.on = false;

      expect(fired, 1);
    });

    test('history handed to guards is bounded by historyLimit', () async {
      final spy = _HistorySpy();
      final pipeline = GuardedPipeline<TestRoute>(
        guards: [spy],
        normalize: identity,
        currentStack: () => const [],
        historyLimit: 3,
      );

      for (var i = 0; i < 6; i++) {
        await pipeline.call([TestRoute('r$i')]);
      }

      expect(spy.lastLength, lessThanOrEqualTo(3));
    });
  });
}
