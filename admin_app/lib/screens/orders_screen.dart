import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/order_status_chip.dart';
import '../widgets/page_body.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Order>> _ordersFuture = orderService.fetchOrders();
  String _filter = 'active'; // active | completed | cancelled
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Check for new orders every 30 seconds, without anyone pulling down.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel(); // VERY important: stop the timer when leaving the screen
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = orderService.fetchOrders();
    setState(() {
      _ordersFuture = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  bool _matches(Order order) => switch (_filter) {
    'active' => OrderStatus.isActive(order.status),
    'completed' => order.status == OrderStatus.completed,
    _ => order.status == OrderStatus.cancelled,
  };

  Future<void> _open(Order order) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
    if (mounted) _refresh(); // statuses may have changed on the detail screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <Order>[];
            final activeCount = all
                .where((o) => OrderStatus.isActive(o.status))
                .length;

            return PageBody(
              maxWidth: 900,
              children: [
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'active',
                      label: Text(
                        activeCount > 0 ? 'Active ($activeCount)' : 'Active',
                      ),
                    ),
                    const ButtonSegment(
                      value: 'completed',
                      label: Text('Completed'),
                    ),
                    const ButtonSegment(
                      value: 'cancelled',
                      label: Text('Cancelled'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (selection) => setState(() {
                    _filter = selection.first;
                  }),
                ),
                const SizedBox(height: 16),
                if (snapshot.hasData)
                  ..._buildOrders(all.where(_matches).toList())
                else if (snapshot.hasError)
                  Center(
                    child: TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Couldn't load orders. Tap to retry"),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildOrders(List<Order> orders) {
    if (orders.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Text(
              switch (_filter) {
                'active' =>
                  'No active orders right now. New ones appear here automatically.',
                'completed' => 'No completed orders yet.',
                _ => 'No cancelled orders.',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminColors.muted),
            ),
          ),
        ),
      ];
    }
    return [
      for (final order in orders)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OrderCard(order: order, onTap: () => _open(order)),
        ),
    ];
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName ?? 'Customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              // "2× Tapsilog, 1× Espresso": the kitchen sees what to make at a glance
              Text(
                order.items
                    .map((i) => '${i.quantity}× ${i.productName}')
                    .join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdminColors.muted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: AdminColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo(order.createdAt),
                    style: const TextStyle(
                      color: AdminColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatPrice(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
