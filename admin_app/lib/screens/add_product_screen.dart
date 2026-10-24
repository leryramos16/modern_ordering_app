import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../services/product_service.dart';
import '../widgets/page_body.dart';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

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
  Uint8List? _imageBytes; // the chosen photo, kept in memory until Save
  String? _imageName;
  bool _saving = false;
  String? _error;

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
      maxWidth: 1200, // shrink big phone photos ON the phone…
      maxHeight: 1200,
      imageQuality: 80, // …and compress them, so uploads are fast and small
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
      String? imageUrl;
      if (_imageBytes != null) {
        imageUrl = await productService.uploadImage(_imageBytes!, _imageName!);
      }
      await productService.createProduct(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _categoryId!,
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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

  Widget _buildImagePicker() {
    final bytes = _imageBytes;
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
          child: bytes == null
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
                    Text(
                      'JPG, PNG or WebP · up to 5 MB',
                      style: TextStyle(color: AdminColors.muted, fontSize: 12),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                    ), // preview before uploading
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
        maxWidth: 560, // forms read best narrow
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
