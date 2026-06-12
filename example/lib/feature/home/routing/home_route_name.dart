/// Wire names for the Home feature's routes.
enum HomeRouteName {
  home('home'),
  detail('detail'),
  animated('animated');

  const HomeRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
