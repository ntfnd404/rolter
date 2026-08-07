import 'package:example/apps/centralized_route_owned/centralized_app.dart';
import 'package:example/apps/centralized_route_owned/centralized_route_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invalid Detail keeps a distinct safe route and key', () {
    final home = const CentralizedHomeRoute();
    for (final parameters in <Map<String, String>>[
      const {},
      const {'id': 'invalid'},
      const {'id': '0'},
      const {'id': '-1'},
    ]) {
      final route = decodeCentralizedDetail(parameters, const []);
      expect(route, isA<CentralizedInvalidDetailRoute>());
      expect(route.name, 'detail');
      expect(route.pageKey, isNot(home.pageKey));
    }
  });

  testWidgets('preserves the original standalone Detail scenario', (
    tester,
  ) async {
    await tester.pumpWidget(const CentralizedRouteOwnedApp());

    await tester.tap(find.text('Original standalone detail'));
    await tester.pumpAndSettle();

    expect(find.text('Detail #42'), findsOneWidget);
    expect(find.text('Route-owned Page composition'), findsOneWidget);
  });

  testWidgets('runs the shared Home to Items to Item flow', (tester) async {
    await tester.pumpWidget(const CentralizedRouteOwnedApp());

    await tester.tap(find.text('Browse demo items'));
    await tester.pumpAndSettle();
    expect(find.text('The first demo item.'), findsOneWidget);

    await tester.tap(find.text('Item #1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-item-detail-1')), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-items-content')), findsOneWidget);
  });

  testWidgets('decodes item deep links and unknown locations safely', (
    tester,
  ) async {
    final itemProvider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(uri: Uri.parse('/item~id=2')),
    );
    addTearDown(itemProvider.dispose);
    await tester.pumpWidget(
      CentralizedRouteOwnedApp(routeInformationProvider: itemProvider),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-item-detail-2')), findsOneWidget);

    final unknownProvider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(uri: Uri.parse('/unknown')),
    );
    addTearDown(unknownProvider.dispose);
    await tester.pumpWidget(
      CentralizedRouteOwnedApp(routeInformationProvider: unknownProvider),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No centralized route matches this location.'),
      findsOneWidget,
    );
  });
}
