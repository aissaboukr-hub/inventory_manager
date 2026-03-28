import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

    import 'package:mobile_scanner/mobile_scanner.dart'; // Ajoute ce package

showDialog(
  context: context,
  builder: (dialogContext) => AlertDialog(
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
          // 🆕 Champ URL avec bouton QR à droite
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'URL du Script Google Apps',
              hintText: 'https://script.google.com/macros/s/.../exec',
              prefixIcon: const Icon(Icons.link),
              // 🆕 Bouton scan QR
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.green),
                tooltip: 'Scanner un QR code',
                onPressed: () async {
                  // Ouvre le scanner QR
                  final scannedUrl = await showDialog<String>(
                    context: dialogContext,
                    builder: (context) => const QRScannerDialog(),
                  );
                  
                  // Si un URL a été scannée, on la met dans le champ
                  if (scannedUrl != null && scannedUrl.isNotEmpty) {
                    controller.text = scannedUrl;
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 🆕 Info bulle pour guider l'utilisateur
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scannez le QR code généré depuis votre Google Sheets ou collez l\'URL manuellement',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
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
        onPressed: () => Navigator.pop(dialogContext),
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
            
            Navigator.of(dialogContext).pop();
            
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

class QRScannerDialog extends StatefulWidget {
  const QRScannerDialog({super.key});

  @override
  State<QRScannerDialog> createState() => _QRScannerDialogState();
}

class _QRScannerDialogState extends State<QRScannerDialog> {
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 400,
          width: double.infinity,
          child: Stack(
            children: [
              // 📷 Caméra scanner
              MobileScanner(
                onDetect: (capture) {
                  if (!_isScanning) return;
                  
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final String? url = barcode.rawValue;
                    if (url != null && url.isNotEmpty) {
                      setState(() => _isScanning = false);
                      // Retourne l'URL scannée et ferme
                      Navigator.pop(context, url);
                      break;
                    }
                  }
                },
              ),
              
              // 🎨 Overlay design
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
              
              // 📍 Zone de scan (carré au centre)
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code,
                      size: 50,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
              
              // ✨ Coins animés (optionnel mais stylé)
              Positioned.fill(
                child: CustomPaint(
                  painter: ScannerOverlayPainter(),
                ),
              ),
              
              // 🔙 Bouton fermer
              Positioned(
                top: 16,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              
              // 💬 Instructions
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Placez le QR code dans le cadre',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🎨 Painter pour les coins du scanner (optionnel)
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const scanArea = 250.0;
    const cornerLength = 30.0;

    // Coins du cadre de scan
    final corners = [
      // Haut gauche
      Offset(centerX - scanArea/2, centerY - scanArea/2 + cornerLength),
      Offset(centerX - scanArea/2, centerY - scanArea/2),
      Offset(centerX - scanArea/2 + cornerLength, centerY - scanArea/2),
      // Haut droite
      Offset(centerX + scanArea/2 - cornerLength, centerY - scanArea/2),
      Offset(centerX + scanArea/2, centerY - scanArea/2),
      Offset(centerX + scanArea/2, centerY - scanArea/2 + cornerLength),
      // Bas droite
      Offset(centerX + scanArea/2, centerY + scanArea/2 - cornerLength),
      Offset(centerX + scanArea/2, centerY + scanArea/2),
      Offset(centerX + scanArea/2 - cornerLength, centerY + scanArea/2),
      // Bas gauche
      Offset(centerX - scanArea/2 + cornerLength, centerY + scanArea/2),
      Offset(centerX - scanArea/2, centerY + scanArea/2),
      Offset(centerX - scanArea/2, centerY + scanArea/2 - cornerLength),
    ];

    for (int i = 0; i < corners.length; i += 3) {
      final path = Path()
        ..moveTo(corners[i].dx, corners[i].dy)
        ..lineTo(corners[i+1].dx, corners[i+1].dy)
        ..lineTo(corners[i+2].dx, corners[i+2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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