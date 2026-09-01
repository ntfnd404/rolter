import 'composition/app_dependencies.dart';
import 'feature/home/routing/home_route.dart';
import 'feature/tabbed_stack/shared/data/data_sources/item_local_data_source_impl.dart';
import 'feature/tabbed_stack/shared/data/repositories/item_repository_impl.dart';
import 'feature/mailbox/data/data_sources/mail_local_data_source_impl.dart';
import 'feature/mailbox/data/repositories/mail_repository_impl.dart';
import 'feature/session/application/session_lock_service.dart';
import 'feature/session/bloc/lock_bloc.dart';
import 'feature/session/routing/lock_guard.dart';
import 'navigation/app_navigator.dart';
import 'composition/app_pages.dart';
import 'composition/app_registry.dart';
import 'navigation/app_route.dart';
import 'composition/app_route_page_catalog.dart';
import 'navigation/nav_log_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rolter/rolter.dart';

import '../../common/ui/example_theme.dart';

/// Creates the feature-first reference application.
FeatureFirstExampleApp createFeatureFirstExampleApp() =>
    const FeatureFirstExampleApp();

/// Root of the rolter example — the composition root. Builds the engine pieces
/// over [AppRoute] and aggregates each feature's decoders via [appRegistry].
///
/// `NavigatorScope` sits above `MaterialApp.router`, where the external page
/// catalog can read it through the delegate context. The `LockBloc` provider
/// sits in the router's `builder:` and is therefore visible to page subtrees.
class FeatureFirstExampleApp extends StatefulWidget {
  const FeatureFirstExampleApp({super.key});

  @override
  State<FeatureFirstExampleApp> createState() => _FeatureFirstExampleAppState();
}

class _FeatureFirstExampleAppState extends State<FeatureFirstExampleApp> {
  // Composition root: the dependency graph (data source -> repository) is wired
  // here once, then narrowed into typed page definitions — never stored in a
  // route and never exposed as one app-wide service locator.
  final AppDependencies _dependencies = const AppDependencies(
    mailRepository: MailRepositoryImpl(MailLocalDataSourceImpl()),
    itemRepository: ItemRepositoryImpl(ItemLocalDataSourceImpl()),
  );
  late final SessionLockService _lockService;
  late final LockGuard _lockGuard;
  late final RoutesState<AppRoute> _state;
  late final AppNavigator _navigator;
  late final AppRoutePageCatalog _pages;
  late final RoutingConfig<AppRoute> _router;
  late final Listenable _routeRefresh;
  late final VoidCallback _reevaluateRoutes;
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
    _routeRefresh = pipeline.refresh;
    _reevaluateRoutes = _state.reevaluate;
    _routeRefresh.addListener(_reevaluateRoutes);
    _navigator = AppNavigator(_state);
    _pages = buildAppPages(dependencies: _dependencies);
    _router = RoutingConfig<AppRoute>(
      state: _state,
      routeInformationParser: RoutingInformationParser<AppRoute>(
        TreeUrlCodec<AppRoute>(appRegistry),
        routesForRootPath: (_) => const <AppRoute>[HomeRoute()],
        entryQuery: _entryQuery,
      ),
      pageBuilder: _pages.build,
    );
    _entryQuery.addListener(
      () => debugPrint(
        'entry query updated (${_entryQuery.value.length} parameters)',
      ),
    );
  }

  @override
  void dispose() {
    _routeRefresh.removeListener(_reevaluateRoutes);
    _router.dispose();
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
        theme: buildExampleTheme(),
        // The navigation tree restores from RouteInformation after the OS kills
        // the app (state restoration), in addition to deep links on web.
        restorationScopeId: 'rolter-example',
        routerConfig: _router,
        builder: (context, child) => BlocProvider<LockBloc>(
          create: (_) => LockBloc(_lockService),
          child: child!,
        ),
      ),
    );
  }
}
