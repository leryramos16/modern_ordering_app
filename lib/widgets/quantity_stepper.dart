import 'package:flutter/material.dart';

import '../services/cart.dart';
import '../theme/app_theme.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: quantity == 1 ? 'Remove' : 'Less',
            // At 1, the minus becomes a trash icon: one more tap removes it.
            icon: Icon(
              quantity == 1 ? Icons.delete_outline : Icons.remove_rounded,
            ),
            onPressed: () => onChanged(quantity - 1),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'More',
            icon: const Icon(Icons.add_rounded),
            // Disabled (greyed out) at the limit, so customers see why it stopped.
            onPressed: quantity >= CartController.maxQuantity
                ? null
                : () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}
