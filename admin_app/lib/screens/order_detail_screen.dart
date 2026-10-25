import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../services/order_service.dart';
import '../services/product_service.dart' show ApiException;
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/order_status_chip.dart';
import '../widgets/page_body.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _order =
      widget.order; // replaced with the server's version after each change
  bool _updating = false;
  String? _error;

  /// The button text for moving to each status.
  String _actionLabel(String status) => switch (status) {
    OrderStatus.confirmed => 'Confirm order',
    OrderStatus.preparing => 'Start preparing',
    OrderStatus.ready => 'Mark as ready',
    OrderStatus.completed => 'Complete order',
    _ => OrderStatus.label(status),
  };

  Future<void> _setStatus(String status) async {
    if (status == OrderStatus.cancelled) {
      final confirmed = await confirmDelete(
        context,
        title: 'Cancel order #${_order.id}?',
        message:
            "The customer's order will be cancelled. This can't be undone.",
        confirmLabel: 'Cancel order',
      );
      if (!confirmed) return;
    }

    setState(() {
      _updating = true;
      _error = null;
    });

    try {
      final updated = await orderService.updateStatus(_order.id, status);
      if (!mounted) return;
      setState(() {
        _order = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order #${_order.id} is now ${OrderStatus.label(status)}',
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message; // e.g. "just updated by someone else"
      });
    } on http.ClientException {
      setState(() {
        _error = 'Could not reach the server';
      });
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.id}')),
      body: PageBody(
        maxWidth: 720,
        children: [
          Row(
            children: [
              OrderStatusChip(status: order.status),
              const SizedBox(width: 8),
              Text(
                formatDateTime(order.createdAt),
                style: const TextStyle(color: AdminColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Customer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName ?? 'Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.phone_outlined, text: order.contactPhone),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: order.deliveryAddress,
                ),
                if (order.notes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.caramel.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Note: ${order.notes}'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Items',
            child: Column(
              children: [
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                const Divider(height: 24),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AdminColors.caramel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Cash on delivery',
                    style: TextStyle(color: AdminColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _buildActions(),
    );
  }

  /// Only the buttons that make sense for the CURRENT status.
  Widget? _buildActions() {
    final next = OrderStatus.nextOf(_order.status);
    if (next.isEmpty) return null; // completed or cancelled: nothing to do

    final canCancel = next.contains(OrderStatus.cancelled);
    final forward = next.where((s) => s != OrderStatus.cancelled).firstOrNull;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (canCancel)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: const Size(0, 48),
                ),
                onPressed: _updating
                    ? null
                    : () => _setStatus(OrderStatus.cancelled),
                child: const Text('Cancel'),
              ),
            if (canCancel && forward != null) const SizedBox(width: 12),
            if (forward != null)
              Expanded(
                child: FilledButton(
                  onPressed: _updating ? null : () => _setStatus(forward),
                  child: _updating
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(_actionLabel(forward)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AdminColors.muted,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AdminColors.muted),
        const SizedBox(width: 8),
        Expanded(child: SelectableText(text)), // long-press to copy
      ],
    );
  }
}
