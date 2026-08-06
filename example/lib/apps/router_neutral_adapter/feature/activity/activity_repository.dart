/// Narrow dependency consumed by the Activity feature.
abstract interface class ActivityRepository {
  /// Returns the label displayed for [sequence].
  String labelFor(int sequence);
}

/// Immutable repository used by the runnable adapter example.
final class StaticActivityRepository implements ActivityRepository {
  /// Creates a repository with a visible [source] label.
  const StaticActivityRepository(this.source);

  /// Source name rendered by the example.
  final String source;

  @override
  String labelFor(int sequence) => '$source activity #$sequence';
}
