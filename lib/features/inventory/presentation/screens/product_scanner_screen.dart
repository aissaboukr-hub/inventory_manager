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
  final Function(Product, double)? onProductScanned; // ← AJOUTÉ : Callback optionnel

  const ProductScannerScreen({
    super.key, 
    required this.inventoryId,
    this.onProductScanned, // ← AJOUTÉ
  });

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen> {
  final BarcodeScannerService _scannerService = BarcodeScannerService();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _searchController = TextEditingController();
  
  MobileScannerController? _cameraController;
  bool _isScanning = true;
  bool _torchEnabled = false;
  Product? _scannedProduct;
  bool _isNewProduct = false;
  String? _lastBarcode;
  bool _isProcessing = false;

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
    _quantityController.dispose();
    _searchController.dispose();
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
            child: _isNewProduct 
                ? _buildNewProductForm() 
                : _buildProductInfo(),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              if (_isNewProduct) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isNewProduct = false;
                        _scannedProduct = null;
                        _lastBarcode = null;
                      });
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: _isNewProduct ? 1 : 2,
                child: FilledButton.icon(
                  onPressed: _validateEntry,
                  icon: Icon(_isNewProduct ? Icons.add_circle : Icons.check_circle),
                  label: Text(
                    _isNewProduct ? 'Créer et ajouter' : 'Valider',
                    style: const TextStyle(fontSize: 16),
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

  Widget _buildProductInfo() {
    if (_scannedProduct == null) {
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

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_scannedProduct!.category != null) ...[
              const SizedBox(height: 8),
              Text('Catégorie: ${_scannedProduct!.category}'),
            ],
            const SizedBox(height: 8),
            Text('Unité: ${_scannedProduct!.unit}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildNewProductForm() {
    return SingleChildScrollView(
      child: Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Text(
                    'Nouveau produit détecté',
                    style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Code-barres: $_lastBarcode', style: const TextStyle(fontFamily: 'monospace')),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Code produit *',
                  hintText: 'Ex: PROD-001',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Désignation *',
                  hintText: 'Nom du produit',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  hintText: 'Optionnel',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      
      final product = await context.read<InventoryRepository>().getProductByBarcode(code);
      
      setState(() {
        if (product != null) {
          _scannedProduct = product;
          _isNewProduct = false;
        } else {
          _isNewProduct = true;
          _scannedProduct = null;
        }
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Erreur lors de la recherche: $e');
    }
  }

  void _searchProduct(String query) async {
    if (query.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final products = await context.read<InventoryRepository>().searchProducts(query, limit: 10);
      
      if (products.isEmpty) {
        setState(() {
          _isNewProduct = true;
          _scannedProduct = null;
          _lastBarcode = query;
        });
      } else if (products.length == 1) {
        setState(() {
          _scannedProduct = products.first;
          _isNewProduct = false;
        });
      } else {
        if (!mounted) return;
        final selected = await showDialog<Product>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sélectionner un produit'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return ListTile(
                    title: Text(p.designation),
                    subtitle: Text('${p.code} ${p.barcode != null ? '• EAN: ${p.barcode}' : ''}'),
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          ),
        );
        
        if (selected != null) {
          setState(() {
            _scannedProduct = selected;
            _isNewProduct = false;
          });
        }
      }
    } catch (e) {
      _showError('Erreur de recherche: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _updateQuantity(double delta) {
    final current = double.tryParse(_quantityController.text) ?? 0;
    final newValue = current + delta;
    _quantityController.text = newValue == newValue.toInt() 
        ? newValue.toInt().toString() 
        : newValue.toStringAsFixed(2);
  }

  // ✅ CORRIGÉ : Ajout du callback et retour à l'écran précédent
  void _validateEntry() async {
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity == 0) {
      _showError('Veuillez entrer une quantité valide');
      return;
    }

    if (_isNewProduct) {
      _showError('Veuillez créer le produit d\'abord');
      return;
    }

    if (_scannedProduct == null) {
      _showError('Aucun produit sélectionné');
      return;
    }

    try {
      // Ajouter l'article à l'inventaire
      final newItem = await context.read<InventoryRepository>().addInventoryItem(
        inventoryId: widget.inventoryId,
        productId: _scannedProduct!.id!,
        quantity: quantity,
      );

      _showSuccess('Article ajouté: ${quantity > 0 ? '+' : ''}$quantity');

      // ✅ APPEL DU CALLBACK si défini
      if (widget.onProductScanned != null) {
        widget.onProductScanned!(_scannedProduct!, quantity);
      }

      // ✅ RETOURNER L'ITEM À L'ÉCRAN PRÉCÉDENT
      Navigator.pop(context, newItem);

    } catch (e) {
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
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
    );
  }
}