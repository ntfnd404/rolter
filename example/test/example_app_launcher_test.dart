import 'dart:io';

import 'package:example/apps/centralized_route_owned/centralized_app.dart';
import 'package:example/apps/external_builder_scope/dependency/scoped_catalog_repository.dart';
import 'package:example/apps/external_builder_scope/scope_example_app.dart';
import 'package:example/apps/feature_first/feature_first_app.dart';
import 'package:example/apps/router_neutral_adapter/adapter_example_app.dart';
import 'package:example/apps/router_neutral_adapter/feature/activity/activity_repository.dart';
import 'package:example/apps/router_neutral_adapter/feature/catalog/catalog_repository.dart';
import 'package:example/example_app_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedKinds = <String, Type>{
    'feature_first': FeatureFirstExampleApp,
    'centralized_route_owned': CentralizedRouteOwnedApp,
    'external_builder_scope': ExternalBuilderScopeApp,
    'router_neutral_adapter': AdapterExampleApp,
  };

  test('each exact environment value selects its reference application', () {
    for (final entry in expectedKinds.entries) {
      final app = createConfiguredExampleApp(appName: entry.key);
      expect(app.runtimeType, entry.value, reason: entry.key);
    }
  });

  test('the compile-time default remains feature-first', () {
    expect(configuredExampleApp, ExampleAppKind.featureFirst.environmentValue);
    expect(createConfiguredExampleApp(), isA<FeatureFirstExampleApp>());
  });

  test('an unknown environment value fails with a useful argument error', () {
    expect(
      () => createConfiguredExampleApp(appName: 'unknown'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.name,
          'environment key',
          exampleAppEnvironmentKey,
        ),
      ),
    );
  });

  test('tracked presets contain only the supported compile-time selection', () {
    for (final value in expectedKinds.keys) {
      final file = File('env/$value.env');
      expect(file.existsSync(), isTrue, reason: file.path);
      expect(file.readAsLinesSync(), <String>[
        '$exampleAppEnvironmentKey=$value',
      ], reason: file.path);
    }
  });

  test('factories retain explicit narrow demo dependency wiring', () {
    final scopeApp = createExternalBuilderScopeExampleApp();
    expect(scopeApp.repository, isA<StaticScopedCatalogRepository>());
    expect(
      scopeApp.repository.sourceLabel,
      'Dependency from ScopedCatalogRepositoryScope.of',
    );

    final adapterApp = createRouterNeutralAdapterExampleApp();
    expect(adapterApp.activityRepository, isA<StaticActivityRepository>());
    expect(adapterApp.catalogRepository, isA<StaticAdapterCatalogRepository>());
  });
}
