import '../feature/animated/page_composition/animated_pages.dart';
import '../feature/confirm/page_composition/confirm_pages.dart';
import '../feature/detail/page_composition/detail_pages.dart';
import '../feature/editor/page_composition/editor_pages.dart';
import '../feature/home/page_composition/home_pages.dart';
import '../feature/independent_tab_stacks/detail/page_composition/mt_detail_pages.dart';
import '../feature/independent_tab_stacks/list/page_composition/mt_list_pages.dart';
import '../feature/independent_tab_stacks/shell/page_composition/multitabs_pages.dart';
import '../feature/mailbox/page_composition/mailbox_pages.dart';
import '../feature/not_found/page_composition/not_found_pages.dart';
import '../feature/picker/page_composition/picker_pages.dart';
import '../feature/route_scope/page_composition/scope_pages.dart';
import '../feature/session/page_composition/lock_pages.dart';
import '../feature/sub_routers/detail/page_composition/module_detail_pages.dart';
import '../feature/sub_routers/home/page_composition/module_home_pages.dart';
import '../feature/sub_routers/shell/page_composition/module_shell_pages.dart';
import '../feature/tabbed_stack/item_detail/page_composition/item_detail_pages.dart';
import '../feature/tabbed_stack/items/page_composition/items_pages.dart';
import '../feature/tabbed_stack/shell/page_composition/tabs_pages.dart';
import 'app_dependencies.dart';
import 'app_route_page_catalog.dart';

/// Builds the application's page catalog from feature-owned contributions.
AppRoutePageCatalog buildAppPages({required AppDependencies dependencies}) =>
    AppRoutePageCatalog([
      homePageDefinition,
      detailPageDefinition,
      animatedPageDefinition,
      buildMailboxPageDefinition(repository: dependencies.mailRepository),
      tabsPageDefinition,
      buildItemsPageDefinition(repository: dependencies.itemRepository),
      buildItemDetailPageDefinition(repository: dependencies.itemRepository),
      pickerPageDefinition,
      confirmPageDefinition,
      lockPageDefinition,
      scopePageDefinition,
      editorPageDefinition,
      multiTabsPageDefinition,
      mtListPageDefinition,
      mtDetailPageDefinition,
      moduleShellPageDefinition,
      moduleHomePageDefinition,
      moduleDetailPageDefinition,
      notFoundPageDefinition,
    ]);
