import 'package:example/feature/tabbed_stack/shared/data/data_sources/item_local_data_source.dart';
import 'package:example/feature/tabbed_stack/shared/domain/entities/item.dart';
import 'package:example/feature/tabbed_stack/shared/domain/repositories/item_repository.dart';

/// [ItemRepository] over an [ItemLocalDataSource], adding id-lookup on top of
/// the raw source. The source is **injected** by the composition root.
final class ItemRepositoryImpl implements ItemRepository {
  const ItemRepositoryImpl(this._source);

  final ItemLocalDataSource _source;

  @override
  List<Item> all() => _source.fetchAll();

  @override
  Item? byId(int? id) {
    if (id == null) {
      return null;
    }
    for (final item in _source.fetchAll()) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }
}
