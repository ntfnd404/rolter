/// Wire names for the Confirm (dialog-as-route) feature's routes.
enum ConfirmRouteName {
  confirm('confirm');

  const ConfirmRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
