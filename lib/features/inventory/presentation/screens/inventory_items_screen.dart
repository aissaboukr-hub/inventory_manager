import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventory_manager/domain/entities/inventory_item.dart';
import 'package:inventory_manager/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:inventory_manager/features/inventory/presentation/screens/product_scanner_screen.dart';

class InventoryItemsScreen extends StatelessWidget {
  final int inventoryId;
  final String inventoryName;

  const InventoryItemsScreen({
    super.key,
    required this.inventoryId,
    required this.inventoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(inventoryName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _openScanner(context),
          ),
        ],
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InventoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Erreur: ${state.message}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      context.read<InventoryBloc>().add(
                        LoadInventoryItemsEvent(inventoryId),
                      );
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is InventoryLoaded && state.inventoryId == inventoryId) {
            if (state.items.isEmpty) {
              return _EmptyItemsView(
                onScan: () => _openScanner(context),
              );
            }

            return _ItemsListView(
              items: state.items,
              inventoryId: inventoryId,
            );
          }

          // Chargement initial
          context.read<InventoryBloc>().add(LoadInventoryItemsEvent(inventoryId));
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScanner(context),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scanner'),
      ),
    );
  }

  void _openScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductScannerScreen(
          inventoryId: inventoryId,
	  onProductScanned: (product, quantity) {
          // ✅ RAFRAÎCHIR IMMÉDIATEMENT
          context.read<InventoryBloc>().add(LoadInventoryItemsEvent(inventoryId));
          },
        ),
      ),
    ).then((_) {
   	 // ✅ RAFRAÎCHIR AUSSI AU RETOUR (backup)
   	 if (result != null) {
      context.read<InventoryBloc>().add(LoadInventoryItemsEvent(inventoryId));
    	}
    });
  }
}

class _ItemsListView extends StatelessWidget {
  final List<InventoryItem> items;
  final int inventoryId;

  const _ItemsListView({
    required this.items,
    required this.inventoryId,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return RefreshIndicator(
      onRefresh: () async {
        context.read<InventoryBloc>().add(RefreshInventoryItemsEvent(inventoryId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: item.quantity > 0 
                    ? Colors.green.shade100 
                    : Colors.red.shade100,
                child: Icon(
                  item.quantity > 0 ? Icons.check : Icons.warning,
                  color: item.quantity > 0 
                      ? Colors.green.shade700 
                      : Colors.red.shade700,
                ),
              ),
              title: Text(
                item.product?.designation ?? 'Produit #${item.productId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code: ${item.product?.code ?? 'N/A'}'),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Text('Note: ${item.notes}'),
                  Text(
                    'Ajouté le: ${dateFormat.format(item.timestamp)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: Text(
                '${item.quantity.toStringAsFixed(2)} ${item.product?.unit ?? 'U'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              onTap: () => _showItemOptions(context, item),
            ),
          );
        },
      ),
    );
  }

  void _showItemOptions(BuildContext context, InventoryItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier la quantité'),
              onTap: () {
                Navigator.pop(context);
                _showEditQuantityDialog(context, item);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red[400]),
              title: Text('Supprimer', style: TextStyle(color: Colors.red[400])),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditQuantityDialog(BuildContext context, InventoryItem item) {
    final controller = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la quantité'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Quantité',
            suffixText: 'unités',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final newQuantity = double.tryParse(controller.text);
              if (newQuantity != null) {
                context.read<InventoryBloc>().add(
                  UpdateInventoryItemEvent(
                    item.copyWith(quantity: newQuantity),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet article ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${item.product?.designation ?? 'cet article'}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (item.id != null) {
                context.read<InventoryBloc>().add(
                  DeleteInventoryItemEvent(item.id!),
                );
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _EmptyItemsView extends StatelessWidget {
  final VoidCallback onScan;

  const _EmptyItemsView({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun article',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cet inventaire est vide.\nScannez des produits pour commencer.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scanner un produit'),
          ),
        ],
      ),
    );
  }
}