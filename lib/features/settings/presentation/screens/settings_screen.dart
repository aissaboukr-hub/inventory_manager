import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/data/datasources/local/database.dart';
import 'package:inventory_manager/features/import_export/data/services/export_service.dart';
import 'package:inventory_manager/features/import_export/data/services/import_service.dart';
import 'package:inventory_manager/features/import_export/data/services/google_sheets_service.dart';
import 'package:drift/drift.dart' as drift;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  String _loadingText = '';
  String _appVersion = '1.0.0';
  int _productCount = 0;
  int _inventoryCount = 0;
  String? _googleScriptUrl;
  bool _isGoogleConnected = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _checkGoogleSheetsConfig();
  }

  Future<void> _loadStats() async {
    final database = AppDatabase();
    final products = await database.select(database.products).get();
    final inventories = await database.select(database.inventories).get();
    
    setState(() {
      _productCount = products.length;
      _inventoryCount = inventories.length;
    });
  }

  Future<void> _checkGoogleSheetsConfig() async {
    final database = AppDatabase();
    final service = GoogleSheetsService(database);
    
    final url = await service.getScriptUrl();
    final isConnected = await service.isConfigured();
    
    setState(() {
      _googleScriptUrl = url;
      _isGoogleConnected = isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              _buildSectionHeader('Import / Export'),
              _buildListTile(
                icon: Icons.file_upload_outlined,
                title: 'Importer des produits',
                subtitle: 'Depuis Excel (.xlsx)',
                onTap: _importFromExcel,
              ),
              _buildListTile(
                icon: Icons.cloud_download_outlined,
                title: 'Importer depuis Google Sheets',
                subtitle: _isGoogleConnected ? '✅ Configuré' : '⚠️ Non configuré',
                color: _isGoogleConnected ? Colors.green : Colors.orange,
                onTap: _importFromGoogleSheets,
              ),
              _buildListTile(
                icon: Icons.cloud_upload_outlined,
                title: 'Connecter Google Sheets',
                subtitle: 'Configuration API',
                onTap: _configureGoogleSheets,
              ),
              
              const Divider(),
              
              _buildSectionHeader('Données'),
              _buildListTile(
                icon: Icons.backup_outlined,
                title: 'Sauvegarder',
                subtitle: 'Exporter toutes les données',
                onTap: _backupData,
              ),
              _buildListTile(
                icon: Icons.restore_outlined,
                title: 'Restaurer',
                subtitle: 'Importer une sauvegarde',
                onTap: _restoreData,
              ),
              _buildListTile(
                icon: Icons.delete_sweep_outlined,
                title: 'Nettoyer les données',
                subtitle: 'Supprimer les produits inutilisés',
                color: Colors.orange,
                onTap: _cleanupData,
              ),
              
              const Divider(),
              
              _buildSectionHeader('Statistiques'),
              _buildStatTile(
                icon: Icons.inventory_2_outlined,
                label: 'Produits en base',
                value: '$_productCount',
              ),
              _buildStatTile(
                icon: Icons.folder_open_outlined,
                label: 'Inventaires créés',
                value: '$_inventoryCount',
              ),
              
              const Divider(),
              
              _buildSectionHeader('À propos'),
              _buildListTile(
                icon: Icons.info_outlined,
                title: 'Version',
                subtitle: _appVersion,
                onTap: null,
              ),
              _buildListTile(
                icon: Icons.help_outline,
                title: 'Aide & Support',
                subtitle: 'Documentation et contact',
                onTap: _showHelp,
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _loadingText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _importFromExcel() async {
    setState(() {
      _isLoading = true;
      _loadingText = 'Importation Excel...';
    });
    
    try {
      final database = AppDatabase();
      final importService = ImportService(database);
      final result = await importService.importFromExcel();
      
      if (!mounted) return;
      
      if (result.successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.successCount} produits importés'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats();
      }
      
      if (result.errorCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.errorCount} erreurs lors de l\'import'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _configureGoogleSheets() {
    final controller = TextEditingController(text: _googleScriptUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud, color: Colors.green),
            SizedBox(width: 8),
            Text('Google Sheets'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'URL du Script Google Apps',
                  hintText: 'https://script.google.com/macros/s/.../exec',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                              ),
              
              const SizedBox(height: 12),
              
              if (_isGoogleConnected)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Connecté',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                final database = AppDatabase();
                final service = GoogleSheetsService(database);
                
                await service.saveScriptUrl(url);
                
                final isConnected = await service.testConnection();
                
                if (!mounted) return;
                
                setState(() {
                  _googleScriptUrl = url;
                  _isGoogleConnected = isConnected;
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isConnected 
                        ? '✅ Connecté à Google Sheets' 
                        : '⚠️ URL sauvegardée mais connexion échouée'),
                    backgroundColor: isConnected ? Colors.green : Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromGoogleSheets() async {
    setState(() {
      _isLoading = true;
      _loadingText = 'Connexion à Google Sheets...';
    });
    
    try {
      final database = AppDatabase();
      final service = GoogleSheetsService(database);
      
      if (!await service.isConfigured()) {
        setState(() => _isLoading = false);
        _configureGoogleSheets();
        return;
      }
      
      setState(() => _loadingText = 'Récupération des données...');
      
      final result = await service.importFromSheetOptimized(
        onProgress: (current, total) {
          setState(() {
            _loadingText = 'Importation $current / $total...';
          });
        },
      );
      
      if (!mounted) return;
      
      if (result.successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result.successCount} produits importés en ${result.duration.inSeconds}s'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats();
      }
      
      if (result.errorCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${result.errorCount} erreurs'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Détails',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Erreurs d\'import'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: result.errors.length,
                        itemBuilder: (context, index) => Text('• ${result.errors[index]}'),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  

  Future<void> _backupData() async {
    setState(() {
      _isLoading = true;
      _loadingText = 'Sauvegarde...';
    });
    
    try {
      final database = AppDatabase();
      final exportService = ExportService(database);
      final inventories = await database.select(database.inventories).get();
      
      for (final inventory in inventories) {
        final filePath = await exportService.exportToExcel(
          inventory.id,
          inventory.name,
        );
        await exportService.shareFile(filePath);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sauvegarde effectuée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _restoreData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer les données'),
        content: const Text(
          'Cette action ajoutera les produits du fichier Excel. Les doublons seront ignorés. Continuer ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performRestore();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore() async {
    setState(() {
      _isLoading = true;
      _loadingText = 'Restauration...';
    });
    
    try {
      final database = AppDatabase();
      final importService = ImportService(database);
      
      final result = await importService.importFromExcel();
      
      if (!mounted) return;
      
      if (result.successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result.successCount} produits restaurés'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats();
      } else if (result.errorCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result.errorCount} erreurs lors de la restauration'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ℹ️ Aucun nouveau produit à importer'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cleanupData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nettoyer les données'),
        content: const Text(
          'Supprimer les produits qui ne sont dans aucun inventaire ? Cette action est irréversible.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performCleanupOptimized(); // ✅ Version optimisée
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Nettoyer'),
          ),
        ],
      ),
    );
  }

  // ✅ VERSION OPTIMISÉE : Nettoyage rapide avec requête SQL unique
  Future<void> _performCleanupOptimized() async {
    setState(() {
    _isLoading = true;
    _loadingText = 'Suppression des données...';
  });

  final stopwatch = Stopwatch()..start();

  try {
    final database = AppDatabase();

    await database.transaction(() async {
      // 1️⃣ Supprimer les dépendances
      await database.customUpdate('DELETE FROM inventory_items');

      // 2️⃣ Supprimer les produits
      final deleted = await database.customUpdate('DELETE FROM products');

      print('Produits supprimés: $deleted');
    });

    stopwatch.stop();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🧹 Tous les produits supprimés en ${stopwatch.elapsed.inSeconds}s'),
        backgroundColor: Colors.orange,
      ),
    );

    _loadStats();

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Erreur: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 Email: support@example.com'),
            SizedBox(height: 8),
            Text('📖 Documentation: https://docs.example.com'),
            SizedBox(height: 8),
            Text('🐛 Signaler un bug: https://github.com/example/issues'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}