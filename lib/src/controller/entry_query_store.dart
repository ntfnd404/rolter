import 'package:flutter/foundation.dart';

/// Holds the raw query parameters of the most recently parsed entry URL.
///
/// `TreeUrlCodec` merges a standard `?k=v` query into the top route's params on
/// decode, but params the route tree does not model (tracking such as `utm_*`,
/// `fbclid`, `gclid`) would otherwise be lost. Pass a store to
/// `RoutingInformationParser` to keep them available app-wide (e.g. forward
/// them to analytics, or read them from a guard via the shared pipeline
/// context).
///
/// The store is a [ValueListenable], so widgets/guards can react to a new entry
/// URL; most apps simply read [value] once after the first frame.
class EntryQueryStore extends ChangeNotifier
    implements ValueListenable<Map<String, String>> {
  /// Creates an empty entry-query store.
  EntryQueryStore();

  Map<String, String> _value = const <String, String>{};

  /// The most recent entry URL's query parameters (empty until the first
  /// parse). Includes everything from the URL's query — both params the routes
  /// consumed and pass-through ones they ignored.
  @override
  Map<String, String> get value => _value;

  /// Records [query] for the latest parsed URL. Called by the parser; not part
  /// of the app-facing API. Notifies listeners only on a real change.
  void capture(Map<String, String> query) {
    if (mapEquals(_value, query)) {
      return;
    }
    _value = Map<String, String>.unmodifiable(query);
    notifyListeners();
  }
}
