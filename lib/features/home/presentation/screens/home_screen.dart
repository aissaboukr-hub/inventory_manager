import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/config/routes.dart';
import 'package:inventory_manager/domain/entities/inventory.dart';
import 'package:inventory_manager/features/home/presentation/bloc/home_bloc.dart';  // ← Importe le bloc avec les states
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Inventaires'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: const _InventoriesList(),
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
                  onTap: () => _navigateToDetail(context, inventory),
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

  void _navigateToDetail(BuildContext context, Inventory inventory) {
    Navigator.pushNamed(
      context,
      AppRoutes.inventoryDetail,
      arguments: inventory,
    );
  }

  void _confirmDelete(BuildContext context, Inventory inventory) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'inventaire ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${inventory.name}" sera définitivement supprimé.'),
            if (inventory.itemCount != null && inventory.itemCount! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ ${inventory.itemCount} articles seront perdus',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
              context.read<HomeBloc>().add(DeleteInventoryEvent(inventory.id));
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

// ... reste du fichier (widgets _InventoryCard, _AddInventoryFab, etc.) ...