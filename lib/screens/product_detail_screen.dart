import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/product_image.dart';
import '../services/cart.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.categoryName,
  });

  final Product product;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppColors.cream,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.espresso,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag:
                    'product-${product.id}', // same tag as the card → it "flies" here
                child: ProductImage(product: product, radius: 0),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (categoryName != null)
                    Text(
                      categoryName!.toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.sage,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(product.name, style: textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    formatPrice(product.price),
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.caramel,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    product.description ?? 'No description yet.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                      height:
                          1.6, // line spacing makes paragraphs easier to read
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: FilledButton(
            onPressed: () {
              cart.add(product);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added to your order'),
                    action: SnackBarAction(
                      label: 'View cart',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
                    ),
                  ),
                );
            },
            child: Text('Add to order · ${formatPrice(product.price)}'),
          ),
        ),
      ),
    );
  }
}
