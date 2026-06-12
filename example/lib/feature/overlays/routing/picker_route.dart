import 'package:example/feature/overlays/routing/overlays_route_name.dart';
import 'package:example/feature/overlays/view/picker_screen.dart';
import 'package:example/routing/app_route.dart';
import 'package:flutter/material.dart';

/// Full-screen color picker pushed for a result.
final class PickerRoute extends AppRoute {
  const PickerRoute();

  @override
  LocalKey get pageKey => const ValueKey('picker');

  @override
  String get name => OverlaysRouteName.picker.wire;

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) =>
      MaterialPage(key: pageKey, child: const PickerScreen());
}
