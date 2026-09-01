import 'package:flutter/foundation.dart';

/// Holds the decoded query parameters of the most recently attempted entry URL.
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
/// It uses [Uri.queryParameters], a single-value decoded map: original percent
/// encoding and lossless repeated-key information are not retained. Capture
/// happens before route resolution and is not rolled back if parsing later
/// fails, so [value] represents the most recent entry attempt.
class EntryQueryStore extends ChangeNotifier
    implements ValueListenable<Map<String, String>> {
  /// Creates an empty entry-query store.
  EntryQueryStore();

  Map<String, String> _value = const <String, String>{};

  /// The most recent attempted entry URL's decoded query parameters.
  ///
  /// The map is empty until the first parse attempt. It includes parameters the
  /// routes consumed and pass-through ones they ignored, but is not a lossless
  /// representation of the original query string.
  @override
  Map<String, String> get value => _value;

  /// Records decoded [query] for the latest attempted entry URL.
  ///
  /// The built-in parser calls this before route resolution. Notifies listeners
  /// only on a real change.
  void capture(Map<String, String> query) {
    if (mapEquals(_value, query)) {
      return;
    }
    _value = Map<String, String>.unmodifiable(query);
    notifyListeners();
  }
}
