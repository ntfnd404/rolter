# rolter example

## Runnable composition approaches

This package keeps four reference applications in isolated folders under
`lib/apps/`. They exist because they solve four different application shapes,
not because Rolter exposes four competing composition APIs. Rolter's two core
modes are route-owned Pages and an external Page builder.

All four apps share only content-only Flutter widgets from `lib/common/ui/`
for a comparable Home → Items → Item detail flow:

- **Feature-first** solves modular ownership with data-only routes, typed Page
  contributions, and narrow constructor injection. It is the default.
- **Centralized route-owned** solves the conventional small-app case with one
  route catalog and minimum boilerplate.
- **External builder + Scope** separates UI from route data while preserving
  an existing inherited-DI model.
- **Router-neutral adapter** isolates application contracts for a concrete
  multi-app or multi-router requirement. It is deliberately bounded and
  application-only.

`AppScope` was an application-specific inherited container, not Rolter API. A
user-defined `AppScope.of(context)` still works when placed above the router,
but the primary example avoids exposing the entire dependency graph to leaf
widgets.

The adapter entrypoint is not the enterprise default and does not reproduce
nested navigation, namespaces, guards, history, results, or restoration behind
a neutral SPI. Its purpose is to make the extra model and mapping cost concrete
when multi-app or multi-router reuse is an actual requirement.

A small app exercising the [`rolter`](../) routing engine end to end. Every
scenario on the home screen maps to one typed route in the catalog.

The primary app is organised **feature-first**: each feature owns data-only
routes, screens, wire-name enum, decoder contribution, typed page contribution,
and navigation sugar. Its `composition/` directory only aggregates those
contributions. The other app folders remain independent alternatives.

## Run

```bash
cd example
flutter run # defaults to feature-first

# Select through the root compile-time launcher:
flutter run --dart-define-from-file=env/feature_first.env
flutter run --dart-define-from-file=env/centralized_route_owned.env
flutter run --dart-define-from-file=env/external_builder_scope.env
flutter run --dart-define-from-file=env/router_neutral_adapter.env

# Or compile one isolated import graph directly:
flutter run -t lib/apps/feature_first/main.dart
flutter run -t lib/apps/centralized_route_owned/main.dart
flutter run -t lib/apps/external_builder_scope/main.dart
flutter run -t lib/apps/router_neutral_adapter/main.dart
```

Open `example/` as the VS Code workspace to use the same four launch presets.
The root launcher is developer convenience, not a fifth architecture.

## What it demonstrates

| Scenario | Route | Notes |
|---|---|---|
| Flat + deep link | `DetailRoute` | Typed param in the URL (`/home/detail~id=5`) |
| Custom transition | `AnimatedRoute` | Slide-up + fade via `TransitionPage` |
| Master-detail | `MailboxRoute` | Selection in the URL; split on wide, push on narrow |
| Tabs + nested stack | `TabsRoute` | `IndexedStack` tabs, shared AppBar, cascading back, guarded |
| Multi-tab independent stacks | `MultiTabsRoute` | Each tab keeps its own nested stack — all of it in the URL |
| Push-for-result | `PickerRoute` | `pushForResult` / `popWith` returns a value |
| Dialog-as-route | `ConfirmRoute` | `TransparentPage`; back/barrier closes, returns `bool` |
| Per-route scope | `ScopeRoute` | Controller created/disposed with the page (`RouteScope`) |
| Confirm on leave | `EditorRoute` | `PopScope` blocks back while there are unsaved changes |
| Guard / lock | `LockRoute` | Locking redirects; unlocking restores the intent |
| Navigation telemetry | `NavigationLogObserver` | A `NavObserver` logs each transition (entered/left page keys) |
| Not found | `NotFoundRoute` | Unknown URL; kept out of history |

## Custom `Page` types in use

The engine is page-agnostic, so a typed page contribution may return any
`Page`:

- `NoAnimationPage` (engine) — the lock screen appears instantly on redirect.
- `NoAnimationTransitionDelegate` (engine) — the whole Items tab switches with
  no slide (passed to its `NestedNavigatorHost.transitionDelegate`).
- `TransparentPage` (engine) — the confirm dialog (scrim + dismissible).
- `TransitionPage` (engine) — the "Custom transition" tile: a slide-up + fade
  built by passing a `transitionsBuilder`, with no custom `Page` subclass.

## Nested navigation & the AppBar

The engine never imposes a `Scaffold`/`AppBar`; the external page catalog
returns any widget, so the AppBar is entirely the app's choice — pick a strategy
by where you place `Scaffold(appBar:)`:

- **Shared AppBar over a nested stack** — the Tabs demo: `TabsShell` owns one
  AppBar and the nested screens are content only. Because that AppBar is outside
  the nested navigator, back is driven from route state and **cascades**: a
  pushed detail pops the nested stack (back to the list), and at the tab root it
  leaves the Tabs section (back to Home).
- **Shared AppBar over a split** — the wide Mailbox: one `AppBar` over the
  list + detail `Row`.
- **Per-screen AppBar** — alternatively give each nested screen its own
  `Scaffold` + `AppBar`, and a pushed detail gets the back arrow automatically.

The Items tab also shows both `NestedNavigatorHost` extras: a `transitionDelegate`
(`NoAnimationTransitionDelegate`, instant switches) and an `onBackButtonPressed`
hook that mirrors the AppBar's cascade for the system back button.

## Where things live

```
lib/
  main.dart                    compile-time launcher (feature-first default)
  example_app_launcher.dart    selection only; not a fifth architecture
  common/ui/                   presentation-only comparison widgets
  apps/
    centralized_route_owned/  one catalog with route-owned Pages
    external_builder_scope/   route_data + external composition + Scope
    feature_first/             enterprise feature contributions
    router_neutral_adapter/   application SPI + RolterAdapter
```

Inside `apps/feature_first/`, each feature owns data-only `routing/`, separate
`page_composition/`, screens under `view/`, and any state. The app page catalog
captures `AppDependencies`, then passes only `MailRepository` or
`ItemRepository` to the features that need them; leaf widgets never read the
full dependency container.
State holders sit by approach:
`bloc/` for a `Bloc` (session), `controller/` for a `ChangeNotifier` (route_scope).
A scenario that spans several routes is a **group**: its host lives in a `shell/`
sub-folder (`routing/`+`view/`, plus shared `domain/`+`data/` where needed) and
the sub-features are sibling folders. This preserves the reference architecture
without mixing alternative approaches into its import graph; see
[Page composition and application architecture](../doc/page_composition.md)
for the rationale and comparison.
