import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'product_image.dart';

/// Shared by the real grid and the loading skeleton, so both line up exactly.
const productGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 220, // phone = 2 columns, tablet = 3-4 automatically
  mainAxisSpacing: 14,
  crossAxisSpacing: 14,
  childAspectRatio: 0.72, // card is taller than wide
);

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd; // tapping +

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior:
          Clip.antiAlias, // keeps the tap ripple inside the rounded corners
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  tag: 'product-${product.id}', // must match the detail screen
                  child: ProductImage(product: product),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (product.description != null)
                Text(
                  product.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    formatPrice(product.price),
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.caramel,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: AppColors.espresso,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: onAdd,
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.cream,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
