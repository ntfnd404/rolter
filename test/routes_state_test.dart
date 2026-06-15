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

void main() {
  // Identity pipeline — no normalisation, no guards.
  RoutesState<TestRoute> stateWith(List<TestRoute> initial) =>
      RoutesState<TestRoute>(initial, (stack) => stack);

  group('RoutesState mutations', () {
    test('push appends to the stack', () async {
      final state = stateWith([const TestRoute('a')]);
      addTearDown(state.dispose);

      state.push(const TestRoute('b'));
      await state.queue.processingCompleted;

      expect(state.root.map((r) => r.name), ['a', 'b']);
      expect(state.top.name, 'b');
      expect(state.canPop, isTrue);
    });

    test('pop removes the top when more than one remains', () async {
      final state = stateWith([const TestRoute('a'), const TestRoute('b')]);
      addTearDown(state.dispose);

      state.pop();
      await state.queue.processingCompleted;

      expect(state.root.map((r) => r.name), ['a']);
      expect(state.canPop, isFalse);
    });

    test('pop is a no-op at a single entry', () async {
      final state = stateWith([const TestRoute('a')]);
      addTearDown(state.dispose);

      state.pop();
      await state.queue.processingCompleted;

      expect(state.root.map((r) => r.name), ['a']);
    });

    test('replaceTop swaps only the top', () async {
      final state = stateWith([const TestRoute('a'), const TestRoute('b')]);
      addTearDown(state.dispose);

      state.replaceTop(const TestRoute('c'));
      await state.queue.processingCompleted;

      expect(state.root.map((r) => r.name), ['a', 'c']);
    });

    test('clearAndPush resets to a single route', () async {
      final state = stateWith([const TestRoute('a'), const TestRoute('b')]);
      addTearDown(state.dispose);

      state.clearAndPush(const TestRoute('c'));
      await state.queue.processingCompleted;

      expect(state.root.map((r) => r.name), ['c']);
    });

    test('pushOrReplaceTop replaces a same-type top, else pushes', () async {
      final state = stateWith([const TestRoute('a')]);
      addTearDown(state.dispose);

      // Same runtime type as the top -> replaceTop.
      state.pushOrReplaceTop(const TestRoute('b'));
      await state.queue.processingCompleted;

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
      await state.queue.processingCompleted;

      expect(state.root.first.children.map((c) => c.name), ['a', 'b']);
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
      await state.queue.processingCompleted;

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
      await state.queue.processingCompleted;

      expect(state.root.map((r) => r.name), ['keep']);
    });

    test('pushAndResetTo resets to the match then pushes', () async {
      final state = stateWith([const TestRoute('a'), const TestRoute('b')]);
      addTearDown(state.dispose);

      state.pushAndResetTo(const TestRoute('c'), (r) => r.name == 'a');
      await state.queue.processingCompleted;

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
      await state.queue.processingCompleted;
      state.pop();
      await state.queue.processingCompleted;

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
      await state.queue.processingCompleted;

      expect(observer.transitions, isEmpty);
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
      await state.queue.processingCompleted;
      expect(notifications, 0);

      // Real change.
      state.push(const TestRoute('b'));
      await state.queue.processingCompleted;
      expect(notifications, 1);
    });
  });

  group('RoutesState pushForResult / popWith', () {
    test('completes with the value passed to popWith', () async {
      final state = stateWith([const TestRoute('home')]);
      addTearDown(state.dispose);

      final result = state.pushForResult<int>(const TestRoute('picker'));
      await state.queue.processingCompleted;
      state.popWith<int>(42);
      await state.queue.processingCompleted;

      expect(await result, 42);
      expect(state.root.map((r) => r.name), ['home']);
    });

    test('completes with null when the route leaves the tree', () async {
      final state = stateWith([const TestRoute('home')]);
      addTearDown(state.dispose);

      final result = state.pushForResult<int>(const TestRoute('picker'));
      await state.queue.processingCompleted;
      // Picker is dropped without popWith.
      state.clearAndPush(const TestRoute('home'));
      await state.queue.processingCompleted;

      expect(await result, isNull);
    });

    test('dispose completes pending results with null', () async {
      final state = stateWith([const TestRoute('home')]);

      final result = state.pushForResult<int>(const TestRoute('picker'));
      await state.queue.processingCompleted;
      state.dispose();

      expect(await result, isNull);
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
        await state.queue.processingCompleted;

        expect(
          () => state.pushForResult<int>(const TestRoute('picker')),
          throwsA(isA<AssertionError>()),
        );

        // Drop the picker; the first (still-registered) awaiter completes with
        // null rather than hanging.
        state.pop();
        await state.queue.processingCompleted;
        expect(await first, isNull);
      },
    );
  });
}
