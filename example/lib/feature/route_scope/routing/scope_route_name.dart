/// Wire names for the Scope feature's routes.
enum ScopeRouteName {
  scope('scope');

  const ScopeRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
