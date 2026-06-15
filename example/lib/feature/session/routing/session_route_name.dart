/// Wire names for the Session feature's routes.
enum SessionRouteName {
  lock('lock');

  const SessionRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
