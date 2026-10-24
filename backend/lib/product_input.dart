import 'package:backend/uploads.dart';
import 'package:shared_models/shared_models.dart';

/// A product's editable fields, already checked and cleaned.
typedef ProductInput = ({
  String name,
  String? description,
  double price,
  int categoryId,
  String? imageUrl,
  bool isAvailable,
});

/// Reads a product from a request body.
/// Returns (input, null) when valid, or (null, 'error message') when not.
(ProductInput?, String?) readProductInput(Map<String, dynamic> body) {
  final name = (body['name'] as String? ?? '').trim();
  final description = (body['description'] as String? ?? '').trim();
  final priceText = body['price']?.toString();
  final categoryId = body['categoryId'] as int?;
  final imageUrl = (body['imageUrl'] as String? ?? '').trim();
  final isAvailable = body['isAvailable'] as bool? ?? true;

  final error =
      Validators.productName(name) ??
      Validators.price(priceText) ??
      (categoryId == null ? 'Choose a category' : null) ??
      imageUrlError(imageUrl);
  if (error != null) return (null, error);

  final input = (
    name: name,
    description: description.isEmpty ? null : description,
    price: double.parse(priceText!),
    categoryId: categoryId!,
    imageUrl: imageUrl.isEmpty ? null : imageUrl,
    isAvailable: isAvailable,
  );
  return (input, null);
}
