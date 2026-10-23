import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A scrolling page whose content stops at [maxWidth] and centers on big screens.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.maxWidth = 1100,
    this.bottomPadding = 32,
  });

  final List<Widget> children;
  final double maxWidth;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On a phone: 16px sides. On a laptop: whatever centers the content.
        final side = math.max(16.0, (constraints.maxWidth - maxWidth) / 2);
        return ListView(
          physics:
              const AlwaysScrollableScrollPhysics(), // pull-to-refresh always works
          padding: EdgeInsets.fromLTRB(side, 8, side, bottomPadding),
          children: children,
        );
      },
    );
  }
}
