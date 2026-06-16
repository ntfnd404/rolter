import 'package:example/feature/editor/routing/editor_route.dart';
import 'package:example/core/routing/app_navigator.dart';

/// Editor feature navigation sugar, added to the shared [AppNavigator].
extension EditorNav on AppNavigator {
  void toEditor() => push(const EditorRoute());
}
