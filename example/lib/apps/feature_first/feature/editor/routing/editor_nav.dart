import 'editor_route.dart';
import '../../../navigation/app_navigator.dart';

/// Editor feature navigation sugar, added to the shared [AppNavigator].
extension EditorNav on AppNavigator {
  void toEditor() => push(const EditorRoute());
}
