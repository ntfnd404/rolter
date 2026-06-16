/// Wire name for the Items (list) route — the Items tab's nested root.
enum ItemsRouteName {
  items('items');

  const ItemsRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
