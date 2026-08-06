import '../../application/app_destination.dart';

/// Router-neutral home destination.
final class HomeDestination implements AppDestination {
  /// Creates the home destination.
  const HomeDestination();

  @override
  String get wireName => 'home';

  @override
  String get pageIdentity => 'home';

  @override
  Map<String, String> toParams() => const {};

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) => other is HomeDestination;
}
