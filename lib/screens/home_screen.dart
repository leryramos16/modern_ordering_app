import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_card.dart';
import '../widgets/product_grid_skeleton.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';

/// Products and categories, loaded together.
typedef Menu = ({List<Product> products, List<ProductCategory> categories});

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Menu> _menuFuture = _loadMenu();
  int? _selectedCategoryId; // null = All
  String _search = '';

  Future<Menu> _loadMenu() async {
    // Both requests run AT THE SAME TIME, not one after the other.
    final (products, categories) = await (
      productService.fetchProducts(),
      productService.fetchCategories(),
    ).wait;
    return (products: products, categories: categories);
  }

  Future<void> _refresh() async {
    final future = _loadMenu();
    setState(() => _menuFuture = future);
    try {
      await future;
    } catch (_) {
      // the FutureBuilder shows the error
    }
  }

  Future<void> _logout(BuildContext context) async {
    await authService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  List<Product> _filter(List<Product> products) {
    final query = _search.trim().toLowerCase();
    return products.where((p) {
      final inCategory =
          _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      final matchesSearch =
          query.isEmpty || p.name.toLowerCase().contains(query);
      return inCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<Menu>(
            future: _menuFuture,
            builder: (context, snapshot) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverToBoxAdapter(child: _buildSearch()),
                  // Order matters: show old data while refreshing (no flicker),
                  // then errors, then the skeleton for the very first load.
                  if (snapshot.hasData)
                    ..._buildMenu(snapshot.data!)
                  else if (snapshot.hasError)
                    _buildMessage(
                      Icons.wifi_off_rounded,
                      "Couldn't load the menu. Pull down to try again.",
                    )
                  else
                    const ProductGridSkeleton(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final firstName = widget.user.name.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $firstName',
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  'What would you like to order today?',
                  style: textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextField(
        onChanged: (value) => setState(() => _search = value),
        decoration: const InputDecoration(
          hintText: 'Search the menu',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }

  List<Widget> _buildMenu(Menu menu) {
    final products = _filter(menu.products);
    final categoryNames = {for (final c in menu.categories) c.id: c.name};

    return [
      SliverPadding(
        padding: const EdgeInsets.only(top: 16),
        sliver: SliverToBoxAdapter(
          child: CategoryChips(
            categories: menu.categories,
            selectedId: _selectedCategoryId,
            onSelected: (id) => setState(() => _selectedCategoryId = id),
          ),
        ),
      ),
      if (products.isEmpty)
        _buildMessage(
          Icons.search_off_rounded,
          'We dont have that product yet. Try searching for something else.',
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          sliver: SliverGrid.builder(
            gridDelegate: productGridDelegate,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      product: product,
                      categoryName: categoryNames[product.categoryId],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ];
  }

  Widget _buildMessage(IconData icon, String text) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
