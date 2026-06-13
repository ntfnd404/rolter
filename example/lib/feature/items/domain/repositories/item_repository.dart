import 'package:example/feature/items/domain/entities/item.dart';

/// Reads items. The contract lives in `domain/`; the UI depends on this.
abstract interface class ItemRepository {
  /// All items, in order.
  List<Item> all();

  /// The item with [id], or `null` if there is none (or [id] is `null`).
  Item? byId(int? id);
}
