import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../theme/app_theme.dart';

/// Customer-friendly words. Same status, different audience than the admin app.
String customerStatusLabel(String status) => switch (status) {
  OrderStatus.pending => 'Waiting for confirmation',
  OrderStatus.confirmed => 'Confirmed',
  OrderStatus.preparing => 'Being prepared',
  OrderStatus.ready => 'Ready for delivery',
  OrderStatus.completed => 'Delivered',
  OrderStatus.cancelled => 'Cancelled',
  _ => status,
};

Color _colorOf(String status) => switch (status) {
  OrderStatus.completed => AppColors.sage,
  OrderStatus.cancelled => const Color(0xFFB3261E),
  _ => AppColors.caramel, // still in progress
};

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        customerStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// ▰▰▰▱  A 4-step bar for orders still in progress.
class OrderProgress extends StatelessWidget {
  const OrderProgress({super.key, required this.status});

  final String status;

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.ready,
  ];

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexOf(status); // 0..3 (or -1 if not in progress)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= current ? AppColors.caramel : AppColors.latte,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Step ${current + 1} of ${_steps.length}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}
