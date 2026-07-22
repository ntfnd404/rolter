import '../../domain/entities/item.dart';

/// Local source of items — a stand-in for an API or database.
abstract interface class ItemLocalDataSource {
  /// All items, in order.
  List<Item> fetchAll();
}
