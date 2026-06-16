/// Which tab of the multi-tab shell. Shared by the shell (`common`) and the
/// `list`/`detail` sub-features.
///
/// Holds only the machine identity (`wire`). Label and icon are presentation
/// concerns — see `MtTabPresentation` in the view layer.
enum MtTab {
  a('mt-a'),
  b('mt-b');

  const MtTab(this.wire);

  /// URL segment — a stable machine id, never translated.
  final String wire;

  static MtTab fromWire(String? wire) =>
      values.firstWhere((t) => t.wire == wire, orElse: () => MtTab.a);
}
