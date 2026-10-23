import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'product_card.dart';

class ProductGridSkeleton extends StatefulWidget {
  const ProductGridSkeleton({super.key});

  @override
  State<ProductGridSkeleton> createState() => _ProductGridSkeletonState();
}

class _ProductGridSkeletonState extends State<ProductGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true); // fade in, fade out, forever
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.4,
    end: 1,
  ).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      sliver: SliverGrid.builder(
        gridDelegate: productGridDelegate, // same shape as the real cards
        itemCount: 6,
        itemBuilder: (_, _) => FadeTransition(
          opacity: _opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.latte,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }
}
