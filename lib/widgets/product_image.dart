import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_models/shared_models.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product, this.radius = 18});

  final Product product;
  final double radius;

  // Warm café colors. Each product always gets the same one (based on its id).
  static const _tileColors = [
    Color(0xFFC8742F), // caramel
    Color(0xFF7A8B6F), // sage
    Color(0xFF6B4F3A), // mocha
    Color(0xFFB5838D), // rose
  ];

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    // Material(transparency) stops ugly yellow underlines on text during Hero animations.
    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      color: _tileColors[product.id % _tileColors.length],
      alignment: Alignment.center,
      child: Text(
        product.name[0].toUpperCase(),
        style: GoogleFonts.fraunces(
          fontSize: 48,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
