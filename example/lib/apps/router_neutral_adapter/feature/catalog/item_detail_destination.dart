import '../../application/app_destination.dart';

/// Router-neutral item detail carrying all identity-bearing parameters.
final class ItemDetailDestination implements AppDestination {
  const ItemDetailDestination({required this.id});

  final int id;

  @override
  String get wireName => 'item';

  @override
  String get pageIdentity => 'item:$id';

  @override
  Map<String, String> toParams() => {'id': '$id'};

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  bool operator ==(Object other) =>
      other is ItemDetailDestination && other.id == id;
}
