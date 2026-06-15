import 'package:example/feature/overlays/routing/confirm_route.dart';
import 'package:example/feature/overlays/routing/picker_route.dart';
import 'package:example/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Overlays feature navigation sugar, added to the shared [AppNavigator].
extension OverlaysNav on AppNavigator {
  Future<Color?> pickColor() => pushForResult<Color>(const PickerRoute());

  Future<bool?> confirm(String message) =>
      pushForResult<bool>(ConfirmRoute(message));
}
