import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../theme/app_theme.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ProductCategory> categories;
  final int? selectedId; // null = "All"
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(int?, String)>[
      (null, 'All'),
      for (final c in categories) (c.id, c.name),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (id, label) = items[index];
          final selected = id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.espresso : Colors.white,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(
                  color: selected ? AppColors.espresso : AppColors.latte,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.cream : AppColors.espresso,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
