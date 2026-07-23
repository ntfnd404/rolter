import 'picker_route.dart';
import '../../../core/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Picker feature navigation sugar, added to the shared [AppNavigator].
extension PickerNav on AppNavigator {
  Future<Color?> pickColor() => pushForResult<Color>(const PickerRoute());
}
