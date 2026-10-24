import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/page_body.dart';
import '../widgets/product_thumb.dart';
import '../widgets/status_chip.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<MenuData> _menuFuture = productService.fetchMenu();
  String _search = '';

  Future<void> _refresh() async {
    final future = productService.fetchMenu();
    setState(() {
      _menuFuture = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  /// No product = add mode. A product = edit mode.
  Future<void> _openForm([Product? product]) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<MenuData>(
          future: _menuFuture,
          builder: (context, snapshot) {
            return PageBody(
              bottomPadding:
                  96, // room so the last row isn't hidden behind the button
              children: [
                TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                if (snapshot.hasData)
                  _buildProducts(snapshot.data!)
                else if (snapshot.hasError)
                  Center(
                    child: TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Couldn't load products. Tap to retry"),
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

  Widget _buildProducts(MenuData menu) {
    final query = _search.trim().toLowerCase();
    final products = menu.products
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
    final categoryNames = {for (final c in menu.categories) c.id: c.name};

    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No products match your search.')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return Card(
          child: Column(
            children: [
              if (wide) const _TableHeader(),
              for (final (i, product) in products.indexed) ...[
                if (i > 0 || wide) const Divider(),
                wide
                    ? _TableRow(
                        product: product,
                        category: categoryNames[product.categoryId],
                        onTap: () => _openForm(product),
                      )
                    : _ListRow(
                        product: product,
                        category: categoryNames[product.categoryId],
                        onTap: () => _openForm(product),
                      ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Phone: compact two-line rows.
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.product,
    required this.category,
    required this.onTap,
  });
  final VoidCallback onTap;

  final Product product;
  final String? category;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ProductThumb(product: product),
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(category ?? 'No category'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatPrice(product.price),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          StatusChip(available: product.isAvailable),
        ],
      ),
    );
  }
}

/// Wide screens: aligned columns, like a spreadsheet.
/// The flex numbers MUST match between header and rows, so columns line up.
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AdminColors.muted,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('PRODUCT', style: style)),
          Expanded(flex: 2, child: Text('CATEGORY', style: style)),
          Expanded(
            flex: 2,
            child: Text('PRICE', style: style, textAlign: TextAlign.right),
          ),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.product,
    required this.category,
    required this.onTap,
  });

  final Product product;
  final String? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  ProductThumb(product: product, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (product.description != null)
                          Text(
                            product.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdminColors.muted,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(category ?? '—')),
            Expanded(
              flex: 2,
              child: Text(
                formatPrice(product.price),
                textAlign:
                    TextAlign.right, // numbers align right so digits line up
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusChip(available: product.isAvailable),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
