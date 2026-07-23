import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support/test_route.dart';

void main() {
  test('rejects a non-positive history limit in every build mode', () {
    expect(
      () => NavigationHistory<TestRoute>((_) {}, limit: 0),
      throwsArgumentError,
    );
  });

  // Builds a state + history wired together (history records commits and
  // replays them via setRoot).
  (RoutesState<TestRoute>, NavigationHistory<TestRoute>) wired() {
    late RoutesState<TestRoute> state;
    final history = NavigationHistory<TestRoute>(
      (stack) => state.setRoot(stack),
    );
    state = RoutesState<TestRoute>(
      [const TestRoute('a')],
      (stack) => stack,
      observers: [history],
    );

    return (state, history);
  }

  test(
    'records committed stacks and reports back/forward availability',
    () async {
      final (state, history) = wired();
      addTearDown(state.dispose);

      expect(history.canGoBack, isFalse);

      state.push(const TestRoute('b'));
      await state.processingCompleted;
      state.push(const TestRoute('c'));
      await state.processingCompleted;

      // Two commits recorded ([a,b], [a,b,c]); cursor at the newest.
      expect(history.canGoBack, isTrue);
      expect(history.canGoForward, isFalse);
    },
  );

  test('back then forward replays the committed stacks', () async {
    final (state, history) = wired();
    addTearDown(state.dispose);

    state.push(const TestRoute('b'));
    await state.processingCompleted;
    state.push(const TestRoute('c'));
    await state.processingCompleted;

    history.back();
    await state.processingCompleted;
    expect(state.root.map((r) => r.name), ['a', 'b']);
    expect(history.canGoForward, isTrue);

    history.forward();
    await state.processingCompleted;
    expect(state.root.map((r) => r.name), ['a', 'b', 'c']);
    expect(history.canGoForward, isFalse);
  });

  test('a new navigation drops the forward tail', () async {
    final (state, history) = wired();
    addTearDown(state.dispose);

    state.push(const TestRoute('b'));
    await state.processingCompleted;
    state.push(const TestRoute('c'));
    await state.processingCompleted;

    history.back(); // -> [a,b], forward to [a,b,c] available
    await state.processingCompleted;
    expect(history.canGoForward, isTrue);

    state.push(const TestRoute('d')); // new nav from [a,b]
    await state.processingCompleted;

    expect(state.root.map((r) => r.name), ['a', 'b', 'd']);
    expect(history.canGoForward, isFalse, reason: 'forward tail dropped');
  });

  test('a no-op replay does not wedge later recording', () async {
    // Reproduces the sticky-flag bug: a back() whose restore the pipeline turns
    // into a no-op (e.g. a guard redirects it back to the current stack) must
    // not stop the next genuine navigation from being recorded.
    late RoutesState<TestRoute> state;
    final history = NavigationHistory<TestRoute>(
      (stack) => state.setRoot(stack),
    );
    var noopNextCommit = false;
    state = RoutesState<TestRoute>(
      [const TestRoute('a')],
      (stack) {
        if (noopNextCommit) {
          noopNextCommit = false;

          return state.root; // reject: commit no change
        }

        return stack;
      },
      observers: [history],
    );
    addTearDown(state.dispose);

    state.push(const TestRoute('b'));
    await state.processingCompleted;
    state.push(const TestRoute('c'));
    await state.processingCompleted; // root [a,b,c], cursor at newest

    noopNextCommit = true;
    history.back(); // restore [a,b] -> pipeline keeps [a,b,c] (no-op)
    await state.processingCompleted;
    expect(state.root.map((r) => r.name), ['a', 'b', 'c']);

    // The next push must still be recorded (would be dropped by the old flag).
    state.push(const TestRoute('d'));
    await state.processingCompleted;
    expect(state.root.map((r) => r.name), ['a', 'b', 'c', 'd']);
    expect(history.canGoForward, isFalse);
    expect(history.canGoBack, isTrue);
  });

  test('back is a no-op with nothing behind', () async {
    final (state, history) = wired();
    addTearDown(state.dispose);

    state.push(const TestRoute('b'));
    await state.processingCompleted;
    // Only one recorded entry ([a,b]) -> cursor 0 -> cannot go back.
    expect(history.canGoBack, isFalse);
    history.back();
    await state.processingCompleted;
    expect(state.root.map((r) => r.name), ['a', 'b']);
  });
}
