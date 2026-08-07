/// Router-engine-neutral navigation data used by the adapter example.
///
/// Implementations are immutable value objects. [pageIdentity] must include
/// every identity-bearing parameter and be unique in an open stack.
abstract interface class AppDestination {
  /// URL wire segment owned by the feature.
  String get wireName;

  /// Stable page identity without a Flutter or router-engine type.
  String get pageIdentity;

  /// Serializable URL parameters.
  Map<String, String> toParams();
}
