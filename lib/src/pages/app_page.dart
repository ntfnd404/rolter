import 'dart:async';

import 'package:flutter/material.dart';

/// Default page: a platform Material route. Carries an optional [completer]
/// resolved with the pop result — the basis for `pushForResult` (v2).
class AppPage<T> extends Page<T> {
  /// Creates a page that shows [child], optionally resolving [completer]
  /// with the pop result.
  const AppPage({
    required this.child,
    this.completer,
    super.key,
    super.name,
    super.arguments,
  });

  /// The widget shown by this page.
  final Widget child;

  /// Resolved with the pop result when this page is popped, if set.
  final Completer<T?>? completer;

  @override
  Route<T> createRoute(BuildContext context) {
    final route = MaterialPageRoute<T>(settings: this, builder: (_) => child);
    final pending = completer;
    if (pending != null) {
      unawaited(
        route.popped.then((value) {
          if (!pending.isCompleted) {
            pending.complete(value);
          }
        }),
      );
    }

    return route;
  }
}
