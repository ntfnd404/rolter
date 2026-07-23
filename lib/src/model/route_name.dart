// Route names form the unescaped body of Rolter's depth- and
// parameter-delimited URL path segments. Restrict them to this deliberately
// small alphabet so they cannot collide with structural delimiters such as
// `/`, `.`, and `~`.
final RegExp _urlSafeRouteName = RegExp(r'^[A-Za-z0-9_-]+$');

/// Whether [name] can be written as a route-name body in Rolter's URL grammar.
///
/// Valid names contain only ASCII letters, digits, underscores, and hyphens.
bool isUrlSafeRouteName(String name) => _urlSafeRouteName.hasMatch(name);

/// Rejects a route [name] that is incompatible with Rolter's URL grammar.
void validateRouteName(String name, {required String argumentName}) {
  if (!isUrlSafeRouteName(name)) {
    throw ArgumentError.value(
      name,
      argumentName,
      'must match [A-Za-z0-9_-]+; "/", ".", "~", and spaces are invalid',
    );
  }
}
