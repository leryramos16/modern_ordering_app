String formatPrice(double price) => '₱${price.toStringAsFixed(2)}';

int toCents(double price) => (price * 100).round();

String formatCents(int cents) => formatPrice(cents / 100);
