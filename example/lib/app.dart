import 'core/di/app_dependencies.dart';
import 'core/di/app_scope.dart';
import 'feature/home/routing/home_route.dart';
import 'feature/tabbed_stack/shared/data/data_sources/item_local_data_source_impl.dart';
import 'feature/tabbed_stack/shared/data/repositories/item_repository_impl.dart';
import 'feature/mailbox/data/data_sources/mail_local_data_source_impl.dart';
import 'feature/mailbox/data/repositories/mail_repository_impl.dart';
import 'feature/session/application/session_lock_service.dart';
import 'feature/session/bloc/lock_bloc.dart';
import 'feature/session/routing/lock_guard.dart';
import 'core/routing/app_navigator.dart';
import 'core/routing/app_registry.dart';
import 'core/routing/app_route.dart';
import 'core/routing/nav_log_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rolter/rolter.dart';

/// Root of the rolter example — the composition root. Builds the engine pieces
/// over [AppRoute] and aggregates each feature's decoders via [appRegistry].
///
/// `NavigatorScope` sits ABOVE `MaterialApp.router` (read by `buildPage` via the
/// delegate context). `AppScope` + the `LockBloc` provider sit in the router's
/// `builder:` — below `MaterialApp` (so the DI graph has `Theme`/`MediaQuery`)
/// and above the `Navigator`.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  // Composition root: the dependency graph (data source -> repository) is wired
  // here once, then exposed app-wide via AppScope — never in a route or screen.
  final AppDependencies _dependencies = const AppDependencies(
    mailRepository: MailRepositoryImpl(MailLocalDataSourceImpl()),
    itemRepository: ItemRepositoryImpl(ItemLocalDataSourceImpl()),
  );
  late final SessionLockService _lockService;
  late final LockGuard _lockGuard;
  late final RoutesState<AppRoute> _state;
  late final AppNavigator _navigator;
  late final RoutingDelegate<AppRoute> _delegate;
  late final RoutingInformationParser<AppRoute> _parser;
  // Captures the entry URL's query (e.g. utm_*); values are never logged.
  final EntryQueryStore _entryQuery = EntryQueryStore();

  @override
  void initState() {
    super.initState();
    _lockService = SessionLockService();
    _lockGuard = LockGuard(_lockService);
    final pipeline = GuardedPipeline<AppRoute>(
      guards: <RouteGuard<AppRoute>>[_lockGuard],
      normalize: normalizeAppStack,
      currentStack: () => _state.root,
    );
    _state = RoutesState<AppRoute>(
      const [HomeRoute()],
      pipeline.call,
      observers: [NavigationLogObserver()],
    );
    pipeline.refresh.addListener(_state.reevaluate);
    _navigator = AppNavigator(_state);
    _delegate = RoutingDelegate<AppRoute>(_state);
    _parser = RoutingInformationParser<AppRoute>(
      TreeUrlCodec<AppRoute>(appRegistry),
      entryQuery: _entryQuery,
    );
    _entryQuery.addListener(
      () => debugPrint(
        'entry query updated (${_entryQuery.value.length} parameters)',
      ),
    );
  }

  @override
  void dispose() {
    _delegate.dispose();
    _state.dispose();
    _lockGuard.dispose();
    _lockService.dispose();
    _entryQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorScope<AppNavigator>(
      navigator: _navigator,
      child: MaterialApp.router(
        title: 'rolter example',
        // The navigation tree restores from RouteInformation after the OS kills
        // the app (state restoration), in addition to deep links on web.
        restorationScopeId: 'rolter-example',
        routerDelegate: _delegate,
        routeInformationParser: _parser,
        builder: (context, child) => AppScope(
          dependencies: _dependencies,
          child: BlocProvider<LockBloc>(
            create: (_) => LockBloc(_lockService),
            child: child!,
          ),
        ),
      ),
    );
  }
}
