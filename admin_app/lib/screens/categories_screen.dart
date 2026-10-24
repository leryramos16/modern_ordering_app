import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/page_body.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<ProductCategory>> _categoriesFuture = productService
      .fetchCategories();

  void _refresh() {
    setState(() {
      _categoriesFuture = productService.fetchCategories();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// No category = add. A category = rename.
  Future<void> _openDialog([ProductCategory? category]) async {
    final saved = await showDialog<ProductCategory>(
      context: context,
      builder: (_) => _CategoryDialog(category: category),
    );
    if (saved == null || !mounted) return;
    _showMessage(
      category == null ? '"${saved.name}" added' : 'Renamed to "${saved.name}"',
    );
    _refresh();
  }

  Future<void> _delete(ProductCategory category) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete ${category.name}?',
      message: "This can't be undone.",
    );
    if (!confirmed || !mounted) return;

    try {
      await productService.deleteCategory(category.id);
      if (!mounted) return;
      _showMessage('"${category.name}" deleted');
      _refresh();
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message); // e.g. "still has 2 products…"
    } on http.ClientException {
      if (mounted) _showMessage('Could not reach the server');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
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
                        trailing: PopupMenuButton<String>(
                          tooltip: 'More',
                          onSelected: (action) => action == 'rename'
                              ? _openDialog(category)
                              : _delete(category),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'rename',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Rename'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
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

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final ProductCategory? category; // null = add, otherwise rename

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        widget.category?.name ?? ''; // rename: start with the old name
  }

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
      final name = _nameController.text.trim();
      final category = widget.category;
      final saved = category == null
          ? await productService.createCategory(name)
          : await productService.updateCategory(category.id, name);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
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
    return AlertDialog(
      title: Text(widget.category == null ? 'New category' : 'Rename category'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Rice Meals',
            errorText: _error,
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
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
