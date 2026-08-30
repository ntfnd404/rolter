import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support/test_route.dart';

/// Records every transition it is handed.
class _CapturingObserver implements NavObserver<TestRoute> {
  final List<NavTransition<TestRoute>> transitions =
      <NavTransition<TestRoute>>[];

  @override
  void onTransition(NavTransition<TestRoute> transition) =>
      transitions.add(transition);
}

class _ThrowingOnceObserver implements NavObserver<TestRoute> {
  int calls = 0;

  @override
  void onTransition(NavTransition<TestRoute> transition) {
    calls++;
    if (calls == 1) {
      throw StateError('telemetry failed');
    }
  }
}

StateError _captureStateError(VoidCallback action) {
  try {
    action();
  } on StateError catch (error) {
    return error;
  }
  fail('Expected a StateError.');
}

void main() {
  // Identity pipeline — no normalisation, no guards.
  RoutesState<TestRoute> stateWith(List<TestRoute> initial) =>
      RoutesState<TestRoute>(initial, (stack) => stack);

  group('RoutesState mutations', () {
    test('rejects an empty initial committed root', () {
      expect(
        () => RoutesState<TestRoute>(const <TestRoute>[], (stack) => stack),
        throwsA(
          isA<ArgumentError>().having(
            (error) => '$error',
            'message',
            isNot(contains('TestRoute')),
          ),
        ),
      );
    });

    test('allows the pipeline to normalize an empty requested stack', () async {
      final state = RoutesState<TestRoute>(
        const [TestRoute('committed')],
        (
          requested,
        ) => requested.isEmpty
            ? const <TestRoute>[TestRoute('normalized')]
            : requested,
      );
      addTearDown(state.dispose);

      state.setRoot(const <TestRoute>[]);
      await state.processingCompleted;

      expect(state.root, const <TestRoute>[TestRoute('normalized')]);
    });

    test(
      'rejects an empty final stack without committing and then recovers',
      () async {
        var rejectAsEmpty = true;
        var pipelineCalls = 0;
        var listenerCalls = 0;
        final observer = _CapturingObserver();
        final state = RoutesState<TestRoute>(
          const [TestRoute('committed')],
          (requested) {
            pipelineCalls++;
            return rejectAsEmpty ? const <TestRoute>[] : requested;
          },
          observers: <NavObserver<TestRoute>>[observer],
        );
        addTearDown(state.dispose);
        state.addListener(() => listenerCalls++);

        state.setRoot(const <TestRoute>[TestRoute('rejected')]);
        state.push(const TestRoute('discarded'));
        final failure = state.processingCompleted;

        await expectLater(
          failure,
          throwsA(
            isA<StateError>().having(
              (error) => '$error',
              'message',
              allOf(
                isNot(contains('rejected')),
                isNot(contains('TestRoute')),
                isNot(contains('ValueKey')),
              ),
            ),
          ),
        );
        expect(state.root, const <TestRoute>[TestRoute('committed')]);
        expect(listenerCalls, 0);
        expect(observer.transitions, isEmpty);
        expect(pipelineCalls, 1);

        rejectAsEmpty = false;
        state.push(const TestRoute('recovered'));
        await state.processingCompleted;

        expect(state.root, const <TestRoute>[
          TestRoute('committed'),
          TestRoute('recovered'),
        ]);
        expect(pipelineCalls, 2);
      },
    );

    test('reports processing without exposing its mutable queue', () async {
      final release = Completer<void>();
      final state = RoutesState<TestRoute>(const [TestRoute('a')], (
        requested,
      ) async {
        await release.future;
        return requested;
      });
      addTearDown(state.dispose);

      state.push(const TestRoute('b'));
      expect(state.isProcessing, isTrue);
      release.complete();
      await state.processingCompleted;

      expect(state.isProcessing, isFalse);
    });

    test('recovers from pipeline failure using committed state', () async {
      var shouldFail = true;
      final state = RoutesState<TestRoute>(const [TestRoute('committed')], (
        requested,
      ) {
        if (shouldFail) {
          throw StateError('policy failed');
        }
        return requested;
      });
      addTearDown(state.dispose);

      state.push(const TestRoute('rejected'));
      state.push(const TestRoute('dependent'));
      await expectLater(state.processingCompleted, throwsStateError);
      expect(state.root.map((route) => route.name), ['committed']);

      shouldFail = false;
      state.push(const TestRoute('recovered'));
      await state.processingCompleted;
      expect(state.root.map((route) => route.name), ['committed', 'recovered']);
    });

    test(
      'keeps the latest pending base when equal snapshots are queued',
      () async {
        final releaseFirst = Completer<void>();
        var pipelineCalls = 0;
        final state = RoutesState<TestRoute>(const [TestRoute('committed')], (
          requested,
        ) async {
          pipelineCalls++;
          if (pipelineCalls == 1) {
            await releaseFirst.future;
            return const [TestRoute('redirected')];
          }

          return requested;
        });
        addTearDown(state.dispose);
        var appended = false;
        state.addListener(() {
          if (!appended && state.top.name == 'redirected') {
            appended = true;
            state.push(const TestRoute('relative'));
          }
        });

        state.setRoot(const [TestRoute('requested')]);
        state.setRoot(const [TestRoute('requested')]);
        releaseFirst.complete();
        await state.processingCompleted;

        expect(state.root.map((route) => route.name), [
          'requested',
          'relative',
        ]);
      },
    );

    test(
      'listener navigation after redirect uses the committed root',
      () async {
        final state = RoutesState<TestRoute>(const [TestRoute('committed')], (
          requested,
        ) {
          if (requested.length == 1 && requested.single.name == 'requested') {
            return const [TestRoute('redirected')];
          }
          return requested;
        });
        addTearDown(state.dispose);
        var appended = false;
        state.addListener(() {
          if (!appended && state.top.name == 'redirected') {
            appended = true;
            state.push(const TestRoute('relative'));
          }
        });

        state.setRoot(const [TestRoute('requested')]);
        await state.processingCompleted;

        expect(state.root.map((route) => route.name), [
          'redirected',
          'relative',
        ]);
      },
    );

    test('push appends to the stack', () async {
      final state = stateWith([const TestRoute('a')]);
      addTearDown(state.dispose);

      state.push(const TestRoute('b'));
      await state.processingCompleted;

      expect(state.root.map((r) => r.name), ['a', 'b']);
      expect(state.top.name, 'b');
      expect(state.canPop, isTrue);
    });

    test('pop removes the top when more than one remains', () async {
      final state = stateWith([const TestRoute('a'), const TestRoute('b')]);
      addTearDown(state.dispose);

      state.pop();
      await state.processingCompleted;

      expect(state.root.map((r) => r.name), ['a']);
      expect(state.canPop, isFalse);
    });

    test('pop is a no-op at a single entry', () async {
      final state = stateWith([const TestRoute('a')]);
      addTearDown(state.dispose);

      state.pop();
      await state.processingCompleted;

      expect(state.root.map((r) => r.name), ['a']);
    });

    test('replaceTop swaps only the top', () async {
      final state = stateWith([const TestRoute('a'), const TestRoute('b')]);
      addTearDown(state.dispose);

      state.replaceTop(const TestRoute('c'));
      await state.processingCompleted;

      expect(state.root.map((r) => r.name), ['a', 'c']);
    });

    test('clearAndPush resets to a single route', () async {
      final state = stateWith([const TestRoute('a'), const TestRoute('b')]);
      addTearDown(state.dispose);

      state.clearAndPush(const TestRoute('c'));
      await state.processingCompleted;

      expect(state.root.map((r) => r.name), ['c']);
    });

    test('pushOrReplaceTop replaces a same-type top, else pushes', () async {
      final state = stateWith([const TestRoute('a')]);
      addTearDown(state.dispose);

      // Same runtime type as the top -> replaceTop.
      state.pushOrReplaceTop(const TestRoute('b'));
      await state.processingCompleted;

      expect(state.root.map((r) => r.name), ['b']);
    });

    test('mutateAt transforms the node at a path (spine copied)', () async {
      final state = stateWith([
        const TestRoute('tabs', children: [TestRoute('a')]),
      ]);
      addTearDown(state.dispose);

      state.mutateAt(
        ['tabs'],
        (node) =>
            const TestRoute('tabs', children: [TestRoute('a'), TestRoute('b')]),
      );
      await state.processingCompleted;

      expect(state.root.first.children.map((c) => c.name), ['a', 'b']);
    });
  });

  group('RoutesState lifecycle', () {
    test('rejects every mutation before callbacks or result side effects', () {
      final state = stateWith([
        const TestRoute('root', children: [TestRoute('child')]),
      ]);
      var transformCalls = 0;
      var predicateCalls = 0;

      state.dispose();

      final errors = <StateError>[
        _captureStateError(
          () => state.setRoot(const [TestRoute('replacement')]),
        ),
        _captureStateError(() => state.push(const TestRoute('pushed'))),
        _captureStateError(state.pop),
        _captureStateError(
          () => state.replaceTop(const TestRoute('replacement')),
        ),
        _captureStateError(
          () => state.clearAndPush(const TestRoute('replacement')),
        ),
        _captureStateError(
          () => state.pushOrReplaceTop(const TestRoute('replacement')),
        ),
        _captureStateError(
          () => state.removeByPageKey(const ValueKey('child')),
        ),
        _captureStateError(
          () => state.mutateAt(['root'], (route) {
            transformCalls++;
            return route;
          }),
        ),
        _captureStateError(
          () => state.popUntil((route) {
            predicateCalls++;
            return true;
          }),
        ),
        _captureStateError(
          () => state.removeWhere((route) {
            predicateCalls++;
            return true;
          }),
        ),
        _captureStateError(
          () => state.pushAndResetTo(const TestRoute('replacement'), (route) {
            predicateCalls++;
            return true;
          }),
        ),
        _captureStateError(state.reevaluate),
        _captureStateError(
          () => state.pushForResult<int>(const TestRoute('result')),
        ),
        _captureStateError(() => state.popWith<int>(42)),
      ];

      expect(errors, everyElement(isA<StateError>()));
      expect(errors.map((error) => error.message).toSet(), {
        'RoutesState has been disposed.',
      });
      expect(identical(errors[0], errors[1]), isFalse);
      expect(transformCalls, 0);
      expect(predicateCalls, 0);
      expect(state.root, [
        const TestRoute('root', children: [TestRoute('child')]),
      ]);
    });

    test(
      'dispose abandons active and queued success without notifications',
      () async {
        final release = Completer<void>();
        final started = Completer<void>();
        var pipelineCalls = 0;
        var notifications = 0;
        final observer = _CapturingObserver();
        final state = RoutesState<TestRoute>(const [TestRoute('committed')], (
          requested,
        ) async {
          pipelineCalls++;
          if (pipelineCalls == 1) {
            started.complete();
            await release.future;
          }
          return requested;
        }, observers: [observer]);
        state.addListener(() => notifications++);

        state.setRoot(const [TestRoute('active')]);
        state.setRoot(const [TestRoute('queued')]);
        final drain = state.processingCompleted;
        await started.future;

        state.dispose();
        release.complete();
        await drain;

        expect(pipelineCalls, 1);
        expect(state.root, const [TestRoute('committed')]);
        expect(notifications, 0);
        expect(observer.transitions, isEmpty);
      },
    );

    test(
      'dispose suppresses an active late error and settles the drain',
      () async {
        final release = Completer<void>();
        final started = Completer<void>();
        final expected = StateError('late policy failure');
        final expectedStack = StackTrace.current;
        final state = RoutesState<TestRoute>(const [TestRoute('committed')], (
          requested,
        ) async {
          started.complete();
          await release.future;
          Error.throwWithStackTrace(expected, expectedStack);
        });

        state.setRoot(const [TestRoute('rejected')]);
        final drain = state.processingCompleted;
        await started.future;

        state.dispose();
        release.complete();
        await drain;

        expect(state.root, const [TestRoute('committed')]);
      },
    );

    test(
      'live failure preserves error identity and stack before recovery',
      () async {
        final expected = StateError('policy failed');
        final expectedStack = StackTrace.current;
        var shouldFail = true;
        final state = RoutesState<TestRoute>(const [TestRoute('committed')], (
          requested,
        ) {
          if (shouldFail) {
            Error.throwWithStackTrace(expected, expectedStack);
          }
          return requested;
        });
        addTearDown(state.dispose);

        state.setRoot(const [TestRoute('rejected')]);
        state.setRoot(const [TestRoute('dependent')]);
        late Object actual;
        late StackTrace actualStack;
        try {
          await state.processingCompleted;
        } on Object catch (error, stack) {
          actual = error;
          actualStack = stack;
        }

        expect(actual, same(expected));
        expect(actualStack.toString(), expectedStack.toString());
        expect(state.root, const [TestRoute('committed')]);

        shouldFail = false;
        state.setRoot(const [TestRoute('recovered')]);
        await state.processingCompleted;
        expect(state.root, const [TestRoute('recovered')]);
      },
    );

    test('borrowed controller inherits disposed-state rejection', () {
      final state = stateWith([const TestRoute('root')]);
      final controller = NavigationController<TestRoute>(state);
      state.dispose();

      expect(
        () => controller.push(const TestRoute('late')),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('RoutesState predicate stack ops', () {
    test('popUntil pops to the topmost match', () async {
      final state = stateWith([
        const TestRoute('a'),
        const TestRoute('b'),
        const TestRoute('c'),
      ]);
      addTearDown(state.dispose);

      state.popUntil((r) => r.name == 'a');
      await state.processingCompleted;

      expect(state.root.map((r) => r.name), ['a']);
    });

    test('removeWhere drops matching nodes', () async {
      final state = stateWith([
        const TestRoute('x1'),
        const TestRoute('keep'),
        const TestRoute('x2'),
      ]);
      addTearDown(state.dispose);

      state.removeWhere((r) => r.name.startsWith('x'));
      await state.processingCompleted;

      expect(state.root.map((r) => r.name), ['keep']);
    });

    test('pushAndResetTo resets to the match then pushes', () async {
      final state = stateWith([const TestRoute('a'), const TestRoute('b')]);
      addTearDown(state.dispose);

      state.pushAndResetTo(const TestRoute('c'), (r) => r.name == 'a');
      await state.processingCompleted;

      expect(state.root.map((r) => r.name), ['a', 'c']);
    });
  });

  group('RoutesState observers (NavObserver)', () {
    test('receives entered/left page keys on push and pop', () async {
      final observer = _CapturingObserver();
      final state = RoutesState<TestRoute>(
        [const TestRoute('a')],
        (stack) => stack,
        observers: [observer],
      );
      addTearDown(state.dispose);

      state.push(const TestRoute('b'));
      await state.processingCompleted;
      state.pop();
      await state.processingCompleted;

      expect(observer.transitions.length, 2);
      expect(observer.transitions[0].entered, {const ValueKey('b')});
      expect(observer.transitions[0].left, isEmpty);
      expect(observer.transitions[0].next.map((r) => r.name), ['a', 'b']);
      expect(observer.transitions[1].entered, isEmpty);
      expect(observer.transitions[1].left, {const ValueKey('b')});
    });

    test('is not called on a no-op commit', () async {
      final observer = _CapturingObserver();
      final state = RoutesState<TestRoute>(
        [const TestRoute('a')],
        (stack) => stack,
        observers: [observer],
      );
      addTearDown(state.dispose);

      state.setRoot([const TestRoute('a')]);
      await state.processingCompleted;

      expect(observer.transitions, isEmpty);
    });

    test(
      'a faulty observer cannot abort or corrupt queued navigation',
      () async {
        final reportedErrors = <FlutterErrorDetails>[];
        final previousErrorHandler = FlutterError.onError;
        FlutterError.onError = reportedErrors.add;
        addTearDown(() => FlutterError.onError = previousErrorHandler);

        final faultyObserver = _ThrowingOnceObserver();
        final observer = _CapturingObserver();
        final state = RoutesState<TestRoute>(
          [const TestRoute('root')],
          (stack) => stack,
          observers: [faultyObserver, observer],
        );
        addTearDown(state.dispose);

        state.push(const TestRoute('first'));
        state.push(const TestRoute('second'));
        await state.processingCompleted;

        expect(state.root.map((route) => route.name), [
          'root',
          'first',
          'second',
        ]);
        expect(observer.transitions, hasLength(2));
        expect(reportedErrors, hasLength(1));
        expect(reportedErrors.single.exception, isA<StateError>());

        state.push(const TestRoute('third'));
        await state.processingCompleted;

        expect(state.root.map((route) => route.name), [
          'root',
          'first',
          'second',
          'third',
        ]);
        expect(observer.transitions, hasLength(3));
        expect(faultyObserver.calls, 3);
      },
    );

    test('transition collections are read-only', () async {
      final observer = _CapturingObserver();
      final state = RoutesState<TestRoute>(
        [const TestRoute('a')],
        (stack) => stack,
        observers: [observer],
      );
      addTearDown(state.dispose);

      state.push(const TestRoute('b'));
      await state.processingCompleted;

      final transition = observer.transitions.single;
      expect(
        () => transition.entered.add(const ValueKey('injected')),
        throwsUnsupportedError,
      );
      expect(
        () => transition.left.add(const ValueKey('injected')),
        throwsUnsupportedError,
      );
    });
  });

  group('RoutesState invariants', () {
    test('root is an unmodifiable view', () {
      final state = stateWith([const TestRoute('a')]);
      addTearDown(state.dispose);

      expect(
        () => state.root.add(const TestRoute('x')),
        throwsUnsupportedError,
      );
    });

    test('notifies listeners only on a real change', () async {
      final state = stateWith([const TestRoute('a')]);
      addTearDown(state.dispose);
      var notifications = 0;
      state.addListener(() => notifications++);

      // No-op: same stack.
      state.setRoot([const TestRoute('a')]);
      await state.processingCompleted;
      expect(notifications, 0);

      // Real change.
      state.push(const TestRoute('b'));
      await state.processingCompleted;
      expect(notifications, 1);
    });
  });

  group('RoutesState pushForResult / popWith', () {
    test(
      'immediate push and pop completes only after the pop commits',
      () async {
        final state = stateWith([const TestRoute('home')]);
        addTearDown(state.dispose);

        final result = state.pushForResult<int>(const TestRoute('picker'));
        var completed = false;
        unawaited(result.then((_) => completed = true));
        state.popWith<int>(42);

        expect(completed, isFalse);
        await state.processingCompleted;

        expect(await result, 42);
        expect(state.root, const [TestRoute('home')]);
      },
    );

    test('completes with the value passed to popWith', () async {
      final state = stateWith([const TestRoute('home')]);
      addTearDown(state.dispose);

      final result = state.pushForResult<int>(const TestRoute('picker'));
      await state.processingCompleted;
      state.popWith<int>(42);
      await state.processingCompleted;

      expect(await result, 42);
      expect(state.root.map((r) => r.name), ['home']);
    });

    test('completes with null when the route leaves the tree', () async {
      final state = stateWith([const TestRoute('home')]);
      addTearDown(state.dispose);

      final result = state.pushForResult<int>(const TestRoute('picker'));
      await state.processingCompleted;
      // Picker is dropped without popWith.
      state.clearAndPush(const TestRoute('home'));
      await state.processingCompleted;

      expect(await result, isNull);
    });

    test('a guard-reverted popWith leaves the result pending', () async {
      var rejectPop = true;
      late final RoutesState<TestRoute> state;
      state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) {
        if (rejectPop && requested.length == 1) {
          return state.root;
        }
        return requested;
      });
      addTearDown(state.dispose);

      final result = state.pushForResult<int>(const TestRoute('picker'));
      await state.processingCompleted;
      var completed = false;
      unawaited(result.then((_) => completed = true));

      state.popWith<int>(1);
      await state.processingCompleted;
      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      expect(state.top.name, 'picker');

      rejectPop = false;
      state.popWith<int>(2);
      await state.processingCompleted;
      expect(await result, 2);
    });

    test('a live popWith failure leaves a committed result pending', () async {
      var failPop = true;
      final expected = StateError('pop failed');
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) {
        if (failPop && requested.length == 1) {
          throw expected;
        }
        return requested;
      });
      addTearDown(state.dispose);

      final result = state.pushForResult<int>(const TestRoute('picker'));
      await state.processingCompleted;
      var completed = false;
      unawaited(result.then((_) => completed = true));

      state.popWith<int>(1);
      await expectLater(state.processingCompleted, throwsA(same(expected)));
      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      expect(state.top.name, 'picker');

      failPop = false;
      state.popWith<int>(2);
      await state.processingCompleted;
      expect(await result, 2);
    });

    test(
      'an empty final pop keeps the committed result and history intact',
      () async {
        var rejectPopAsEmpty = false;
        late final RoutesState<TestRoute> state;
        final history = NavigationHistory<TestRoute>(
          (stack) => state.setRoot(stack),
        );
        addTearDown(history.dispose);
        state = RoutesState<TestRoute>(
          const <TestRoute>[TestRoute('home')],
          (requested) => rejectPopAsEmpty && requested.length == 2
              ? const <TestRoute>[]
              : requested,
          observers: <NavObserver<TestRoute>>[history],
        );
        addTearDown(state.dispose);
        var historyNotifications = 0;
        history.addListener(() => historyNotifications++);

        state.push(const TestRoute('list'));
        await state.processingCompleted;
        final result = state.pushForResult<int>(const TestRoute('picker'));
        await state.processingCompleted;
        expect(history.canGoBack, isTrue);
        expect(history.canGoForward, isFalse);
        expect(historyNotifications, 2);

        var resultCompleted = false;
        unawaited(result.then((_) => resultCompleted = true));
        rejectPopAsEmpty = true;
        state.popWith<int>(1);

        await expectLater(state.processingCompleted, throwsStateError);
        await Future<void>.delayed(Duration.zero);

        expect(state.root, const <TestRoute>[
          TestRoute('home'),
          TestRoute('list'),
          TestRoute('picker'),
        ]);
        expect(history.canGoBack, isTrue);
        expect(history.canGoForward, isFalse);
        expect(historyNotifications, 2);
        expect(resultCompleted, isFalse);

        rejectPopAsEmpty = false;
        state.popWith<int>(2);
        await state.processingCompleted;

        expect(await result, 2);
        expect(state.root, const <TestRoute>[
          TestRoute('home'),
          TestRoute('list'),
        ]);
        expect(historyNotifications, 3);
      },
    );

    test('a failed speculative result route completes with null', () async {
      final release = Completer<void>();
      final started = Completer<void>();
      final expected = StateError('push failed');
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) async {
        started.complete();
        await release.future;
        throw expected;
      });
      addTearDown(state.dispose);

      final result = state.pushForResult<int>(const TestRoute('picker'));
      final drain = state.processingCompleted;
      await started.future;
      release.complete();

      await expectLater(drain, throwsA(same(expected)));
      expect(await result, isNull);
      expect(state.root, const [TestRoute('home')]);
    });

    test('a fail-fast discarded result route completes with null', () async {
      final release = Completer<void>();
      final started = Completer<void>();
      final expected = StateError('earlier request failed');
      var calls = 0;
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) async {
        calls++;
        started.complete();
        await release.future;
        throw expected;
      });
      addTearDown(state.dispose);

      state.setRoot(const [TestRoute('first')]);
      final result = state.pushForResult<int>(const TestRoute('picker'));
      final drain = state.processingCompleted;
      await started.future;
      release.complete();

      await expectLater(drain, throwsA(same(expected)));
      expect(await result, isNull);
      expect(calls, 1);
      expect(state.root, const [TestRoute('home')]);
    });

    test('result callback observes the root after the committed pop', () async {
      final state = stateWith([const TestRoute('home')]);
      addTearDown(state.dispose);

      final result = state.pushForResult<int>(const TestRoute('picker'));
      await state.processingCompleted;
      List<TestRoute>? callbackRoot;
      unawaited(result.then((_) => callbackRoot = state.root));

      state.popWith<int>(42);
      await state.processingCompleted;
      await result;

      expect(callbackRoot, const [TestRoute('home')]);
    });

    test('dispose completes pending results with null', () async {
      final state = stateWith([const TestRoute('home')]);

      final result = state.pushForResult<int>(const TestRoute('picker'));
      await state.processingCompleted;
      state.dispose();

      expect(await result, isNull);
    });

    test('dispose completes an uncommitted pending result with null', () async {
      final release = Completer<void>();
      final started = Completer<void>();
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) async {
        started.complete();
        await release.future;
        return requested;
      });

      final result = state.pushForResult<int>(const TestRoute('picker'));
      final drain = state.processingCompleted;
      await started.future;
      state.dispose();
      release.complete();

      expect(await result, isNull);
      await drain;
      expect(state.root, const [TestRoute('home')]);
    });

    test(
      'a second pending push on the same pageKey is rejected (debug assert)',
      () async {
        // Equal pageKey (TestRoute keys by name). Pushing a second result route
        // with an already-pending key is a programming error: it asserts in
        // debug (here) and completes the prior awaiter with null in release.
        final state = stateWith([const TestRoute('home')]);
        addTearDown(state.dispose);

        final first = state.pushForResult<int>(const TestRoute('picker'));
        await state.processingCompleted;

        expect(
          () => state.pushForResult<int>(const TestRoute('picker')),
          throwsA(isA<AssertionError>()),
        );

        // Drop the picker; the first (still-registered) awaiter completes with
        // null rather than hanging.
        state.pop();
        await state.processingCompleted;
        expect(await first, isNull);
      },
    );
  });
}
