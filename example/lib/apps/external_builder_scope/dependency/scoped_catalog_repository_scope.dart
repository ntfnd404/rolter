import 'package:flutter/widgets.dart';

import 'scoped_catalog_repository.dart';

/// Application-defined narrow inherited dependency boundary.
final class ScopedCatalogRepositoryScope extends InheritedWidget {
  const ScopedCatalogRepositoryScope({
    required this.repository,
    required super.child,
    super.key,
  });

  final ScopedCatalogRepository repository;

  /// Reads the nearest catalog capability and subscribes to replacement.
  static ScopedCatalogRepository of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ScopedCatalogRepositoryScope>();
    if (scope == null) {
      throw StateError('ScopedCatalogRepositoryScope is unavailable.');
    }
    return scope.repository;
  }

  @override
  bool updateShouldNotify(ScopedCatalogRepositoryScope oldWidget) =>
      !identical(repository, oldWidget.repository);
}
