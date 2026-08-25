import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/src/controller/routing_config/framework_transaction.dart';

FrameworkTransaction _transaction([int generation = 1]) =>
    FrameworkTransaction(Uri(path: '/request-$generation'), generation);

void main() {
  group('FrameworkTransaction', () {
    test('seals before successful settlement', () {
      final transaction = _transaction();

      expect(transaction.phase, FrameworkTransactionPhase.pending);
      expect(transaction.isPending, isTrue);
      expect(transaction.seal(), isTrue);
      expect(transaction.phase, FrameworkTransactionPhase.sealedPending);
      expect(transaction.supersede(), isFalse);
      expect(transaction.settleSuccess(), isTrue);
      expect(transaction.phase, FrameworkTransactionPhase.settledSuccess);
      expect(transaction.isPending, isFalse);
    });

    test('settles directly from pending', () {
      final transaction = _transaction();

      expect(transaction.settleSuccess(), isTrue);
      expect(transaction.phase, FrameworkTransactionPhase.settledSuccess);
    });

    test('fails from pending or sealed pending', () {
      final pending = _transaction();
      final sealed = _transaction(2)..seal();

      expect(pending.fail(), isTrue);
      expect(pending.phase, FrameworkTransactionPhase.failed);
      expect(sealed.fail(), isTrue);
      expect(sealed.phase, FrameworkTransactionPhase.failed);
    });

    test('supersedes only an unsealed pending request', () {
      final transaction = _transaction();

      expect(transaction.supersede(), isTrue);
      expect(transaction.phase, FrameworkTransactionPhase.superseded);
      expect(transaction.seal(), isFalse);
      expect(transaction.settleSuccess(), isFalse);
      expect(transaction.fail(), isFalse);
      expect(transaction.abandon(), isFalse);
    });

    test('abandons pending or sealed pending', () {
      final pending = _transaction();
      final sealed = _transaction(2)..seal();

      expect(pending.abandon(), isTrue);
      expect(pending.phase, FrameworkTransactionPhase.abandoned);
      expect(sealed.abandon(), isTrue);
      expect(sealed.phase, FrameworkTransactionPhase.abandoned);
    });

    test('terminal phases reject every later transition', () {
      for (final transaction in <FrameworkTransaction>[
        _transaction()..settleSuccess(),
        _transaction(2)..fail(),
        _transaction(3)..supersede(),
        _transaction(4)..abandon(),
      ]) {
        final terminal = transaction.phase;

        expect(transaction.seal(), isFalse);
        expect(transaction.settleSuccess(), isFalse);
        expect(transaction.fail(), isFalse);
        expect(transaction.supersede(), isFalse);
        expect(transaction.abandon(), isFalse);
        expect(transaction.phase, terminal);
      }
    });

    test('equivalent requests retain distinct identity', () {
      final first = FrameworkTransaction(Uri(path: '/same'), 1);
      final second = FrameworkTransaction(Uri(path: '/same'), 2);

      expect(first, isNot(same(second)));
      expect(first.originUri, second.originUri);
      expect(first.platformGeneration, isNot(second.platformGeneration));
    });
  });
}
