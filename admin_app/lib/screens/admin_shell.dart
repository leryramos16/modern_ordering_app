import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../theme/app_theme.dart';
import 'categories_screen.dart';
import 'overview_screen.dart';
import 'products_screen.dart';
import 'orders_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.user});

  final User user;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  // One list drives ALL three navigation styles, so they can never get out of sync.
  static const _destinations = [
    (
      icon: Icons.space_dashboard_outlined,
      selected: Icons.space_dashboard,
      label: 'Overview',
    ),
    (
      icon: Icons.receipt_long_outlined,
      selected: Icons.receipt_long,
      label: 'Orders',
    ),
    (
      icon: Icons.inventory_2_outlined,
      selected: Icons.inventory_2,
      label: 'Products',
    ),
    (
      icon: Icons.category_outlined,
      selected: Icons.category,
      label: 'Categories',
    ),
  ];

  void _goTo(int index) => setState(() => _index = index);

  Widget _page() => switch (_index) {
    0 => OverviewScreen(user: widget.user, onNavigate: _goTo),
    1 => const OrdersScreen(),
    2 => const ProductsScreen(),
    _ => const CategoriesScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    // PHONE: bottom navigation bar
    if (width < 600) {
      return Scaffold(
        body: _page(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goTo,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selected),
                label: d.label,
              ),
          ],
        ),
      );
    }

    // TABLET: icon rail.  LAPTOP: full sidebar with labels.
    final extended = width >= 1000;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            backgroundColor: AdminColors.espresso,
            indicatorColor: AdminColors.caramel,
            selectedIndex: _index,
            onDestinationSelected: _goTo,
            // When extended, labels sit next to the icons, so labelType must be "none".
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedIconTheme: IconThemeData(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            leading: _Brand(extended: extended),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: Text(d.label),
                ),
            ],
          ),
          Expanded(child: _page()),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AdminColors.caramel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_cafe, color: Colors.white),
          ),
          if (extended) ...[
            const SizedBox(width: 12),
            const Text(
              'Store Admin',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
