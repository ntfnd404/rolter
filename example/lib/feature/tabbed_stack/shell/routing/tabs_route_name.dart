/// Wire name for the Tabs shell route.
enum TabsRouteName {
  tabs('tabs');

  const TabsRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
