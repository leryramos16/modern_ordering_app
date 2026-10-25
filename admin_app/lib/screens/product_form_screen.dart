import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_models/shared_models.dart';

import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../utils/image_url.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/page_body.dart';

/// One form, two modes: add (product == null) or edit (product != null).
/// Closes with a message for a snackbar, e.g. "Changes saved", or null if cancelled.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  late final Future<List<ProductCategory>> _categoriesFuture = productService
      .fetchCategories();
  int? _categoryId;
  Uint8List? _imageBytes; // a NEW photo picked on this screen
  String? _imageName;
  String? _existingImageUrl; // the photo already saved on the server
  bool _isAvailable = true;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    // Edit mode: fill the form with the product's current values.
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _descriptionController.text = product.description ?? '';
      _priceController.text = product.price.toStringAsFixed(2);
      _categoryId = product.categoryId;
      _existingImageUrl = product.imageUrl;
      _isAvailable = product.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Keep the current photo, unless a new one was picked.
      var imageUrl = _existingImageUrl;
      if (_imageBytes != null) {
        imageUrl = await productService.uploadImage(_imageBytes!, _imageName!);
      }

      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final description = _descriptionController.text.trim();
      final product = widget.product;

      if (product == null) {
        await productService.createProduct(
          name: name,
          price: price,
          categoryId: _categoryId!,
          description: description,
          imageUrl: imageUrl,
        );
      } else {
        await productService.updateProduct(
          id: product.id,
          name: name,
          price: price,
          categoryId: _categoryId!,
          description: description,
          imageUrl: imageUrl,
          isAvailable: _isAvailable,
        );
      }
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(product == null ? '"$name" added' : 'Changes saved');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on http.ClientException {
      setState(() => _error = 'Could not reach the server');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final product = widget.product!;
    final confirmed = await confirmDelete(
      context,
      title: 'Delete ${product.name}?',
      message: "It will be removed from the menu. This can't be undone.",
    );
    if (!confirmed) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await productService.deleteProduct(product.id);
      if (!mounted) return;
      Navigator.of(context).pop('"${product.name}" deleted');
    } on ApiException catch (e) {
      setState(
        () => _error = e.message,
      ); // e.g. "…is in past orders… hide it instead"
    } on http.ClientException {
      setState(() => _error = 'Could not reach the server');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit product' : 'Add product'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete product',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
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

  /// New photo (from memory) > saved photo (from server) > nothing.
  Widget? _preview() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    }
    final url = fullImageUrl(_existingImageUrl);
    if (url != null) return Image.network(url, fit: BoxFit.cover);
    return null;
  }

  Widget _buildImagePicker() {
    final preview = _preview();
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _saving ? null : _pickImage,
          child: preview == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: AdminColors.caramel,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add a photo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    preview,
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        tooltip: 'Remove photo',
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                _imageBytes = null;
                                _imageName = null;
                                _existingImageUrl =
                                    null; // removes the saved one too
                              }),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tap to change',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildForm(List<ProductCategory> categories) {
    return Form(
      key: _formKey,
      child: PageBody(
        maxWidth: 560,
        children: [
          _buildImagePicker(),
          const SizedBox(height: 16),
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
          if (_isEditing) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show on menu'),
              subtitle: Text(
                _isAvailable
                    ? 'Customers can see and order this'
                    : 'Hidden from customers',
              ),
              value: _isAvailable,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _isAvailable = value),
            ),
          ],
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
                : Text(_isEditing ? 'Save changes' : 'Save product'),
          ),
        ],
      ),
    );
  }
}
