import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_manager/domain/entities/product.dart';
import 'package:inventory_manager/domain/repositories/inventory_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddProductScreen extends StatefulWidget {
  final String? barcode;
  final Function(Product)? onProductCreated;

  const AddProductScreen({
    super.key,
    this.barcode,
    this.onProductCreated,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _designationController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController(text: 'U');

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.barcode != null) {
      _barcodeController.text = widget.barcode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _designationController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Produit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Code produit *',
                hintText: 'Ex: PROD-001',
                prefixIcon: Icon(Icons.code),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le code est obligatoire';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _designationController,
              decoration: const InputDecoration(
                labelText: 'Désignation *',
                hintText: 'Nom du produit',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La désignation est obligatoire';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Code-barres (EAN)',
                hintText: 'Scannez ou saisissez le code-barres',
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _scanBarcode,
                ),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                hintText: 'Optionnel',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unité',
                hintText: 'Ex: U, kg, L, m...',
                prefixIcon: Icon(Icons.straighten),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveProduct,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scanBarcode() {
    // TODO: Open barcode scanner to fill barcode field
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final product = await context.read<InventoryRepository>().createProduct(
        code: _codeController.text.trim().toUpperCase(),
        designation: _designationController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty 
            ? null 
            : _barcodeController.text.trim(),
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
        unit: _unitController.text.trim(),
      );

      if (widget.onProductCreated != null) {
        widget.onProductCreated!(product);
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, product);
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}