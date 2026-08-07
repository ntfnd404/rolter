import '../../application/app_destination.dart';

/// Router-neutral activity destination with URL-backed identity.
final class ActivityDestination implements AppDestination {
  /// Creates an activity destination for a positive [sequence].
  const ActivityDestination({required this.sequence})
    : assert(sequence > 0, 'sequence must be positive');

  /// Sequence selected by the URL or application navigation.
  final int sequence;

  @override
  String get wireName => 'activity';

  @override
  String get pageIdentity => 'activity:$sequence';

  @override
  Map<String, String> toParams() => {'sequence': '$sequence'};

  @override
  int get hashCode => Object.hash(ActivityDestination, sequence);

  @override
  bool operator ==(Object other) =>
      other is ActivityDestination && other.sequence == sequence;
}
