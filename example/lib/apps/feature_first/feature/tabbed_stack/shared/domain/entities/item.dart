/// An item — the items domain entity, shared by the `items` (list) and
/// `item_detail` sub-features of the Tabs group.
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
