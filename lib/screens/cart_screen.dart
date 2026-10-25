import 'package:flutter/material.dart';

import '../services/cart.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your order')),
      // Rebuilds whenever the cart changes (− / + / remove).
      body: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (cart.isEmpty) return const _EmptyCart();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final line in cart.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CartLineTile(line: line),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Total', style: textTheme.titleLarge),
                  const Spacer(),
                  Text(
                    formatCents(cart.totalCents),
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.caramel,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (cart.isEmpty) return const SizedBox.shrink();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                ),
                child: Text('Checkout · ${formatCents(cart.totalCents)}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 64,
            child: ProductImage(product: product, radius: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${formatPrice(product.price)} each',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCents(line.totalCents),
                  style: const TextStyle(
                    color: AppColors.caramel,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          QuantityStepper(
            quantity: line.quantity,
            onChanged: (quantity) => cart.setQuantity(product.id, quantity),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: AppColors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              'Your order is empty',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Add something tasty from the menu.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Browse menu'),
            ),
          ],
        ),
      ),
    );
  }
}
