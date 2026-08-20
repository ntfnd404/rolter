import 'package:example/apps/feature_first/feature_first_app.dart';
import 'package:example/apps/feature_first/feature/home/routing/home_route.dart';
import 'package:example/apps/feature_first/navigation/app_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

void main() {
  testWidgets('renders the complete feature-first enterprise showcase', (
    tester,
  ) async {
    await tester.pumpWidget(const FeatureFirstExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('rolter example'), findsOneWidget);
    expect(find.text('Mailbox (master-detail)'), findsOneWidget);
    expect(find.text('Multi-tab independent stacks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reuses the existing nested Items flow as the comparison flow', (
    tester,
  ) async {
    await tester.pumpWidget(const FeatureFirstExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Browse demo items'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-items-content')), findsOneWidget);

    await tester.tap(find.text('Item #1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-item-detail-1')), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-items-content')), findsOneWidget);
  });

  testWidgets(
    'guard refresh restores the protected route and unmounts cleanly',
    (tester) async {
      await tester.pumpWidget(const FeatureFirstExampleApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Lock session'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lock session'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Tabs + nested stack (guarded)'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Tabs + nested stack (guarded)'));
      await tester.pumpAndSettle();

      expect(find.text('Session is locked'), findsOneWidget);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(find.text('Session is locked'), findsNothing);
      expect(find.text('Items'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  test('detached refresh cannot reach disposed route state', () {
    final refresh = ChangeNotifier();
    final state = RoutesState<AppRoute>(const [HomeRoute()], (requested) {
      return requested;
    });
    final VoidCallback reevaluateRoutes = state.reevaluate;

    refresh.addListener(reevaluateRoutes);
    refresh.removeListener(reevaluateRoutes);
    state.dispose();

    expect(refresh.notifyListeners, returnsNormally);
    refresh.dispose();
  });
}
