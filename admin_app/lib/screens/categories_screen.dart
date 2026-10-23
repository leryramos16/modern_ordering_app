import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../services/product_service.dart';
import '../widgets/page_body.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<ProductCategory>> _categoriesFuture = productService
      .fetchCategories();

  void _refresh() {
    setState(() => _categoriesFuture = productService.fetchCategories());
  }

  Future<void> _openAddDialog() async {
    // The dialog closes with the new category, or null if the admin cancelled.
    final created = await showDialog<ProductCategory>(
      context: context,
      builder: (_) => const _AddCategoryDialog(),
    );
    if (created == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('"${created.name}" added')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: FutureBuilder<List<ProductCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text("Couldn't load categories. Tap to retry"),
              ),
            );
          }
          final categories = snapshot.data!;
          if (categories.isEmpty) {
            return const Center(
              child: Text('Add your first category to group your menu.'),
            );
          }
          return PageBody(
            maxWidth: 720,
            bottomPadding: 96,
            children: [
              Card(
                child: Column(
                  children: [
                    for (final (i, category) in categories.indexed) ...[
                      if (i > 0) const Divider(),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AdminColors.caramel.withValues(
                            alpha: 0.15,
                          ),
                          foregroundColor: AdminColors.caramel,
                          child: Text(category.name[0].toUpperCase()),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog();

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final category = await productService.createCategory(
        _nameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(category); // hand the new category back
    } on ApiException catch (e) {
      setState(() => _error = e.message); // e.g. "Rice Meals" already exists
    } on http.ClientException {
      setState(() => _error = 'Could not reach the server');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New category'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true, // keyboard opens right away
          textCapitalization:
              TextCapitalization.words, // "rice meals" → "Rice Meals"
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Rice Meals',
            errorText: _error, // the server's message shows under the field
          ),
          validator: Validators.categoryName,
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          // Your theme makes FilledButtons full-width (Size.fromHeight).
          // Inside a dialog that breaks the layout, so give this one a normal size.
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
