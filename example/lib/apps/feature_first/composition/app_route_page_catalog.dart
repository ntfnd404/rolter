import 'package:flutter/widgets.dart';
import 'package:rolter/rolter.dart';

import '../navigation/app_route.dart';

/// Builds one typed application route page.
///
/// [nestedPageBuilder] is the complete catalog strategy. A shell definition
/// passes it to every `NestedNavigatorHost` that renders the route's children.
typedef AppRoutePageFactory<R extends AppRoute> =
    Page<Object?> Function(
      BuildContext context,
      R route,
      RouteNodePageBuilder<AppRoute> nestedPageBuilder,
    );

/// Type-erased page contribution owned by one application feature.
abstract interface class AppRoutePageDefinition {
  /// Concrete route type handled by this definition.
  Type get routeType;

  /// Builds [route] with access to the complete nested composition strategy.
  Page<Object?> build(
    BuildContext context,
    AppRoute route,
    RouteNodePageBuilder<AppRoute> nestedPageBuilder,
  );
}

/// Adapts a typed feature page factory to [AppRoutePageDefinition].
final class TypedAppRoutePageDefinition<R extends AppRoute>
    implements AppRoutePageDefinition {
  /// Creates a contribution backed by [pageFactory].
  const TypedAppRoutePageDefinition({required this.pageFactory});

  /// Typed factory implemented by the owning feature.
  final AppRoutePageFactory<R> pageFactory;

  @override
  Type get routeType => R;

  @override
  Page<Object?> build(
    BuildContext context,
    AppRoute route,
    RouteNodePageBuilder<AppRoute> nestedPageBuilder,
  ) {
    if (route is! R) {
      throw StateError(
        'A page definition for $R received ${route.runtimeType}.',
      );
    }

    return pageFactory(context, route, nestedPageBuilder);
  }
}

/// Composes feature-owned page definitions into one application builder.
///
/// Dispatch is by concrete route type, never by URL wire name, so mounted
/// feature namespaces may reuse names such as `detail` safely.
final class AppRoutePageCatalog {
  /// Creates an immutable catalog and rejects duplicate route-type handlers.
  AppRoutePageCatalog(Iterable<AppRoutePageDefinition> definitions)
    : _definitions = _index(definitions);

  final Map<Type, AppRoutePageDefinition> _definitions;

  /// Builds a page for [route] and supplies this complete catalog recursively.
  Page<Object?> build(BuildContext context, AppRoute route) {
    final definition = _definitions[route.runtimeType];
    if (definition == null) {
      throw StateError(
        'No page definition is registered for ${route.runtimeType}.',
      );
    }

    return definition.build(context, route, build);
  }

  static Map<Type, AppRoutePageDefinition> _index(
    Iterable<AppRoutePageDefinition> definitions,
  ) {
    final indexed = <Type, AppRoutePageDefinition>{};
    for (final definition in definitions) {
      if (indexed.containsKey(definition.routeType)) {
        throw StateError(
          'More than one page definition is registered for '
          '${definition.routeType}.',
        );
      }
      indexed[definition.routeType] = definition;
    }

    return Map<Type, AppRoutePageDefinition>.unmodifiable(indexed);
  }
}
