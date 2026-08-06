import '../routing/tabs_tab.dart';
import '../../settings/view/settings_screen.dart';
import 'package:flutter/material.dart';

/// Tabbed shell with **one shared AppBar** for both tabs and the Items tab's
/// nested stack. The active tab comes from the route (URL + deep link);
/// `IndexedStack` keeps both tabs mounted. [title] and [onBack] are derived from
/// the route by `TabsRoute`, since this AppBar sits outside the nested navigator
/// and gets no automatic back arrow.
class TabsShell extends StatelessWidget {
  const TabsShell({
    required this.title,
    required this.activeTab,
    required this.onSelectTab,
    required this.onBack,
    required this.itemsTab,
    super.key,
  });

  final String title;
  final TabsTab activeTab;
  final ValueChanged<TabsTab> onSelectTab;
  final VoidCallback onBack;
  final Widget itemsTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: BackButton(onPressed: onBack),
      ),
      body: IndexedStack(
        index: activeTab.index,
        children: [itemsTab, const SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab.index,
        onDestinationSelected: (index) => onSelectTab(TabsTab.values[index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Items'),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
