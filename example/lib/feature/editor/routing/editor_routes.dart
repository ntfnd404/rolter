import 'editor_route.dart';
import 'editor_route_name.dart';
import '../../../core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Editor feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get editorRoutes => {
      EditorRouteName.editor.wire: (_, unusedChildren) => const EditorRoute(),
    };
