/// A demo module for the full sub-router example (E8): each module owns its OWN
/// `RouteRegistry`, so both `shop` and `blog` define a `detail` route without
/// colliding. (Page keys stay globally unique — prefixed by module — even though
/// the URL *names* are isolated.)
///
/// Holds only the machine identity (`wire`). The human-readable label is a
/// presentation concern — see `DemoModulePresentation` in the view layer.
enum DemoModule {
  shop('shop'),
  blog('blog');

  const DemoModule(this.wire);

  /// URL segment and registry key — a stable machine id, never translated.
  final String wire;

  /// The sibling module (used by the demo's cross-link).
  DemoModule get other => this == shop ? blog : shop;
}
