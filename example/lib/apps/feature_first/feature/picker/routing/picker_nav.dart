import 'dart:ui' show Color;

import 'picker_route.dart';
import '../../../navigation/app_navigator.dart';

/// Picker feature navigation sugar, added to the shared [AppNavigator].
extension PickerNav on AppNavigator {
  Future<Color?> pickColor() => pushForResult<Color>(const PickerRoute());
}
