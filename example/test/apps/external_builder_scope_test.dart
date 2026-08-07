import 'package:example/apps/external_builder_scope/dependency/scoped_catalog_repository.dart';
import 'package:example/apps/external_builder_scope/scope_example_app.dart';
import 'package:example/apps/external_builder_scope/view/scoped_home_screen.dart';
import 'package:example/apps/external_builder_scope/view/scoped_item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('external builder passes the exact narrow scoped dependency', (
    tester,
  ) async {
    const repository = StaticScopedCatalogRepository('same instance');
    await tester.pumpWidget(
      const ExternalBuilderScopeApp(repository: repository),
    );

    final screen = tester.widget<ScopedHomeScreen>(
      find.byType(ScopedHomeScreen),
    );
    expect(screen.repository, same(repository));
    expect(find.text('same instance'), findsOneWidget);
  });

  testWidgets('runs the shared flow with the same repository instance', (
    tester,
  ) async {
    const repository = StaticScopedCatalogRepository('scope repository');
    await tester.pumpWidget(
      const ExternalBuilderScopeApp(repository: repository),
    );

    await tester.tap(find.text('Browse demo items'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item #1'));
    await tester.pumpAndSettle();

    final screen = tester.widget<ScopedItemDetailScreen>(
      find.byType(ScopedItemDetailScreen),
    );
    expect(screen.repository, same(repository));
    expect(find.byKey(const ValueKey('demo-item-detail-1')), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-items-content')), findsOneWidget);
  });

  testWidgets('decodes semantic item deep links and unknown locations', (
    tester,
  ) async {
    const repository = StaticScopedCatalogRepository('deep link');
    final itemProvider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(uri: Uri.parse('/item~id=3')),
    );
    addTearDown(itemProvider.dispose);
    await tester.pumpWidget(
      ExternalBuilderScopeApp(
        repository: repository,
        routeInformationProvider: itemProvider,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-item-detail-3')), findsOneWidget);

    final unknownProvider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(uri: Uri.parse('/unknown')),
    );
    addTearDown(unknownProvider.dispose);
    await tester.pumpWidget(
      ExternalBuilderScopeApp(
        repository: repository,
        routeInformationProvider: unknownProvider,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No scoped route matches this location.'), findsOneWidget);
  });
}
