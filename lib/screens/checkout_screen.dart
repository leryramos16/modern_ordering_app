import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../services/cart.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _placing = false;
  String? _error;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _placing = true;
      _error = null;
    });

    try {
      final order = await orderService.placeOrder(
        lines: cart.lines,
        deliveryAddress: _addressController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        notes: _notesController.text.trim(),
      );
      cart.clear(); // only AFTER the server said yes
      if (!mounted) return;
      // Replace Cart + Checkout with the success screen; Home stays underneath.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
        (route) => route.isFirst,
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } on http.ClientException {
      setState(() {
        _error = 'Could not reach the server';
      });
    } finally {
      if (mounted) {
        setState(() {
          _placing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Deliver to', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Delivery address',
                hintText: 'House no., street, barangay, city',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: Validators.address,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone, // number keypad
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '0917 123 4567',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes for the store (optional)',
                hintText: 'Less sugar, extra rice…',
              ),
              validator: Validators.notes,
            ),
            const SizedBox(height: 28),
            Text('Order summary', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  for (final line in cart.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            '${line.quantity}×',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(line.product.name)),
                          Text(formatCents(line.totalCents)),
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
                        formatCents(cart.totalCents),
                        style: const TextStyle(
                          color: AppColors.caramel,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.payments_outlined, color: AppColors.sage),
              title: Text('Cash on delivery'),
              subtitle: Text('Pay the rider when your order arrives'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _placing ? null : _placeOrder,
            child: _placing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text('Place order · ${formatCents(cart.totalCents)}'),
          ),
        ),
      ),
    );
  }
}
