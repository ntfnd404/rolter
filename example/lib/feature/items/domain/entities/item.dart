/// An item — the items feature's domain entity.
class Item {
  const Item({
    required this.id,
    required this.title,
    required this.description,
  });

  final int id;
  final String title;
  final String description;
}
