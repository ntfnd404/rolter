import 'package:example/feature/tabbed_stack/shared/data/data_sources/item_local_data_source.dart';
import 'package:example/feature/tabbed_stack/shared/domain/entities/item.dart';

/// In-memory [ItemLocalDataSource] holding a fixed demo data set.
final class ItemLocalDataSourceImpl implements ItemLocalDataSource {
  const ItemLocalDataSourceImpl();

  static const List<Item> _items = [
    Item(id: 1, title: 'Item #1', description: 'The first demo item.'),
    Item(id: 2, title: 'Item #2', description: 'The second demo item.'),
    Item(id: 3, title: 'Item #3', description: 'The third demo item.'),
  ];

  @override
  List<Item> fetchAll() => _items;
}
