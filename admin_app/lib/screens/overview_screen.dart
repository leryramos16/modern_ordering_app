import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/page_body.dart';
import '../widgets/product_thumb.dart';
import '../widgets/stat_card.dart';
import 'product_form_screen.dart';
import 'login_screen.dart';
import '../services/order_service.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({
    super.key,
    required this.user,
    required this.onNavigate,
  });

  final User user;
  final ValueChanged<int> onNavigate; // lets this page switch tabs in the shell

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late Future<(MenuData, List<Order>)> _future = _load();

  Future<(MenuData, List<Order>)> _load() =>
      (productService.fetchMenu(), orderService.fetchOrders()).wait;

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  Future<void> _logout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _addProduct() async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      _refresh();
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (_) => _logout(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Log out'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AdminColors.caramel,
                child: Text(
                  widget.user.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<(MenuData, List<Order>)>(
          future: _future,
          builder: (context, snapshot) {
            return PageBody(
              children: [
                Text(
                  '${_greeting()}, ${widget.user.name.split(' ').first}',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Here's how your store looks today.",
                  style: textTheme.bodyMedium?.copyWith(
                    color: AdminColors.muted,
                  ),
                ),
                const SizedBox(height: 20),
                if (snapshot.hasData)
                  ..._buildContent(snapshot.data!.$1, snapshot.data!.$2)
                else if (snapshot.hasError)
                  Center(
                    child: TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        "Couldn't load your store. Tap to retry",
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildContent(MenuData menu, List<Order> orders) {
    final now = DateTime.now();
    final ordersToday = orders.where((o) {
      final t = o.createdAt.toLocal();
      return t.year == now.year &&
          t.month == now.month &&
          t.day == now.day &&
          o.status != OrderStatus.cancelled;
    }).length;
    final waiting = orders.where((o) => o.status == OrderStatus.pending).length;
    final products = menu.products;
    final average = products.isEmpty
        ? null
        : products.map((p) => p.price).reduce((a, b) => a + b) /
              products.length;
    final categoryNames = {for (final c in menu.categories) c.id: c.name};
    // Newest first: a higher id means it was added later.
    final recent = [...products]..sort((a, b) => b.id.compareTo(a.id));

    return [
      _StatsGrid(
        cards: [
          StatCard(
            icon: Icons.inventory_2_outlined,
            label: 'Products on menu',
            value: '${products.length}',
          ),
          StatCard(
            icon: Icons.category_outlined,
            label: 'Categories',
            value: '${menu.categories.length}',
            color: AdminColors.success,
          ),
          StatCard(
            icon: Icons.payments_outlined,
            label: 'Average price',
            value: average == null ? '—' : formatPrice(average),
            color: AdminColors.espresso,
          ),
          StatCard(
            icon: Icons.receipt_long_outlined,
            label: 'Orders today',
            value: '$ordersToday',
            hint: waiting > 0 ? '$waiting waiting for you' : 'All caught up',
            color: AdminColors.caramel,
          ),
        ],
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: _addProduct,
            icon: const Icon(Icons.add),
            label: const Text('Add product'),
          ),
          OutlinedButton.icon(
            onPressed: () => widget.onNavigate(3),
            icon: const Icon(Icons.category_outlined),
            label: const Text('Manage categories'),
          ),
        ],
      ),
      const SizedBox(height: 28),
      Row(
        children: [
          Text(
            'Recently added',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => widget.onNavigate(2),
            child: const Text('View all'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Card(
        child: Column(
          children: [
            for (final (i, product) in recent.take(5).indexed) ...[
              if (i > 0) const Divider(),
              ListTile(
                leading: ProductThumb(product: product),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  categoryNames[product.categoryId] ?? 'No category',
                ),
                trailing: Text(
                  formatPrice(product.price),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Add your first product to start your menu.'),
              ),
          ],
        ),
      ),
    ];
  }
}

/// 2 columns on narrow screens, 4 on wide ones.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 840 ? 4 : 2;
        // floorToDouble avoids tiny rounding errors pushing a card to the next line
        final cardWidth =
            ((constraints.maxWidth - gap * (columns - 1)) / columns)
                .floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}
