/// Immutable presentation data rendered by the shared example UI.
///
/// This is deliberately not a domain entity. Each example application owns
/// its domain and maps the values required by the shared UI at its presentation
/// boundary.
final class DemoItemViewData {
  /// Creates presentation data for one item.
  const DemoItemViewData({
    required this.id,
    required this.title,
    required this.description,
  });

  /// Stable identity shown by the comparison flow.
  final int id;

  /// Primary item label.
  final String title;

  /// Item details rendered by the detail content.
  final String description;
}
