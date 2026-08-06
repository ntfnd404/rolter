import 'picker_route_name.dart';
import '../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';

/// Full-screen color picker pushed for a result.
final class PickerRoute extends AppRoute {
  const PickerRoute();

  @override
  LocalKey get pageKey => const ValueKey('picker');

  @override
  String get name => PickerRouteName.picker.wire;

  @override
  Map<String, String> toParams() => const {};
}
