import '../../shell/routing/demo_module.dart';
import '../view/module_detail_screen.dart';
import '../../../../core/routing/app_route.dart';
import 'package:flutter/material.dart';

/// A module's detail (route name `detail`, local to the module's registry — both
/// modules reuse the name without colliding).
final class ModuleDetailRoute extends AppRoute {
  const ModuleDetailRoute(this.module, this.id);

  final DemoModule module;
  final int id;

  @override
  LocalKey get pageKey => ValueKey('${module.wire}/detail:$id');

  @override
  String get name => 'detail';

  @override
  Map<String, String> toParams() => {'id': '$id'};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
        key: pageKey,
        child: ModuleDetailScreen(module: module, id: id),
      );
}
