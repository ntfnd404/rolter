/// Wire names for the Detail feature's routes.
enum DetailRouteName {
  detail('detail');

  const DetailRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
