import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory.dart';
import '../core/theme.dart';
import 'active_inventory_screen.dart';

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Inventaires'),
        actions: [
          Consumer<InventoryProvider>(
            builder: (_, prov, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${prov.inventories.length} liste(s)',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.inventories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun inventaire',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez sur + pour créer votre\npremier inventaire',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.loadInventories,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.inventories.length,
              itemBuilder: (ctx, i) =>
                  _InventoryCard(inventory: provider.inventories[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel inventaire'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
    controller.text = 'Inventaire $dateStr';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvel inventaire'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom de l\'inventaire',
            hintText: 'Ex: Inventaire magasin principal',
          ),
          onSubmitted: (_) => _create(ctx, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _create(ctx, controller.text),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _create(BuildContext context, String name) async {
    if (name.trim().isEmpty) return;
    Navigator.pop(context);
    final provider = context.read<InventoryProvider>();
    final inv = await provider.createInventory(name.trim());
    await provider.setActiveInventory(inv);
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveInventoryScreen(inventory: inv),
        ),
      );
    }
  }
}

class _InventoryCard extends StatelessWidget {
  final Inventory inventory;
  const _InventoryCard({required this.inventory});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              inventory.isActive ? AppTheme.primary : Colors.grey,
          child: Icon(
            inventory.isActive ? Icons.edit_note : Icons.check_circle,
            color: Colors.white,
          ),
        ),
        title: Text(
          inventory.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd/MM/yyyy à HH:mm').format(inventory.createdAt)),
            if (inventory.entryCount != null)
              Text(
                '${inventory.entryCount} saisie(s)',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) =>
              _handleAction(context, action, provider),
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'open',
                child: ListTile(
                    leading: Icon(Icons.open_in_new),
                    title: Text('Ouvrir'))),
            const PopupMenuItem(
                value: 'rename',
                child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Renommer'))),
            const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Supprimer',
                        style: TextStyle(color: Colors.red)))),
          ],
        ),
        onTap: () async {
          await provider.setActiveInventory(inventory);
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ActiveInventoryScreen(inventory: inventory),
              ),
            );
          }
        },
      ),
    );
  }

  void _handleAction(
      BuildContext context, String action, InventoryProvider provider) {
    switch (action) {
      case 'open':
        provider.setActiveInventory(inventory).then((_) {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ActiveInventoryScreen(inventory: inventory),
              ),
            );
          }
        });
        break;
      case 'rename':
        _showRenameDialog(context, provider);
        break;
      case 'delete':
        _showDeleteConfirm(context, provider);
        break;
    }
  }

  void _showRenameDialog(BuildContext context, InventoryProvider provider) {
    final ctrl = TextEditingController(text: inventory.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renommer'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration:
              const InputDecoration(labelText: 'Nouveau nom'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.renameInventory(inventory.id, ctrl.text.trim());
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'inventaire'),
        content: Text(
            'Supprimer "${inventory.name}" et toutes ses saisies ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteInventory(inventory.id);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
