/// App-owned item used by the Scope example's domain boundary.
final class ScopedCatalogItem {
  const ScopedCatalogItem({
    required this.id,
    required this.title,
    required this.description,
  });

  final int id;
  final String title;
  final String description;
}

/// Narrow capability consumed by the Scope example's Page composition.
abstract interface class ScopedCatalogRepository {
  String get sourceLabel;

  List<ScopedCatalogItem> all();

  ScopedCatalogItem? byId(int id);
}

/// Immutable in-memory repository used by the runnable Scope example.
final class StaticScopedCatalogRepository implements ScopedCatalogRepository {
  const StaticScopedCatalogRepository(this.sourceLabel);

  @override
  final String sourceLabel;

  static const _items = [
    ScopedCatalogItem(
      id: 1,
      title: 'Item #1',
      description: 'The first demo item.',
    ),
    ScopedCatalogItem(
      id: 2,
      title: 'Item #2',
      description: 'The second demo item.',
    ),
    ScopedCatalogItem(
      id: 3,
      title: 'Item #3',
      description: 'The third demo item.',
    ),
  ];

  @override
  List<ScopedCatalogItem> all() => _items;

  @override
  ScopedCatalogItem? byId(int id) {
    final matches = _items.where((item) => item.id == id);
    return matches.isEmpty ? null : matches.single;
  }
}
