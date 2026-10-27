String formatPrice(double price) => '₱${price.toStringAsFixed(2)}';

int toCents(double price) => (price * 100).round();

String formatCents(int cents) => formatPrice(cents / 100);

/// "Oct 25, 11:21 AM", in the phone's own time zone
String formatDateTime(DateTime time) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final t = time.toLocal();
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.hour < 12 ? 'AM' : 'PM';
  return '${months[t.month - 1]} ${t.day}, $hour:$minute $period';
}
