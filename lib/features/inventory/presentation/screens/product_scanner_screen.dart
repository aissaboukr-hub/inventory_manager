import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:inventory_manager/core/utils/barcode_scanner.dart';
import 'package:inventory_manager/core/utils/sound_player.dart';
import 'package:inventory_manager/domain/entities/product.dart';
import 'package:inventory_manager/domain/repositories/inventory_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductScannerScreen extends StatefulWidget {
  final int inventoryId;
  final Function(Product, double)? onProductScanned;

  const ProductScannerScreen({
    super.key,
    required this.inventoryId,
    this.onProductScanned,
  });

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen> {
  final BarcodeScannerService _scannerService = BarcodeScannerService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newProductCodeController = TextEditingController();
  final TextEditingController _newProductNameController = TextEditingController();
  final TextEditingController _newProductCategoryController = TextEditingController();

  MobileScannerController? _cameraController;
  bool _isScanning = true;
  bool _torchEnabled = false;
  Product? _scannedProduct;
  bool _isNewProduct = false;
  String? _lastBarcode;
  bool _isProcessing = false;
  double _quantity = 1.0;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerService.dispose();
    _cameraController?.dispose();
    _searchController.dispose();
    _newProductCodeController.dispose();
    _newProductNameController.dispose();
    _newProductCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        actions: [
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: () => setState(() => _isScanning = !_isScanning),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: _buildScanner(),
          ),
          Expanded(
            flex: 3,
            child: _buildInputSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            MobileScanner(
              controller: _cameraController!,
              onDetect: (capture) {
                if (_isScanning && !_isProcessing) {
                  _onBarcodeDetected(capture);
                }
              },
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 250,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 2,
                      color: Colors.red.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Rechercher manuellement',
              hintText: 'Code, désignation ou EAN',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _scannedProduct = null;
                    _isNewProduct = false;
                  });
                },
              ),
            ),
            onSubmitted: _searchProduct,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _scannedProduct != null
                ? _buildProductWithQuantity()
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Scannez un code-barres\nou recherchez un produit',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductWithQuantity() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Carte produit
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(_scannedProduct!.code),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      if (_scannedProduct!.barcode != null)
                        Text(
                          'EAN: ${_scannedProduct!.barcode}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _scannedProduct!.designation,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_scannedProduct!.category != null) ...[
                    const SizedBox(height: 8),
                    Text('Catégorie: ${_scannedProduct!.category}'),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Unité: ${_scannedProduct!.unit}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Section quantité optimisée mobile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Quantité',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                // Affichage de la quantité avec contrôles +/- et saisie directe
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onPressed: () => _updateQuantity(-1),
                    ),
                    const SizedBox(width: 16),
                    // Champ de saisie numérique optimisé mobile
                    Expanded(
                      child: TextField(
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: '0',
                        ),
                        controller: TextEditingController(
                          text: _quantity == _quantity.toInt()
                              ? _quantity.toInt().toString()
                              : _quantity.toStringAsFixed(2),
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null && parsed >= 0) {
                            setState(() => _quantity = parsed);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onPressed: () => _updateQuantity(1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Boutons de raccourcis rapides
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [0.5, 1, 2, 5, 10].map((value) {
                    return ActionChip(
                      label: Text(
                        value == value.toInt()
                            ? '+${value.toInt()}'
                            : '+$value',
                      ),
                      onPressed: () => setState(() => _quantity += value),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetScan,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Annuler'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _validateEntry,
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Valider',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _updateQuantity(double delta) {
    setState(() {
      final newValue = _quantity + delta;
      _quantity = newValue < 0 ? 0 : newValue;
    });
  }

  void _resetScan() {
    setState(() {
      _scannedProduct = null;
      _isNewProduct = false;
      _lastBarcode = null;
      _quantity = 1.0;
    });
    _searchController.clear();
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      setState(() => _isProcessing = false);
      return;
    }

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      await _scannerService.playBeep();
      _lastBarcode = code;

      final product = await context
          .read<InventoryRepository>()
          .getProductByBarcode(code);

      if (product != null) {
        setState(() {
          _scannedProduct = product;
          _isNewProduct = false;
          _quantity = 1.0;
          _isProcessing = false;
        });
      } else {
        setState(() => _isProcessing = false);
        // Afficher le dialogue de création de produit
        _showNewProductDialog(code);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Erreur lors de la recherche: $e');
    }
  }

  void _showNewProductDialog(String barcode) {
    // Pré-remplir le code si c'est un code produit
    _newProductCodeController.text = '';
    _newProductNameController.text = '';
    _newProductCategoryController.text = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête avec icône
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nouveau produit détecté',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        barcode,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Champs du formulaire
                TextField(
                  controller: _newProductCodeController,
                  decoration: InputDecoration(
                    labelText: 'Code produit *',
                    hintText: 'Ex: PROD-001',
                    prefixIcon: const Icon(Icons.tag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newProductNameController,
                  decoration: InputDecoration(
                    labelText: 'Désignation *',
                    hintText: 'Nom du produit',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newProductCategoryController,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    hintText: 'Optionnel',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '* Champs obligatoires',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => _createNewProduct(barcode),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Créer le produit',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createNewProduct(String barcode) async {
    final code = _newProductCodeController.text.trim();
    final name = _newProductNameController.text.trim();
    final category = _newProductCategoryController.text.trim();

    if (code.isEmpty || name.isEmpty) {
      _showError('Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      setState(() => _isProcessing = true);
      Navigator.pop(context); // Ferme le dialogue

      final newProduct = await context
          .read<InventoryRepository>()
          .createProduct(
            code: code,
            designation: name,
            barcode: barcode,
            category: category.isNotEmpty ? category : null,
            unit: 'unité', // Valeur par défaut, peut être modifiée
          );

      setState(() {
        _scannedProduct = newProduct;
        _isNewProduct = false;
        _quantity = 1.0;
        _isProcessing = false;
      });

      _showSuccess('Produit créé avec succès');
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Erreur lors de la création: $e');
    }
  }

  void _searchProduct(String query) async {
    if (query.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final products = await context
          .read<InventoryRepository>()
          .searchProducts(query, limit: 100); // Augmenté pour liste complète

      setState(() => _isProcessing = false);

      if (products.isEmpty) {
        _showNewProductDialog(query);
      } else {
        // Afficher tous les résultats dans un bottom sheet plein écran
        _showProductSelectionSheet(products);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Erreur de recherche: $e');
    }
  }

  void _showProductSelectionSheet(List<Product> products) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Poignée de drag
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // En-tête
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${products.length} résultat${products.length > 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Tapez pour sélectionner',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                // Liste complète des produits
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: products.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                product.designation.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            product.designation,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Code: ${product.code}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (product.barcode != null)
                                Text(
                                  'EAN: ${product.barcode}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (product.category != null)
                                Text(
                                  'Catégorie: ${product.category}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _scannedProduct = product;
                              _isNewProduct = false;
                              _quantity = 1.0;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _validateEntry() async {
    if (_scannedProduct == null) {
      _showError('Aucun produit sélectionné');
      return;
    }

    if (_quantity <= 0) {
      _showError('Veuillez entrer une quantité valide');
      return;
    }

    try {
      setState(() => _isProcessing = true);

      final newItem = await context
          .read<InventoryRepository>()
          .addInventoryItem(
            inventoryId: widget.inventoryId,
            productId: _scannedProduct!.id!,
            quantity: _quantity,
          );

      _showSuccess('Article ajouté: ${_quantity > 0 ? '+' : ''}$_quantity');

      if (widget.onProductScanned != null) {
        widget.onProductScanned!(_scannedProduct!, _quantity);
      }

      Navigator.pop(context, newItem);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Erreur lors de l\'ajout: $e');
    }
  }

  void _toggleTorch() {
    setState(() {
      _torchEnabled = !_torchEnabled;
      _cameraController?.toggleTorch();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}