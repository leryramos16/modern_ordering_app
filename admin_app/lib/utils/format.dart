String formatPrice(double price) => '₱${price.toStringAsFixed(2)}';

/// "Just now", "5 min ago", "2 h ago", "3 d ago"
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}

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
  final t = time.toLocal(); // UTC from the server → local time
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0'); // 5 → "05"
  final period = t.hour < 12 ? 'AM' : 'PM';
  return '${months[t.month - 1]} ${t.day}, $hour:$minute $period';
}
