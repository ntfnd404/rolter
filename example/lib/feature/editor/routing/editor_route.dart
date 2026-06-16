import 'package:example/feature/editor/routing/editor_route_name.dart';
import 'package:example/feature/editor/view/editor_screen.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:flutter/material.dart';

/// A screen that blocks leaving while it has unsaved changes — confirm-on-leave
/// demo (the screen owns the veto via `PopScope`).
final class EditorRoute extends AppRoute {
  const EditorRoute();

  @override
  LocalKey get pageKey => const ValueKey('editor');

  @override
  String get name => EditorRouteName.editor.wire;

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) =>
      const MaterialPage(key: ValueKey('editor'), child: EditorScreen());
}
