import 'package:example/feature/picker/routing/picker_route.dart';
import 'package:example/feature/picker/routing/picker_route_name.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Picker feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get pickerRoutes => {
  PickerRouteName.picker.wire: (_, _) => const PickerRoute(),
};
