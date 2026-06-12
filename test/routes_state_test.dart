import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support/test_route.dart';

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
  });
}
