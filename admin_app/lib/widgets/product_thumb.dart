import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.product, this.size = 44});

  final Product product;
  final double size;

  // Same colors and same `id % 4` rule as the customer app's ProductImage.
  static const _tileColors = [
    Color(0xFFC8742F),
    Color(0xFF7A8B6F),
    Color(0xFF6B4F3A),
    Color(0xFFB5838D),
  ];

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox.square(
        dimension: size,
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _letter(),
              )
            : _letter(),
      ),
    );
  }

  Widget _letter() {
    return ColoredBox(
      color: _tileColors[product.id % _tileColors.length],
      child: Center(
        child: Text(
          product.name[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.4, // letter scales with the tile
          ),
        ),
      ),
    );
  }
}
