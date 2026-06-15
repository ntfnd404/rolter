/// Wire names for the Items/Tabs feature's routes.
enum ItemsRouteName {
  tabs('tabs'),
  items('items'),
  item('item');

  const ItemsRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
