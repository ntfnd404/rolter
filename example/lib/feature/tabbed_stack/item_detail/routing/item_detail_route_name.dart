/// Wire name for the item-detail route, pushed inside the Items tab.
enum ItemDetailRouteName {
  item('item');

  const ItemDetailRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
