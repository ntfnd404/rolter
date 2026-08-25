import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../model/route_node.dart';
import '../../pages/route_page_builder.dart';
import '../../state/navigation_queue.dart';
import '../../state/routes_state.dart';
import '../routing_delegate.dart';
import 'framework_transaction.dart';
import 'routing_coordinator.dart';

/// Delegate adapter for request completion, presentation, and root Back.
@internal
final class CoordinatedRoutingDelegate<R extends RouteNode>
    extends RouterDelegate<Object>
    with ChangeNotifier {
  /// Creates a coordinated delegate around the transparent FIFO delegate.
  CoordinatedRoutingDelegate(
    this._state,
    this._coordinator, {
    required RouteNodePageBuilder<R> pageBuilder,
    TransitionDelegate<Object?>? transitionDelegate,
  }) : _inner = RoutingDelegate<R>(
         _state,
         pageBuilder: pageBuilder,
         transitionDelegate: transitionDelegate,
       ) {
    _inner.addListener(_handleStateChanged);
    _coordinator.attachResyncHandler(_scheduleResync);
  }

  final RoutesState<R> _state;
  final RoutingCoordinator<R> _coordinator;
  final RoutingDelegate<R> _inner;
  bool _resyncScheduled = false;
  bool _disposed = false;

  @override
  Object get currentConfiguration => _coordinator.currentConfiguration();

  @override
  Widget build(BuildContext context) => _inner.build(context);

  @override
  Future<bool> popRoute() {
    if (_coordinator.isDisposed) {
      return SynchronousFuture<bool>(false);
    }
    final context = _coordinator.beginRootBack();
    Future<bool> result;
    try {
      result = _inner.popRoute();
    } on Object {
      _coordinator.completeRootBack(context);
      rethrow;
    }

    return result.then<bool>(
      (handled) {
        _coordinator.completeRootBack(context);
        return handled;
      },
      onError: (Object error, StackTrace stackTrace) {
        _coordinator.completeRootBack(context);
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  @override
  Future<void> setNewRoutePath(Object configuration) {
    if (configuration is! CoordinatedConfiguration<R> ||
        !configuration.isParsed ||
        configuration.transaction == null) {
      throw StateError(
        'RoutingConfig components must be used together.',
      );
    }
    final transaction = configuration.transaction!;
    if (_coordinator.isDisposed) {
      _coordinator.abandon(transaction);
      return SynchronousFuture<void>(null);
    }
    final navigationRequest = NavigationRequest(
      token: transaction,
      canCommit: () => _coordinator.canCommit(transaction),
      onSeal: () => _coordinator.seal(transaction),
      onSuccess: () => _coordinator.settleSuccess(transaction),
      onFailure: () => _coordinator.fail(transaction),
      onAbandon: () => _coordinator.abandon(transaction),
    );

    return applyFrameworkRoutePath<R>(
      _state,
      configuration.routes,
      navigationRequest,
    );
  }

  void _handleStateChanged() {
    if (_disposed || _coordinator.isDisposed) {
      return;
    }
    final request = activeFrameworkRouteRequest<R>(_state);
    if (request?.token is FrameworkTransaction) {
      return;
    }

    notifyListeners();
  }

  void _scheduleResync() {
    if (_disposed || _coordinator.isDisposed || _resyncScheduled) {
      return;
    }
    _resyncScheduled = true;
    scheduleMicrotask(() {
      _resyncScheduled = false;
      if (_disposed || _coordinator.isDisposed) {
        return;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _coordinator.detachResyncHandler();
    _inner.removeListener(_handleStateChanged);
    _inner.dispose();
    super.dispose();
  }
}
