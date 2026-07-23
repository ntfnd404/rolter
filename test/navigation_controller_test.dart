import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support/test_route.dart';

void main() {
  test('NavigationController forwards root-stack navigation', () async {
    final state = RoutesState<TestRoute>(
      const [TestRoute('a')],
      (requested) => requested,
    );
    addTearDown(state.dispose);
    final controller = NavigationController<TestRoute>(state);

    expect(controller.rootStack.map((route) => route.name), ['a']);
    expect(controller.canPop, isFalse);

    controller.push(const TestRoute('b'));
    await state.processingCompleted;
    expect(controller.rootStack.map((route) => route.name), ['a', 'b']);
    expect(controller.canPop, isTrue);

    controller.replaceTop(const TestRoute('c'));
    await state.processingCompleted;
    expect(controller.rootStack.map((route) => route.name), ['a', 'c']);

    controller.clearAndPush(const TestRoute('d'));
    await state.processingCompleted;
    expect(controller.rootStack.map((route) => route.name), ['d']);
  });
}
