# rolter example

A small app exercising the [`rolter`](../) routing engine end to end. Every
scenario on the home screen maps to one typed route in the catalog.

The catalog is organised **feature-first**: each feature owns its routes,
screens, wire-name enum, decoder contribution, and navigation sugar; `routing/`
holds the shared core and the composition root that aggregates them. (See the
package README for the monolithic `sealed` alternative for small apps.)

## Run

```bash
cd example
flutter run            # or: -d macos / -d chrome
```

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

The engine is page-agnostic, so a route's `buildPage` may return any `Page`:

- `NoAnimationPage` (engine) — the lock screen appears instantly on redirect.
- `NoAnimationTransitionDelegate` (engine) — the whole Items tab switches with
  no slide (passed to its `NestedNavigatorHost.transitionDelegate`).
- `TransparentPage` (engine) — the confirm dialog (scrim + dismissible).
- `TransitionPage` (engine) — the "Custom transition" tile: a slide-up + fade
  built by passing a `transitionsBuilder`, with no custom `Page` subclass.

## Nested navigation & the AppBar

The engine never imposes a `Scaffold`/`AppBar`; `buildPage` returns any widget,
so the AppBar is entirely the app's choice — pick a strategy by where you place
`Scaffold(appBar:)`:

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
  main.dart      entry point — runApp(ExampleApp())
  app.dart       ExampleApp: the root widget (wires the engine + AppScope)
  core/
    routing/     app_route (base), app_navigator, app_registry (composition root),
                 nav_log_observer — the app-wide routing layer
    di/          app_dependencies + app_scope — the app-wide DI container
  feature/
    home/ detail/ animated/ picker/ confirm/ route_scope/ editor/
    session/ mailbox/ not_found/
    tabbed_stack/           Tabs + nested stack — shell/ (host) + shared/ (item
                            domain/ data/) + items/ item_detail/ settings/
    independent_tab_stacks/ each tab keeps its own stack — shell/ + list/ detail/
    sub_routers/            mounted feature sub-routers — shell/ + home/ detail/
```

`core/` holds the app-wide routing and DI (including the registry that composes
every feature), `app.dart` is the root widget, and each `feature/` owns its routes
(`routing/`), screens (`view/`), and any state. State holders sit by approach:
`bloc/` for a `Bloc` (session), `controller/` for a `ChangeNotifier` (route_scope).
A scenario that spans several routes is a **group**: its host lives in a `shell/`
sub-folder (`routing/`+`view/`, plus shared `domain/`+`data/` where needed) and
the sub-features are sibling folders. This mirrors the reference architecture
(`core/` + `feature/` + top-level `app.dart`); see the package README's
"Organising the catalog" for the rationale.
