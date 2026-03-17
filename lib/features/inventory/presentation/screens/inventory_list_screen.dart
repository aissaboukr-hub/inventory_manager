import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/config/routes.dart';
import 'package:inventory_manager/domain/entities/inventory.dart';
import 'package:inventory_manager/domain/entities/inventory_item.dart';
import 'package:inventory_manager/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:inventory_manager/domain/repositories/inventory_repository.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class InventoryListScreen extends StatelessWidget {
  final Inventory inventory;

  const InventoryListScreen({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InventoryBloc(
        repository: context.read<InventoryRepository>(),
      )..add(LoadInventoryItemsEvent(inventory.id)),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(inventory.name),
              Text(
                '${inventory.itemCount ?? 0} articles',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: InventorySearchDelegate(
                    inventoryId: inventory.id,
                    repository: context.read<InventoryRepository>(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptions(context),
            ),
          ],
        ),
        body: const _ItemsList(),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'scan',
              onPressed: () => _openScanner(context),
              child: const Icon(Icons.qr_code_scanner),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              heroTag: 'add',
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _openScanner(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.scanner,
      arguments: inventory.id,
    );
  }

  void _showAddItemDialog(BuildContext context) {
    // TODO: Show manual add dialog
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.summarize_outlined),
              title: const Text('Voir les totaux'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showSummary(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Exporter Excel'),
              onTap: () {
                Navigator.pop(sheetContext);
                _exportToExcel(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Envoyer vers Google Sheets'),
              onTap: () {
                Navigator.pop(sheetContext);
                _exportToGoogleSheets(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Supprimer', style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(sheetContext);
                // TODO: Delete confirmation
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSummary(BuildContext context) {
    // TODO: Navigate to summary screen
  }

  void _exportToExcel(BuildContext context) {
    // TODO: Show export dialog
  }

  void _exportToGoogleSheets(BuildContext context) {
    // TODO: Show Google Sheets export
  }
}

class _ItemsList extends StatelessWidget {
  const _ItemsList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return const _LoadingShimmer();
        }

        if (state is InventoryError) {
          return _ErrorView(message: state.message);
        }

        if (state is InventoryLoaded) {
          if (state.items.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<InventoryBloc>().add(
                RefreshInventoryItemsEvent(state.inventoryId),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _ItemCard(
                  item: item,
                  onEdit: () => _editItem(context, item),
                  onDelete: () => _deleteItem(context, item),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _editItem(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditItemDialog(item: item),
    );
  }

  void _deleteItem(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette entrée ?'),
        content: Text(
          '${item.product?.designation}\n'
          'Quantité: ${item.quantity}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              context.read<InventoryBloc>().add(
                DeleteInventoryItemEvent(item.id!),
              );
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isNegative = item.quantity < 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isNegative 
                ? Colors.red.shade50 
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isNegative ? Colors.red : null,
              ),
            ),
          ),
        ),
        title: Text(
          item.product?.designation ?? 'Produit inconnu',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${item.product?.code ?? '-'}'),
            if (item.product?.barcode != null)
              Text('EAN: ${item.product!.barcode}'),
            Text(
              dateFormat.format(item.timestamp),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red.shade400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditItemDialog extends StatefulWidget {
  final InventoryItem item;

  const _EditItemDialog({required this.item});

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier la quantité'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.product?.designation ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(
              labelText: 'Quantité',
              hintText: 'Utilisez un nombre négatif pour corriger',
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final newQuantity = double.tryParse(_quantityController.text);
            if (newQuantity != null) {
              context.read<InventoryBloc>().add(
                UpdateInventoryItemEvent(
                  widget.item.copyWith(quantity: newQuantity),
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            'Scannez ou ajoutez votre premier article',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // Open scanner
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scanner un article'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // Retry
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class InventorySearchDelegate extends SearchDelegate<InventoryItem?> {
  final int inventoryId;
  final InventoryRepository repository;

  InventorySearchDelegate({
    required this.inventoryId,
    required this.repository,
  });

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<InventoryItem>>(
      future: repository.getInventoryItems(inventoryId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!.where((item) {
          final searchLower = query.toLowerCase();
          return item.product?.code.toLowerCase().contains(searchLower) == true ||
                 item.product?.designation.toLowerCase().contains(searchLower) == true ||
                 item.product?.barcode?.toLowerCase().contains(searchLower) == true;
        }).toList();

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item.product?.designation ?? ''),
              subtitle: Text('Code: ${item.product?.code}'),
              trailing: Text('Qty: ${item.quantity}'),
              onTap: () => close(context, item),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Recherchez par code, désignation ou code-barres'),
      );
    }
    return buildResults(context);
  }
}