import 'dart:io';

import 'package:example/apps/router_neutral_adapter/adapter_example_app.dart';
import 'package:example/apps/router_neutral_adapter/application/app_destination.dart';
import 'package:example/apps/router_neutral_adapter/application/app_route_definition.dart';
import 'package:example/apps/router_neutral_adapter/application/not_found_destination.dart';
import 'package:example/apps/router_neutral_adapter/feature/activity/activity_definition.dart';
import 'package:example/apps/router_neutral_adapter/feature/activity/activity_destination.dart';
import 'package:example/apps/router_neutral_adapter/feature/activity/activity_repository.dart';
import 'package:example/apps/router_neutral_adapter/feature/activity/activity_screen.dart';
import 'package:example/apps/router_neutral_adapter/feature/catalog/catalog_definitions.dart';
import 'package:example/apps/router_neutral_adapter/feature/catalog/catalog_repository.dart';
import 'package:example/apps/router_neutral_adapter/feature/catalog/item_detail_destination.dart';
import 'package:example/apps/router_neutral_adapter/feature/catalog/item_detail_screen.dart';
import 'package:example/apps/router_neutral_adapter/feature/catalog/items_destination.dart';
import 'package:example/apps/router_neutral_adapter/feature/home/home_definition.dart';
import 'package:example/apps/router_neutral_adapter/feature/home/home_destination.dart';
import 'package:example/apps/router_neutral_adapter/infrastructure/rolter_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Repository implements ActivityRepository {
  const _Repository(this.prefix);

  final String prefix;

  @override
  String labelFor(int sequence) => '$prefix $sequence';
}

final class _CatalogRepository implements AdapterCatalogRepository {
  const _CatalogRepository();

  static const item = AdapterCatalogItem(
    id: 1,
    title: 'Item #1',
    description: 'same catalog repository',
  );

  @override
  List<AdapterCatalogItem> all() => const [item];

  @override
  AdapterCatalogItem? byId(int id) => id == item.id ? item : null;
}

final class _UnregisteredDestination implements AppDestination {
  const _UnregisteredDestination();

  @override
  String get pageIdentity => 'private-value';

  @override
  String get wireName => 'private-wire';

  @override
  Map<String, String> toParams() => const {};
}

AppRouteDefinition<NotFoundDestination> _notFoundDefinition({
  String wireName = 'not-found',
}) => AppRouteDefinition<NotFoundDestination>(
  wireName: wireName,
  decode: (parameters) =>
      parameters.isEmpty ? const NotFoundDestination() : null,
  pageFactory: (context, destination, pageKey, navigator) =>
      MaterialPage<Object?>(key: pageKey, child: const Text('not found')),
);

RolterAdapter _buildAdapter({
  Iterable<AppRouteDefinition<AppDestination>>? definitions,
}) => RolterAdapter(
  definitions:
      definitions ??
      <AppRouteDefinition<AppDestination>>[
        buildHomeDefinition(
          activityDestination: () => const ActivityDestination(sequence: 42),
          itemsDestination: ItemsDestination.new,
        ),
        buildActivityDefinition(repository: const _Repository('activity')),
        _notFoundDefinition(),
      ],
  initialDestination: const HomeDestination(),
  invalidDestination: NotFoundDestination.new,
  unknownDestination: (_) => const NotFoundDestination(),
);

