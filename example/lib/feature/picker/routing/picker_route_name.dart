/// Wire names for the Picker (push-for-result) feature's routes.
enum PickerRouteName {
  picker('picker');

  const PickerRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
