import 'package:flutter/widgets.dart';

import 'app_destination.dart';
import 'app_navigation_controller.dart';

/// Decodes one destination type from URL parameters.
typedef AppDestinationDecoder<T extends AppDestination> =
    T? Function(Map<String, String> parameters);

/// Builds a Flutter page without depending on a routing engine.
typedef AppDestinationPageFactory<T extends AppDestination> =
    Page<Object?> Function(
      BuildContext context,
      T destination,
      LocalKey pageKey,
      AppNavigationController navigator,
    );

/// Feature-owned decoder and Page-factory contribution.
///
/// This application type is Flutter-specific but router-engine-neutral. It is
/// intentionally not part of Rolter's public API.
final class AppRouteDefinition<T extends AppDestination> {
  /// Creates a typed feature contribution.
  const AppRouteDefinition({
    required this.wireName,
    required this.decode,
    required this.pageFactory,
  });

  /// URL wire segment registered for [T].
  final String wireName;

  /// Pure decoder for external URL parameters.
  final AppDestinationDecoder<T> decode;

  /// Page factory receiving identity and navigation from the host adapter.
  final AppDestinationPageFactory<T> pageFactory;

  /// Exact destination type handled by this definition.
  Type get destinationType => T;

  /// Type-erased decode boundary used only by infrastructure adapters.
  AppDestination? decodeDestination(Map<String, String> parameters) =>
      decode(parameters);

  /// Type-erased Page boundary used only by infrastructure adapters.
  Page<Object?> buildPage(
    BuildContext context,
    AppDestination destination,
    LocalKey pageKey,
    AppNavigationController navigator,
  ) {
    if (destination is! T) {
      throw StateError(
        'A route definition for $T received ${destination.runtimeType}.',
      );
    }

    return pageFactory(context, destination, pageKey, navigator);
  }
}