void main() {
  test('destinations use value equality and identity-bearing parameters', () {
    expect(const HomeDestination(), const HomeDestination());
    expect(const NotFoundDestination(), const NotFoundDestination());
    expect(
      const ActivityDestination(sequence: 7),
      const ActivityDestination(sequence: 7),
    );
    expect(
      const ActivityDestination(sequence: 7),
      isNot(const ActivityDestination(sequence: 8)),
    );
    expect(const ActivityDestination(sequence: 7).pageIdentity, 'activity:7');
    expect(const ItemsDestination(), const ItemsDestination());
    expect(
      const ItemDetailDestination(id: 7),
      const ItemDetailDestination(id: 7),
    );
    expect(const ItemDetailDestination(id: 7).pageIdentity, 'item:7');
  });

  test('activity decoder accepts only one positive sequence', () {
    final definition = buildActivityDefinition(
      repository: const _Repository('activity'),
    );

    expect(
      definition.decode(const {'sequence': '7'}),
      const ActivityDestination(sequence: 7),
    );
    expect(definition.decode(const {}), isNull);
    expect(definition.decode(const {'sequence': 'invalid'}), isNull);
    expect(definition.decode(const {'sequence': '0'}), isNull);
    expect(
      definition.decode(const {'sequence': '7', 'extra': 'value'}),
      isNull,
    );
  });

  test(
    'adapter rejects duplicate destination types using type-only errors',
    () {
      expect(
        () => _buildAdapter(
          definitions: <AppRouteDefinition<AppDestination>>[
            buildHomeDefinition(
              activityDestination: () => const ActivityDestination(sequence: 1),
              itemsDestination: ItemsDestination.new,
            ),
            buildHomeDefinition(
              activityDestination: () => const ActivityDestination(sequence: 2),
              itemsDestination: ItemsDestination.new,
            ),
          ],
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(contains('$HomeDestination'), isNot(contains('home'))),
          ),
        ),
      );
    },
  );

  test('adapter rejects duplicate wire registration without wire values', () {
    expect(
      () => _buildAdapter(
        definitions: <AppRouteDefinition<AppDestination>>[
          buildHomeDefinition(
            activityDestination: () => const ActivityDestination(sequence: 1),
            itemsDestination: ItemsDestination.new,
          ),
          _notFoundDefinition(wireName: 'home'),
        ],
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(contains('wire name'), isNot(contains('home'))),
        ),
      ),
    );
  });

  test('push rejects an unregistered type without destination values', () {
    final adapter = _buildAdapter();
    addTearDown(adapter.dispose);

    expect(
      () => adapter.push(const _UnregisteredDestination()),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('$_UnregisteredDestination'),
            isNot(contains('private-value')),
            isNot(contains('private-wire')),
          ),
        ),
      ),
    );
  });

  testWidgets(
    'push/pop uses exact-type dispatch, generated key, and narrow dependency',
    (tester) async {
      const repository = _Repository('same repository');
      await tester.pumpWidget(
        const AdapterExampleApp(
          activityRepository: repository,
          catalogRepository: StaticAdapterCatalogRepository(),
        ),
      );

      await tester.tap(find.text('Open adapter activity'));
      await tester.pumpAndSettle();

      final screen = tester.widget<AdapterActivityScreen>(
        find.byType(AdapterActivityScreen),
      );
      expect(screen.sequence, 42);
      expect(screen.repository, same(repository));
      expect(find.text('same repository 42'), findsOneWidget);

      final context = tester.element(find.byType(AdapterActivityScreen));
      final settings = ModalRoute.of(context)!.settings as Page<Object?>;
      expect(
        settings.key,
        ValueKey<Object>((ActivityDestination, 'activity:42')),
      );

      screen.navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('Router-neutral modules'), findsOneWidget);
    },
  );

  testWidgets('activity deep link decodes through the adapter', (tester) async {
    const repository = _Repository('deep link');
    final provider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(
        uri: Uri.parse('/activity~sequence=9'),
      ),
    );
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      AdapterExampleApp(
        activityRepository: repository,
        catalogRepository: const StaticAdapterCatalogRepository(),
        routeInformationProvider: provider,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activity #9'), findsOneWidget);
    expect(find.text('deep link 9'), findsOneWidget);
  });

  testWidgets('shared Items flow keeps adapter repository identity', (
    tester,
  ) async {
    const catalog = _CatalogRepository();
    await tester.pumpWidget(
      const AdapterExampleApp(
        activityRepository: _Repository('activity'),
        catalogRepository: catalog,
      ),
    );

    await tester.tap(find.text('Browse demo items'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item #1'));
    await tester.pumpAndSettle();

    final screen = tester.widget<AdapterItemDetailScreen>(
      find.byType(AdapterItemDetailScreen),
    );
    expect(screen.repository, same(catalog));
    expect(find.text('same catalog repository'), findsOneWidget);

    final context = tester.element(find.byType(AdapterItemDetailScreen));
    final settings = ModalRoute.of(context)!.settings as Page<Object?>;
    expect(settings.key, ValueKey<Object>((ItemDetailDestination, 'item:1')));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('same catalog repository'), findsOneWidget);
  });

  test('item decoder accepts one positive id and rejects invalid input', () {
    final definition = buildItemDetailDefinition(
      repository: const _CatalogRepository(),
      homeDestination: HomeDestination.new,
    );

    expect(
      definition.decode(const {'id': '1'}),
      const ItemDetailDestination(id: 1),
    );
    expect(definition.decode(const {}), isNull);
    expect(definition.decode(const {'id': '0'}), isNull);
    expect(definition.decode(const {'id': 'invalid'}), isNull);
    expect(definition.decode(const {'id': '1', 'extra': 'value'}), isNull);
  });

  testWidgets('unknown and invalid URLs use the registered fallback', (
    tester,
  ) async {
    for (final uri in <Uri>[
      Uri.parse('/unknown'),
      Uri.parse('/activity~sequence=invalid'),
    ]) {
      final provider = PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(uri: uri),
      );
      await tester.pumpWidget(
        AdapterExampleApp(
          activityRepository: const _Repository('unused'),
          catalogRepository: const StaticAdapterCatalogRepository(),
          routeInformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Adapter route not found'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    }
  });

  test('only adapter infrastructure imports Rolter', () {
    final root = Directory('lib/apps/router_neutral_adapter');
    final offenders = <String>[];
    for (final file
        in root
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      if (file.readAsStringSync().contains("package:rolter/rolter.dart") &&
          !file.path.endsWith('infrastructure/rolter_adapter.dart')) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty);
  });

  testWidgets('adapter-owned objects dispose with the application', (
    tester,
  ) async {
    await tester.pumpWidget(
      const AdapterExampleApp(
        activityRepository: _Repository('dispose'),
        catalogRepository: StaticAdapterCatalogRepository(),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
