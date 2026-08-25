import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../model/route_node.dart';
import '../../state/routes_state.dart';
import 'framework_transaction.dart';

/// Coordinates framework transactions, app entries, and route reporting.
@internal
final class RoutingCoordinator<R extends RouteNode>
    implements RoutesStateCoordinator {
  /// Creates a coordinator backed by the single committed route state.
  RoutingCoordinator(this.state);

  /// Backing route state borrowed by `RoutingConfig`.
  final RoutesState<R> state;

  FrameworkTransaction? _latest;
  _RoutePresentation _presentation = const _RoutePresentation.application();
  _PreparedRouteReport? _preparedReport;
  VoidCallback? _resyncHandler;
  SupersessionContext? _pendingRootBackContext;
  int _platformGeneration = 0;
  int _applicationGeneration = 0;
  bool _disposed = false;

  /// Whether the coordinator or its backing state has been disposed.
  bool get isDisposed => _disposed || routesStateIsDisposed<R>(state);

  /// Starts a distinct platform transaction at parser entry.
  FrameworkTransaction begin(RouteInformation information) {
    final previous = _latest;
    if (previous != null) {
      supersede(previous);
    }
    _platformGeneration++;
    final transaction = FrameworkTransaction(
      information.uri,
      _platformGeneration,
    );
    _latest = transaction;
    _pendingRootBackContext = null;
    _preparedReport = null;
    if (isDisposed) {
      abandon(transaction);
    }

    return transaction;
  }

  /// Whether [transaction] may still publish its decoded snapshot.
  bool canCommit(FrameworkTransaction transaction) =>
      !isDisposed &&
      switch (transaction.phase) {
        FrameworkTransactionPhase.pending => identical(_latest, transaction),
        FrameworkTransactionPhase.sealedPending => true,
        _ => false,
      };

  /// Whether [transaction] is the newest platform intent.
  bool isLatest(FrameworkTransaction transaction) =>
      identical(_latest, transaction);

  /// Protects a valid pending transaction as an app FIFO dependency.
  void seal(FrameworkTransaction transaction) {
    if (canCommit(transaction)) {
      transaction.seal();
    }
  }

  /// Supersedes an unsealed pending transaction.
  void supersede(FrameworkTransaction transaction) {
    if (transaction.supersede()) {
      _preparedReport = null;
    }
  }

  /// Records successful settlement at the queue commit boundary.
  void settleSuccess(FrameworkTransaction transaction) {
    if (!transaction.settleSuccess()) {
      return;
    }
    _presentation = isLatest(transaction)
        ? _RoutePresentation.framework(transaction.originUri)
        : const _RoutePresentation.suppressed();
    _preparedReport = null;
  }

  /// Records one live framework failure and prepares resynchronization.
  void fail(FrameworkTransaction transaction) {
    if (!transaction.fail()) {
      return;
    }
    if (isLatest(transaction)) {
      _setCorrection(transaction.originUri, notify: true);
    }
  }

  /// Records lifecycle abandonment without publishing route state.
  void abandon(FrameworkTransaction transaction) => transaction.abandon();

  /// Creates Flutter's presentation envelope for the committed route root.
  CoordinatedConfiguration<R> currentConfiguration() =>
      CoordinatedConfiguration<R>.presentation(
        state.root,
        reportOriginUri: _presentation.originUri,
        suppressReport: _presentation.kind == _RoutePresentationKind.suppressed,
      );

  /// Associates a restored route report with its presentation policy.
  void prepareReport(
    CoordinatedConfiguration<R> configuration,
    RouteInformation? restored,
  ) {
    if (restored == null || configuration.suppressReport || isDisposed) {
      _preparedReport = null;
      return;
    }
    final reportOriginUri = configuration.reportOriginUri;
    final replace = reportOriginUri != null && restored.uri != reportOriginUri;
    _preparedReport = _PreparedRouteReport(restored, replace: replace);
  }

  /// Applies replace-style correction only to the matching default report.
  RouteInformationReportingType reportingType(
    RouteInformation information,
    RouteInformationReportingType requested,
  ) {
    final prepared = _preparedReport;
    _preparedReport = null;
    if (requested != RouteInformationReportingType.none ||
        prepared == null ||
        !identical(prepared.information, information) ||
        !prepared.replace) {
      return requested;
    }

    return RouteInformationReportingType.neglect;
  }

  /// Registers the coordinated delegate's resync callback.
  void attachResyncHandler(VoidCallback handler) => _resyncHandler = handler;

  /// Removes the exact coordinated delegate resync callback.
  void detachResyncHandler() => _resyncHandler = null;

  /// Converts a current parser error into a failed transaction.
  void reportParserFailure(FrameworkTransaction transaction) {
    fail(transaction);
  }

  /// Supersedes an unsealed platform request before root Back handling.
  SupersessionContext? beginRootBack() {
    final latest = _latest;
    if (latest == null || latest.phase != FrameworkTransactionPhase.pending) {
      return null;
    }
    final context = _createSupersessionContext(latest);
    supersede(latest);
    _pendingRootBackContext = context;

    return context;
  }

  @override
  Object? beginApplicationNavigation() {
    SupersessionContext? context;
    final rootBackContext = _pendingRootBackContext;
    if (rootBackContext != null && _canApplyCorrection(rootBackContext)) {
      rootBackContext.claimByApplication();
      context = rootBackContext;
    }
    _pendingRootBackContext = null;

    final latest = _latest;
    if (latest != null && latest.phase == FrameworkTransactionPhase.pending) {
      context = _createSupersessionContext(latest);
      supersede(latest);
    }

    _preparedReport = null;

    return context;
  }

  @override
  void completeApplicationNavigation(
    Object? context, {
    required bool changed,
    required bool needsResync,
  }) {
    if (isDisposed) {
      return;
    }
    final supersession = context is SupersessionContext ? context : null;
    if (changed) {
      _applicationGeneration++;
      supersession?.resolve();
      _presentation = const _RoutePresentation.application();
      _preparedReport = null;
      return;
    }

    if (supersession != null && _canApplyCorrection(supersession)) {
      supersession.resolve();
      _setCorrection(supersession.originUri, notify: !needsResync);
      return;
    }

    if (needsResync) {
      _presentation = const _RoutePresentation.application();
      _preparedReport = null;
    }
  }

  @override
  void failApplicationNavigation(Object? context) {
    final supersession = context is SupersessionContext ? context : null;
    if (supersession == null || !_canApplyCorrection(supersession)) {
      return;
    }
    supersession.resolve();
    _setCorrection(supersession.originUri, notify: true);
  }

  /// Completes root Back correction when no app mutation claimed its context.
  void completeRootBack(SupersessionContext? context) {
    if (identical(_pendingRootBackContext, context)) {
      _pendingRootBackContext = null;
    }
    if (context == null ||
        context.isClaimedByApplication ||
        !_canApplyCorrection(context)) {
      return;
    }
    context.resolve();
    _setCorrection(context.originUri, notify: true);
  }

  SupersessionContext _createSupersessionContext(
    FrameworkTransaction transaction,
  ) => SupersessionContext(
    originUri: transaction.originUri,
    platformGeneration: transaction.platformGeneration,
    applicationGeneration: _applicationGeneration,
  );

  bool _canApplyCorrection(SupersessionContext context) =>
      !isDisposed &&
      !context.isResolved &&
      context.platformGeneration == _platformGeneration &&
      context.applicationGeneration == _applicationGeneration;

  void _setCorrection(Uri originUri, {required bool notify}) {
    if (isDisposed) {
      return;
    }
    _presentation = _RoutePresentation.correction(originUri);
    _preparedReport = null;
    if (notify) {
      _resyncHandler?.call();
    }
  }

  @override
  void onRoutesStateDisposed() => dispose();

  /// Abandons live coordination and suppresses every future report effect.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final latest = _latest;
    if (latest != null) {
      abandon(latest);
    }
    _pendingRootBackContext = null;
    _presentation = const _RoutePresentation.suppressed();
    _preparedReport = null;
    _resyncHandler = null;
  }
}

enum _RoutePresentationKind { framework, application, correction, suppressed }

final class _RoutePresentation {
  const _RoutePresentation.framework(this.originUri)
    : kind = _RoutePresentationKind.framework;

  const _RoutePresentation.application()
    : kind = _RoutePresentationKind.application,
      originUri = null;

  const _RoutePresentation.correction(this.originUri)
    : kind = _RoutePresentationKind.correction;

  const _RoutePresentation.suppressed()
    : kind = _RoutePresentationKind.suppressed,
      originUri = null;

  final _RoutePresentationKind kind;
  final Uri? originUri;
}

final class _PreparedRouteReport {
  const _PreparedRouteReport(this.information, {required this.replace});

  final RouteInformation information;
  final bool replace;
}
