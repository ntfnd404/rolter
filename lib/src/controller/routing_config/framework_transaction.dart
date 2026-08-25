import 'package:flutter/foundation.dart';

import '../../model/route_node.dart';

/// Lifecycle phases for one package-internal framework transaction.
@internal
enum FrameworkTransactionPhase {
  /// The latest request is not yet protected by an application FIFO barrier.
  pending,

  /// An application entry depends on this request, so it cannot be superseded.
  sealedPending,

  /// The request passed its commit boundary successfully.
  settledSuccess,

  /// The request failed while it was live.
  failed,

  /// A newer platform or application intent replaced the pending request.
  superseded,

  /// Lifecycle teardown or late work abandoned the request.
  abandoned,
}

/// State owned by one package-internal framework route transaction.
@internal
final class FrameworkTransaction {
  /// Creates a pending transaction without retaining `RouteInformation.state`.
  FrameworkTransaction(this.originUri, this.platformGeneration);

  /// Platform URI that initiated this transaction.
  final Uri originUri;

  /// Platform-intent generation at transaction creation.
  final int platformGeneration;

  FrameworkTransactionPhase _phase = FrameworkTransactionPhase.pending;

  /// Current read-only lifecycle phase.
  FrameworkTransactionPhase get phase => _phase;

  /// Whether the transaction may still settle, fail, or be abandoned.
  bool get isPending =>
      _phase == FrameworkTransactionPhase.pending ||
      _phase == FrameworkTransactionPhase.sealedPending;

  /// Protects a pending request as an application FIFO dependency.
  bool seal() => _transition(
    from: const <FrameworkTransactionPhase>{FrameworkTransactionPhase.pending},
    to: FrameworkTransactionPhase.sealedPending,
  );

  /// Settles a pending or sealed request successfully.
  bool settleSuccess() => _transition(
    from: const <FrameworkTransactionPhase>{
      FrameworkTransactionPhase.pending,
      FrameworkTransactionPhase.sealedPending,
    },
    to: FrameworkTransactionPhase.settledSuccess,
  );

  /// Fails a pending or sealed live request.
  bool fail() => _transition(
    from: const <FrameworkTransactionPhase>{
      FrameworkTransactionPhase.pending,
      FrameworkTransactionPhase.sealedPending,
    },
    to: FrameworkTransactionPhase.failed,
  );

  /// Supersedes only an unsealed pending request.
  bool supersede() => _transition(
    from: const <FrameworkTransactionPhase>{FrameworkTransactionPhase.pending},
    to: FrameworkTransactionPhase.superseded,
  );

  /// Abandons a pending or sealed request during lifecycle teardown.
  bool abandon() => _transition(
    from: const <FrameworkTransactionPhase>{
      FrameworkTransactionPhase.pending,
      FrameworkTransactionPhase.sealedPending,
    },
    to: FrameworkTransactionPhase.abandoned,
  );

  bool _transition({
    required Set<FrameworkTransactionPhase> from,
    required FrameworkTransactionPhase to,
  }) {
    if (!from.contains(_phase)) {
      return false;
    }
    _phase = to;
    return true;
  }
}

/// Correlates browser correction with the app entry that caused supersession.
@internal
final class SupersessionContext {
  /// Creates a context tied to platform and application generations.
  SupersessionContext({
    required this.originUri,
    required this.platformGeneration,
    required this.applicationGeneration,
  });

  /// URI that must be restored if no newer route is published.
  final Uri originUri;

  /// Platform generation that owns this correction.
  final int platformGeneration;

  /// Application generation at the point of supersession.
  final int applicationGeneration;

  bool _claimedByApplication = false;
  bool _resolved = false;

  /// Whether a root Back navigation entry claimed this context.
  bool get isClaimedByApplication => _claimedByApplication;

  /// Whether publication or correction already resolved this context.
  bool get isResolved => _resolved;

  /// Associates this root Back context with an enqueued app mutation.
  void claimByApplication() => _claimedByApplication = true;

  /// Prevents duplicate publication or correction.
  void resolve() => _resolved = true;
}

/// Internal envelope shared by coordinated parser and delegate adapters.
@internal
final class CoordinatedConfiguration<R extends RouteNode> {
  /// Wraps one freshly parsed framework configuration.
  CoordinatedConfiguration.parsed(List<R> routes, this.transaction)
    : routes = List<R>.unmodifiable(routes),
      isParsed = true,
      suppressReport = false,
      reportOriginUri = null;

  /// Wraps the current committed presentation for Flutter restoration.
  CoordinatedConfiguration.presentation(
    List<R> routes, {
    required this.reportOriginUri,
    required this.suppressReport,
  }) : routes = List<R>.unmodifiable(routes),
       isParsed = false,
       transaction = null;

  /// Immutable decoded or committed route tree.
  final List<R> routes;

  /// Framework transaction for a parsed envelope, otherwise null.
  final FrameworkTransaction? transaction;

  /// Whether this envelope came from parser input.
  final bool isParsed;

  /// Whether Flutter must skip reporting this presentation.
  final bool suppressReport;

  /// Browser URI used to decide whether correction requires `neglect`.
  final Uri? reportOriginUri;
}
