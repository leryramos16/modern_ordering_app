import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.sage.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 56,
                    color: AppColors.sage,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Order placed!', style: textTheme.headlineMedium),
                const SizedBox(height: 8),
                // The total FROM THE SERVER: the real amount the customer will pay.
                Text(
                  'Order #${order.id} · ${formatPrice(order.total)}',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.caramel,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We've received your order. The store will confirm it soon.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DELIVER TO',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(order.deliveryAddress),
                      Text(
                        order.contactPhone,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to menu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
