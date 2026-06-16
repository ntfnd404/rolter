import 'package:example/feature/picker/routing/picker_route.dart';
import 'package:example/core/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Picker feature navigation sugar, added to the shared [AppNavigator].
extension PickerNav on AppNavigator {
  Future<Color?> pickColor() => pushForResult<Color>(const PickerRoute());
}
