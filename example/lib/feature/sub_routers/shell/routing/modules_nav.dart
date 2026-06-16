import 'package:example/feature/sub_routers/shell/routing/demo_module.dart';
import 'package:example/feature/sub_routers/shell/routing/module_shell_route.dart';
import 'package:example/feature/sub_routers/detail/routing/module_detail_route.dart';
import 'package:example/core/routing/app_navigator.dart';

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
