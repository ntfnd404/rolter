/// Wire names for the Overlays feature's routes.
enum OverlaysRouteName {
  picker('picker'),
  confirm('confirm');

  const OverlaysRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
