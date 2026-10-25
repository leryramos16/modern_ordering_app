abstract final class OrderStatus {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const preparing = 'preparing';
  static const ready = 'ready';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  /// The statuses an order is allowed to move to next.
  static List<String> nextOf(String status) => switch (status) {
    pending => [confirmed, cancelled],
    confirmed => [preparing, cancelled],
    preparing => [ready, cancelled],
    ready => [completed],
    _ => const [], // completed and cancelled are final
  };

  /// Still needs work from the store?
  static bool isActive(String status) =>
      status != completed && status != cancelled;

  /// Friendly words for the screen.
  static String label(String status) => switch (status) {
    pending => 'New',
    confirmed => 'Confirmed',
    preparing => 'Preparing',
    ready => 'Ready',
    completed => 'Completed',
    cancelled => 'Cancelled',
    _ => status,
  };
}
