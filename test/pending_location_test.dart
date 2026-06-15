import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support/test_route.dart';

void main() {
  group('PendingLocation', () {
    test('starts empty', () {
      final pending = PendingLocation<TestRoute>();
      expect(pending.hasPending, isFalse);
      expect(pending.peek, isNull);
      expect(pending.take(), isNull);
    });

    test('remember -> peek (non-destructive) -> take (clears)', () {
      final pending = PendingLocation<TestRoute>()
        ..remember([const TestRoute('a'), const TestRoute('b')]);

      expect(pending.hasPending, isTrue);
      expect(pending.peek!.map((r) => r.name), ['a', 'b']);
      expect(pending.hasPending, isTrue, reason: 'peek must not clear');

      expect(pending.take()!.map((r) => r.name), ['a', 'b']);
      expect(pending.hasPending, isFalse, reason: 'take must clear');
      expect(pending.take(), isNull);
    });

    test('remember copies defensively', () {
      final pending = PendingLocation<TestRoute>();
      final source = [const TestRoute('a')];
      pending.remember(source);
      source.add(const TestRoute('b'));

      expect(pending.peek!.map((r) => r.name), ['a']);
    });

    test('clear forgets the target', () {
      final pending = PendingLocation<TestRoute>()
        ..remember([const TestRoute('a')]);
      pending.clear();

      expect(pending.hasPending, isFalse);
    });
  });
}
