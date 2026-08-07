import 'app_destination.dart';

/// Safe fallback for unknown or invalid adapter-example URLs.
final class NotFoundDestination implements AppDestination {
  /// Creates the constant fallback destination.
  const NotFoundDestination();

  @override
  String get wireName => 'not-found';

  @override
  String get pageIdentity => 'not-found';

  @override
  Map<String, String> toParams() => const {};

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) => other is NotFoundDestination;
}
