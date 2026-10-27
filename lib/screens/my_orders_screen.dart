import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/order_status_badge.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<Order>> _ordersFuture = orderService.fetchMyOrders();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Watch the status change live while this screen is open.
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel(); // every timer you start, you must stop
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = orderService.fetchMyOrders();
    setState(() {
      _ordersFuture = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final orders = snapshot.data!;
              if (orders.isEmpty) return const _NoOrders();
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _OrderCard(order: orders[index]),
              );
            }
            if (snapshot.hasError) {
              // Still a scrollable list, so pull-to-refresh works on the error too.
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(48),
                    child: Text(
                      "Couldn't load your orders. Pull down to try again.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Order #${order.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatDateTime(order.createdAt),
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          if (OrderStatus.isActive(order.status)) ...[
            const SizedBox(height: 14),
            OrderProgress(status: order.status),
          ],
          const SizedBox(height: 14),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}×',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.productName)),
                  Text(formatPrice(item.unitPrice * item.quantity)),
                ],
              ),
            ),
          const Divider(height: 20),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                formatPrice(order.total),
                style: const TextStyle(
                  color: AppColors.caramel,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoOrders extends StatelessWidget {
  const _NoOrders();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        const Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: AppColors.muted,
        ),
        const SizedBox(height: 16),
        Text(
          'No orders yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        const Text(
          'Your orders will show up here so you can track them.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Browse menu'),
        ),
      ],
    );
  }
}
