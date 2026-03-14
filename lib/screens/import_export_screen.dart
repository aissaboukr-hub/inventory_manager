import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import '../core/theme.dart';
import '../services/export_service.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final _scriptUrlCtrl = TextEditingController();
  final _sheetUrlCtrl = TextEditingController();

  @override
  void dispose() {
    _scriptUrlCtrl.dispose();
    _sheetUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import / Export')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Import Section ─────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.upload_file,
              title: 'Importer les produits',
              color: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            // Compteur produits
            Consumer<ProductProvider>(
              builder: (_, prov, __) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2,
                        color: AppTheme.primary, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${prov.productCount}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const Text('produits dans la base locale'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Import Excel
            Consumer<ProductProvider>(
              builder: (_, prov, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        prov.loading ? null : () => _importExcel(context),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Importer depuis Excel (.xlsx)'),
                  ),
                  if (prov.loading) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: prov.importProgress),
                    const SizedBox(height: 6),
                    Text(
                      prov.importStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Import Google Sheets
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Importer depuis Google Sheets',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _scriptUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL Apps Script',
                      hintText: 'https://script.google.com/macros/s/...',
                      prefixIcon: Icon(Icons.code),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sheetUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL Google Sheets',
                      hintText: 'https://docs.google.com/spreadsheets/d/...',
                      prefixIcon: Icon(Icons.table_view),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _importSheets(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D58)),
                    icon: const Icon(Icons.cloud_download),
                    label:
                        const Text('Importer depuis Google Sheets'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Export Section ──────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.download,
              title: 'Exporter un inventaire',
              color: AppTheme.success,
            ),
            const SizedBox(height: 16),

            Consumer<InventoryProvider>(
              builder: (_, prov, __) {
                if (prov.inventories.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun inventaire à exporter',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: prov.inventories
                      .take(10)
                      .map((inv) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                inv.isActive
                                    ? Icons.edit
                                    : Icons.check_circle,
                                color: inv.isActive
                                    ? AppTheme.primary
                                    : Colors.grey,
                              ),
                              title: Text(inv.name),
                              subtitle:
                                  Text('${inv.entryCount ?? 0} saisie(s)'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) =>
                                    _handleExport(context, action, inv.id,
                                        inv.name),
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'excel',
                                    child: ListTile(
                                      leading: Icon(Icons.table_chart),
                                      title: Text('Excel + Partage'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'sheets',
                                    child: ListTile(
                                      leading: Icon(Icons.cloud_upload),
                                      title: Text('Google Sheets'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importExcel(BuildContext context) async {
    final result =
        await context.read<ProductProvider>().importFromExcel();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? AppTheme.success : AppTheme.error,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  Future<void> _importSheets(BuildContext context) async {
    final scriptUrl = _scriptUrlCtrl.text.trim();
    final sheetUrl = _sheetUrlCtrl.text.trim();
    if (scriptUrl.isEmpty || sheetUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner les deux URLs')),
      );
      return;
    }
    final result =
        await context.read<ProductProvider>().importFromGoogleSheets(
              scriptUrl: scriptUrl,
              sheetUrl: sheetUrl,
            );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? AppTheme.success : AppTheme.error,
      ));
    }
  }

  Future<void> _handleExport(
    BuildContext context,
    String action,
    String invId,
    String invName,
  ) async {
    ExportResult result;
    if (action == 'excel') {
      result = await ExportService.instance.exportToExcel(
        inventoryId: invId,
        inventoryName: invName,
      );
    } else {
      final scriptUrl = _scriptUrlCtrl.text.trim();
      if (scriptUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez renseigner l\'URL Apps Script'),
        ));
        return;
      }
      result = await ExportService.instance.exportToGoogleSheets(
        scriptUrl: scriptUrl,
        inventoryId: invId,
        inventoryName: invName,
      );
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? AppTheme.success : AppTheme.error,
      ));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
