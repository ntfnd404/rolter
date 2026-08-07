import '../routing/demo_module.dart';

/// Display strings for [DemoModule] — a presentation concern, kept out of the
/// identity enum. Hardcoded for now; swap each `case` for a localized lookup
/// (e.g. `context.l10n.moduleShop`) when the app adds i18n.
extension DemoModulePresentation on DemoModule {
  String get label => switch (this) {
    DemoModule.shop => 'Shop',
    DemoModule.blog => 'Blog',
  };
}
