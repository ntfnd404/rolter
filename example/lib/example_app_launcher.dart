import 'package:flutter/widgets.dart';

import 'apps/centralized_route_owned/centralized_app.dart';
import 'apps/external_builder_scope/scope_example_app.dart';
import 'apps/feature_first/feature_first_app.dart';
import 'apps/router_neutral_adapter/adapter_example_app.dart';

/// Compile-time key used to select one of the runnable example applications.
const String exampleAppEnvironmentKey = 'ROLTER_EXAMPLE_APP';

/// Example selected by `--dart-define` or `--dart-define-from-file`.
const String configuredExampleApp = String.fromEnvironment(
  exampleAppEnvironmentKey,
  defaultValue: 'feature_first',
);

/// A runnable reference architecture included in the example package.
enum ExampleAppKind {
  /// Modular, feature-owned routing with constructor injection.
  featureFirst('feature_first'),

  /// One centralized catalog whose routes own their Pages.
  centralizedRouteOwned('centralized_route_owned'),

  /// Data-only routes composed through a narrow inherited Scope.
  externalBuilderScope('external_builder_scope'),

  /// A bounded router-neutral application layer adapted to Rolter.
  routerNeutralAdapter('router_neutral_adapter');

  const ExampleAppKind(this.environmentValue);

  /// Exact value accepted by [parse] and the corresponding env preset.
  final String environmentValue;

  /// Parses an exact compile-time environment value.
  static ExampleAppKind parse(String value) {
    for (final kind in values) {
      if (kind.environmentValue == value) {
        return kind;
      }
    }
    throw ArgumentError.value(
      value,
      exampleAppEnvironmentKey,
      'Expected one of: ${values.map((kind) => kind.environmentValue).join(', ')}',
    );
  }
}

/// Creates the reference application selected by [kind].
///
/// This launcher is developer tooling, not a fifth routing architecture. Each
/// returned application retains its own independent import graph and dedicated
/// `main.dart` entrypoint.
Widget createExampleApp(ExampleAppKind kind) => switch (kind) {
  ExampleAppKind.featureFirst => createFeatureFirstExampleApp(),
  ExampleAppKind.centralizedRouteOwned =>
    createCentralizedRouteOwnedExampleApp(),
  ExampleAppKind.externalBuilderScope => createExternalBuilderScopeExampleApp(),
  ExampleAppKind.routerNeutralAdapter => createRouterNeutralAdapterExampleApp(),
};

/// Creates the application selected by the compile-time environment value.
Widget createConfiguredExampleApp({String appName = configuredExampleApp}) =>
    createExampleApp(ExampleAppKind.parse(appName));
