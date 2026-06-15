import 'package:example/feature/modules/routing/modules_routes.dart';
import 'package:example/routing/app_navigator.dart';

/// Modules feature navigation sugar, added to the shared [AppNavigator].
extension ModulesNav on AppNavigator {
  /// Opens [module]'s sub-router (mounted under its own name).
  void toModule(DemoModule module) => push(ModuleShellRoute(module));

  /// Pushes a detail onto [module]'s own nested stack.
  void openModuleItem(DemoModule module, int id) => mutateAt(
    [module.wire],
    (node) =>
        node.withChildren([...node.children, ModuleDetailRoute(module, id)]),
  );
}
