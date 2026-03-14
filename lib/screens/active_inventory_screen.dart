import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../models/inventory.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';
import '../core/theme.dart';
import '../widgets/quantity_numpad.dart';
import '../widgets/product_search_delegate.dart';
import '../services/export_service.dart';

class ActiveInventoryScreen extends StatefulWidget {
  final Inventory inventory;
  const ActiveInventoryScreen({super.key, required this.inventory});

  @override
  State<ActiveInventoryScreen> createState() => _ActiveInventoryScreenState();
}

class _ActiveInventoryScreenState extends State<ActiveInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MobileScannerController _scannerController =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _scannerActive = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invProvider = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inventory.name),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scanner'),
            Tab(icon: Icon(Icons.list_alt), text: 'Saisies'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(context),
            tooltip: 'Rechercher un produit',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _export(context),
            tooltip: 'Exporter',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ScannerTab(
            controller: _scannerController,
            active: _scannerActive,
            processing: _processing,
            onDetect: _onBarcode,
            onManualAdd: () => _showManualAdd(context),
          ),
          _EntriesTab(
            entries: invProvider.activeEntries,
            onDelete: (id) => invProvider.deleteEntry(id),
            onEdit: (entry) => _editQuantity(context, entry.id, entry.quantity),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showManualAdd(context),
        tooltip: 'Ajouter manuellement',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _onBarcode(String barcode) async {
    if (_processing) return;
    setState(() => _processing = true);

    HapticFeedback.mediumImpact();
    final productProvider = context.read<ProductProvider>();
    final product = await productProvider.findByBarcode(barcode);

    if (!mounted) return;

    if (product != null) {
      await _showQuantityDialog(context, product: product, barcode: barcode);
    } else {
      _showProductNotFound(context, barcode: barcode);
    }
    setState(() => _processing = false);
  }

  Future<void> _showQuantityDialog(
    BuildContext context, {
    required Product product,
    required String barcode,
  }) async {
    final quantity = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuantityNumpad(
        productName: product.designation,
        productCode: product.code,
      ),
    );
    if (quantity != null && mounted) {
      final invProvider = context.read<InventoryProvider>();
      await invProvider.addEntry(
        productCode: product.code,
        designation: product.designation,
        barcode: barcode,
        quantity: quantity,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${product.designation} — $quantity ajouté'),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _showProductNotFound(BuildContext context, {required String barcode}) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.orange, size: 48),
        title: const Text('Produit non trouvé'),
        content: Text('Code-barres :\n$barcode\n\nProduit inconnu dans la base locale.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showManualAdd(context, barcode: barcode);
            },
            child: const Text('Ajouter manuellement'),
          ),
        ],
      ),
    );
  }

  void _showManualAdd(BuildContext context, {String barcode = ''}) {
    final codeCtrl = TextEditingController();
    final desigCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController(text: barcode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ajouter un produit',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              decoration:
                  const InputDecoration(labelText: 'Code produit *'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: desigCtrl,
              decoration:
                  const InputDecoration(labelText: 'Désignation *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: barcodeCtrl,
              decoration:
                  const InputDecoration(labelText: 'Code-barres'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.isEmpty || desigCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                final product = Product(
                  code: codeCtrl.text.trim(),
                  designation: desigCtrl.text.trim(),
                  barcode: barcodeCtrl.text.trim(),
                );
                await context.read<ProductProvider>().saveProduct(product);
                if (context.mounted) {
                  await _showQuantityDialog(
                    context,
                    product: product,
                    barcode: product.barcode,
                  );
                }
              },
              child: const Text('Ajouter et saisir la quantité'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: ProductSearchDelegate(
        onProductSelected: (product) =>
            _showQuantityDialog(context, product: product, barcode: product.barcode),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final result = await ExportService.instance.exportToExcel(
      inventoryId: widget.inventory.id,
      inventoryName: widget.inventory.name,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? AppTheme.success : AppTheme.error,
      ));
    }
  }

  void _editQuantity(
      BuildContext context, String entryId, double currentQty) async {
    final quantity = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuantityNumpad(
        productName: 'Modifier la quantité',
        initialValue: currentQty,
      ),
    );
    if (quantity != null) {
      await context.read<InventoryProvider>().updateEntryQuantity(entryId, quantity);
    }
  }
}
