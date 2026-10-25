import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../theme/app_theme.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final String status;

  /// One color per status, the same everywhere in the app.
  static Color colorOf(String status) => switch (status) {
    OrderStatus.pending => AdminColors.caramel, // needs attention!
    OrderStatus.confirmed => const Color(0xFF3A6EA5), // blue
    OrderStatus.preparing => const Color(0xFF8E5BB5), // purple
    OrderStatus.ready => AdminColors.success, // green
    OrderStatus.completed => AdminColors.muted, // grey: done
    _ => const Color(0xFFB3261E), // red: cancelled
  };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        OrderStatus.label(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
