import 'package:flutter/material.dart';

import '../services/cart.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class CartBar extends StatelessWidget {
  const CartBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          color: AppColors.espresso,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.caramel,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'View cart',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatCents(cart.totalCents),
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.cream,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
