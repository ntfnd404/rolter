import 'package:example/feature/editor/routing/editor_route.dart';
import 'package:example/feature/editor/routing/editor_route_name.dart';
import 'package:example/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Editor feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get editorRoutes => {
  EditorRouteName.editor.wire: (_, _) => const EditorRoute(),
};
