import '../view/module_shell.dart';
import '../../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/module_shell_route.dart';

/// Page contribution for a module shell and its nested navigator.
final AppRoutePageDefinition moduleShellPageDefinition =
    TypedAppRoutePageDefinition<ModuleShellRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: ModuleShell(
          module: route.module,
          pageBuilder: nestedPageBuilder,
        ),
      ),
    );
