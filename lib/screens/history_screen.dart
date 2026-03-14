import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory.dart';
import '../models/inventory_entry.dart';
import '../core/database/database_service.dart';
import '../core/theme.dart';
import '../services/export_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final closed =
              provider.inventories.where((i) => !i.isActive).toList();
          if (closed.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun inventaire terminé',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: closed.length,
            itemBuilder: (ctx, i) =>
                _HistoryCard(inventory: closed[i]),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Inventory inventory;
  const _HistoryCard({required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: Text(inventory.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(inventory.createdAt),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () => _viewDetails(context),
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _export(context),
            ),
          ],
        ),
        onTap: () => _viewDetails(context),
      ),
    );
  }

  void _viewDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _InventoryDetailScreen(inventory: inventory),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final result = await ExportService.instance.exportToExcel(
      inventoryId: inventory.id,
      inventoryName: inventory.name,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? AppTheme.success : AppTheme.error,
      ));
    }
  }
}

class _InventoryDetailScreen extends StatefulWidget {
  final Inventory inventory;
  const _InventoryDetailScreen({required this.inventory});

  @override
  State<_InventoryDetailScreen> createState() =>
      _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<_InventoryDetailScreen> {
  List<InventoryEntry> _entries = [];
  List<Map<String, dynamic>> _totals = [];
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await DatabaseService.instance
        .getEntriesByInventory(widget.inventory.id);
    final totals = await DatabaseService.instance
        .getTotalsByInventory(widget.inventory.id);
    setState(() {
      _entries = entries;
      _totals = totals;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inventory.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final result = await ExportService.instance.exportToExcel(
                inventoryId: widget.inventory.id,
                inventoryName: widget.inventory.name,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result.message),
                  backgroundColor: result.success
                      ? AppTheme.success
                      : AppTheme.error,
                ));
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: _tabIndex == 0
                        ? Colors.white24
                        : Colors.transparent,
                    alignment: Alignment.center,
                    child: Text(
                      'Historique (${_entries.length})',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: _tabIndex == 1
                        ? Colors.white24
                        : Colors.transparent,
                    alignment: Alignment.center,
                    child: Text(
                      'Totaux (${_totals.length})',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tabIndex == 0
              ? _buildHistory()
              : _buildTotals(),
    );
  }

  Widget _buildHistory() {
    if (_entries.isEmpty) {
      return const Center(child: Text('Aucune saisie'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (ctx, i) {
        final e = _entries[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(e.designation,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${e.productCode}  •  ${DateFormat('dd/MM HH:mm').format(e.date)}',
            ),
            trailing: Text(
              e.quantity.toStringAsFixed(
                  e.quantity.truncateToDouble() == e.quantity ? 0 : 2),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: e.quantity < 0 ? AppTheme.error : AppTheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotals() {
    if (_totals.isEmpty) {
      return const Center(child: Text('Aucun total'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _totals.length,
      itemBuilder: (ctx, i) {
        final t = _totals[i];
        final qty = (t['total_quantity'] as num).toDouble();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(t['designation']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(t['product_code']?.toString() ?? ''),
            trailing: Text(
              qty.toStringAsFixed(
                  qty.truncateToDouble() == qty ? 0 : 2),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: qty < 0 ? AppTheme.error : AppTheme.success,
              ),
            ),
          ),
        );
      },
    );
  }
}
