import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventory_manager/domain/entities/inventory.dart';
import 'package:inventory_manager/features/home/presentation/bloc/home_bloc.dart';
import 'package:inventory_manager/features/inventory/presentation/screens/product_scanner_screen.dart';

class InventoryDetailScreen extends StatefulWidget {
  final Inventory inventory;

  const InventoryDetailScreen({
    super.key,
    required this.inventory,
  });

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  late Inventory _currentInventory;

  @override
  void initState() {
    super.initState();
    _currentInventory = widget.inventory;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentInventory.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte info principale
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentInventory.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (_currentInventory.description != null && 
                                  _currentInventory.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _currentInventory.description!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _InfoRow(
                      icon: Icons.numbers_outlined,
                      label: 'Nombre d\'articles',
                      value: '${_currentInventory.itemCount ?? 0}',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Créé le',
                      value: dateFormat.format(_currentInventory.createdAt),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.update_outlined,
                      label: 'Dernière modification',
                      value: dateFormat.format(_currentInventory.updatedAt),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Section actions
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            
            // Bouton voir articles
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.list_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text('Voir les articles'),
                subtitle: Text('${_currentInventory.itemCount ?? 0} article(s)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _navigateToItemsList(context),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Bouton scanner
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: Colors.green.shade700,
                  ),
                ),
                title: const Text('Scanner un produit'),
                subtitle: const Text('Ajouter via code-barres/QR'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _openScanner(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modifier l'inventaire
  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: _currentInventory.name);
    final descController = TextEditingController(text: _currentInventory.description ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier l\'inventaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                hintText: 'Nom de l\'inventaire',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optionnel',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                // Envoi au BLoC
                context.read<HomeBloc>().add(
                  UpdateInventoryEvent(
                    inventoryId: _currentInventory.id,
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty 
                        ? null 
                        : descController.text.trim(),
                  ),
                );
                // Mise à jour locale immédiate
                setState(() {
                  _currentInventory = _currentInventory.copyWith(
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty 
                        ? null 
                        : descController.text.trim(),
                  );
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inventaire mis à jour')),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // Naviguer vers la liste des articles
  void _navigateToItemsList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryListScreen(
          inventoryId: _currentInventory.id,
        ),
      ),
    );
  }

  // Ouvrir le scanner
  void _openScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductScannerScreen(
          inventoryId: _currentInventory.id,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}