import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../services/product_service.dart';
import '../widgets/page_body.dart';
import '../widgets/page_body.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  late final Future<List<ProductCategory>> _categoriesFuture = productService
      .fetchCategories();
  int? _categoryId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await productService.createProduct(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _categoryId!,
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true); // true = "a product was added"
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on http.ClientException {
      setState(() => _error = 'Could not reach the server');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add product')),
      body: FutureBuilder<List<ProductCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load categories'));
          }
          return _buildForm(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildForm(List<ProductCategory> categories) {
    return Form(
      key: _formKey,
      child: PageBody(
        maxWidth: 560, // forms read best narrow
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: Validators.productName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Price'),
            validator: Validators.price,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final c in categories)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (value) => setState(() => _categoryId = value),
            validator: (value) => value == null ? 'Choose a category' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Save Product'),
          ),
        ],
      ),
    );
  }
}
