/// Wire names for the Editor feature's routes.
enum EditorRouteName {
  editor('editor');

  const EditorRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
