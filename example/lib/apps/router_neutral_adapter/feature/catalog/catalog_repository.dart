/// Catalog-owned domain entity for the router-neutral example.
final class AdapterCatalogItem {
  const AdapterCatalogItem({
    required this.id,
    required this.title,
    required this.description,
  });

  final int id;
  final String title;
  final String description;
}

/// Narrow feature dependency captured by Catalog route definitions.
abstract interface class AdapterCatalogRepository {
  List<AdapterCatalogItem> all();

  AdapterCatalogItem? byId(int id);
}

/// Immutable catalog used by the runnable adapter application.
final class StaticAdapterCatalogRepository implements AdapterCatalogRepository {
  const StaticAdapterCatalogRepository();

  static const _items = [
    AdapterCatalogItem(
      id: 1,
      title: 'Item #1',
      description: 'The first demo item.',
    ),
    AdapterCatalogItem(
      id: 2,
      title: 'Item #2',
      description: 'The second demo item.',
    ),
    AdapterCatalogItem(
      id: 3,
      title: 'Item #3',
      description: 'The third demo item.',
    ),
  ];

  @override
  List<AdapterCatalogItem> all() => _items;

  @override
  AdapterCatalogItem? byId(int id) {
    final matches = _items.where((item) => item.id == id);
    return matches.isEmpty ? null : matches.single;
  }
}
