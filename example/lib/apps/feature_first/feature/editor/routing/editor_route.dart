import 'editor_route_name.dart';
import '../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';

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
}
