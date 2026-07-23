import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support/test_route.dart';

void main() {
  group('NavigationQueue', () {
    test('processes immutable snapshots in FIFO order', () async {
      final releaseFirst = Completer<void>();
      final processed = <String>[];
      var calls = 0;
      final queue = NavigationQueue<TestRoute>((snapshot) async {
        calls += 1;
        if (calls == 1) {
          await releaseFirst.future;
        }
        processed.add(snapshot.single.name);
        expect(
          () => snapshot.add(const TestRoute('mutation')),
          throwsUnsupportedError,
        );
      });
      final first = <TestRoute>[const TestRoute('first')];

      queue.add(first);
      queue.add(const [TestRoute('second')]);
      first[0] = const TestRoute('changed-after-add');

      expect(queue.isProcessing, isTrue);
      releaseFirst.complete();
      await queue.processingCompleted;

      expect(processed, ['first', 'second']);
      expect(queue.isProcessing, isFalse);
    });

    test('fails fast, discards dependent work, and permits recovery', () async {
      final processed = <String>[];
      final queue = NavigationQueue<TestRoute>((snapshot) async {
        final name = snapshot.single.name;
        processed.add(name);
        if (name == 'fails') {
          throw StateError('processor failed');
        }
      });

      queue.add(const [TestRoute('fails')]);
      queue.add(const [TestRoute('must-be-discarded')]);

      await expectLater(queue.processingCompleted, throwsStateError);
      expect(processed, ['fails']);
      expect(queue.isProcessing, isFalse);

      queue.add(const [TestRoute('recovery')]);
      await queue.processingCompleted;
      expect(processed, ['fails', 'recovery']);
    });
  });
}
