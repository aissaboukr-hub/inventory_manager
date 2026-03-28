import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/config/routes.dart';
import 'package:inventory_manager/domain/entities/inventory.dart';
import 'package:inventory_manager/features/home/presentation/bloc/home_bloc.dart';
import 'package:inventory_manager/features/inventory/presentation/screens/inventory_items_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      // Material 3: Surface tint color pour l'élévation
      backgroundColor: colorScheme.surface,
      // Material 3: Large AppBar avec scrolledUnderElevation
      appBar: AppBar(
        title: const Text('Mes Inventaires'),
        centerTitle: true,
        // Material 3: Surface tint pour l'effet d'élévation au scroll
        scrolledUnderElevation: 4,
        shadowColor: Colors.transparent,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          // Material 3: IconButton avec style standard
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres', // Material 3: Tooltips obligatoires
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: const _InventoriesList(),
      // Material 3: FAB avec extended variant
      floatingActionButton: const _AddInventoryFab(),
    );
  }
}

class _InventoriesList extends StatelessWidget {
  const _InventoriesList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const _LoadingShimmer();
        }

        if (state is HomeError) {
          return _ErrorView(message: state.message);
        }

        if (state is HomeLoaded) {
          if (state.inventories.isEmpty) {
            return const _EmptyState();
          }

          // Material 3: Pull-to-refresh avec indicateur Material
          return RefreshIndicator(
            onRefresh: () async {
              context.read<HomeBloc>().add(const RefreshInventoriesEvent());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.inventories.length,
              itemBuilder: (context, index) {
                final inventory = state.inventories[index];
                return _InventoryCard(
                  inventory: inventory,
                  onTap: () => _navigateToItemsList(context, inventory),
                  onDelete: () => _confirmDelete(context, inventory),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _navigateToItemsList(BuildContext context, Inventory inventory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryItemsScreen(
          inventoryId: inventory.id,
          inventoryName: inventory.name,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Inventory inventory) {
    // Material 3: AlertDialog avec actions alignées à droite
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // Material 3: Icone dans le dialog (optional mais recommandé)
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        title: const Text('Supprimer l\'inventaire ?'),
        // Material 3: Content padding standard
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${inventory.name}" sera définitivement supprimé.'),
            if (inventory.itemCount != null && inventory.itemCount! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                // Material 3: Card pour l'avertissement avec tonalité
                child: Card(
                  color: Colors.orange.shade50,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, 
                          color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${inventory.itemCount} articles seront perdus',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Material 3: Actions avec TextButton et FilledButton.tonal/elevated
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          // Material 3: FilledButton pour l'action principale destructive
          FilledButton(
            onPressed: () {
              context.read<HomeBloc>().add(DeleteInventoryEvent(inventory.id));
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Inventory inventory;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InventoryCard({
    required this.inventory,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    // Material 3: Card avec elevation et shape standard
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // Material 3: Elevation 1 pour les cartes de liste
      elevation: 1,
      // Material 3: Shape avec border radius 12 (medium component)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      // Material 3: Surface tint pour l'effet de couleur d'élévation
      surfaceTintColor: colorScheme.surfaceTint,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Material 3: Container avec couleur du schéma
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  // Material 3: Primary container pour les icônes
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Material 3: titleMedium pour les titres de cartes
                    Text(
                      inventory.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Material 3: bodyMedium avec onSurfaceVariant pour le texte secondaire
                    Text(
                      '${inventory.itemCount ?? 0} articles • ${dateFormat.format(inventory.updatedAt)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Material 3: MenuAnchor (nouveau) ou PopupMenuButton
              PopupMenuButton<String>(
                // Material 3: Tooltip obligatoire
                tooltip: 'Plus d\'options',
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      onDelete();
                      break;
                    case 'export':
                      // TODO: Export
                      break;
                    case 'rename':
                      _showEditDialog(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Renommer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Exporter'),
                      ],
                    ),
                  ),
                  // Material 3: Divider entre les actions
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, 
                          size: 20, 
                          color: colorScheme.error),
                        const SizedBox(width: 12),
                        Text('Supprimer', 
                          style: TextStyle(color: colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: inventory.name);
    final descController = TextEditingController(text: inventory.description ?? '');
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.edit_note),
        title: const Text('Modifier l\'inventaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Material 3: TextField avec decoration filled
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nom *',
                hintText: 'Nom de l\'inventaire',
                // Material 3: Filled decoration par défaut
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Optionnel',
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
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
                context.read<HomeBloc>().add(
                  UpdateInventoryEvent(
                    inventoryId: inventory.id,
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty 
                        ? null 
                        : descController.text.trim(),
                  ),
                );
                Navigator.pop(dialogContext);
                // Material 3: SnackBar avec action optionnelle
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Inventaire mis à jour'),
                    behavior: SnackBarBehavior.floating,
                    width: 280,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _AddInventoryFab extends StatelessWidget {
  const _AddInventoryFab();

  @override
  Widget build(BuildContext context) {
    // Material 3: FloatingActionButton.extended avec elevation standard
    return FloatingActionButton.extended(
      onPressed: () => _showAddDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('Nouveau'),
      // Material 3: Elevation 3 pour FAB extended
      elevation: 3,
      // Material 3: Shape avec border radius 16 (large)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.create_new_folder_outlined),
        title: const Text('Nouvel inventaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nom *',
                hintText: 'Ex: Stock Mars 2024',
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Optionnel',
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
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
                context.read<HomeBloc>().add(
                  CreateInventoryEvent(
                    nameController.text.trim(),
                    description: descController.text.trim().isEmpty 
                        ? null 
                        : descController.text.trim(),
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
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
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 88,
          // Material 3: Même border radius que les vraies cartes
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Material 3: Icône avec couleur outline
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          // Material 3: headlineSmall pour les états vides
          Text(
            'Aucun inventaire',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier inventaire\npour commencer',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          // Material 3: FilledButton.tonal pour l'action secondaire
          FilledButton.tonalIcon(
            onPressed: () {
              // Trigger add dialog through bloc
              // Note: Vous devriez utiliser un GlobalKey ou un callback
            },
            icon: const Icon(Icons.add),
            label: const Text('Créer un inventaire'),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Material 3: Icône d'erreur avec couleur error
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // Material 3: FilledButton.tonal pour l'action de retry
            FilledButton.tonalIcon(
              onPressed: () {
                context.read<HomeBloc>().add(const LoadInventoriesEvent());
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