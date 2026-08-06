import '../../application/app_destination.dart';

/// Router-neutral item-list destination.
final class ItemsDestination implements AppDestination {
  const ItemsDestination();

  @override
  String get wireName => 'items';

  @override
  String get pageIdentity => 'items';

  @override
  Map<String, String> toParams() => const {};

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) => other is ItemsDestination;
}
