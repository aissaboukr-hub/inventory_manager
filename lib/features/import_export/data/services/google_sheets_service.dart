import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventory_manager/data/datasources/local/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleSheetsService {
  static const String _scriptUrlKey = 'google_script_url';
  final AppDatabase _database;

  GoogleSheetsService(this._database);

  Future<void> saveScriptUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scriptUrlKey, url);
  }

  Future<String?> getScriptUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scriptUrlKey);
  }

  Future<bool> isConfigured() async {
    final url = await getScriptUrl();
    return url != null && url.isNotEmpty;
  }

  Future<bool> testConnection() async {
    try {
      final url = await getScriptUrl();
      if (url == null) return false;

      final response = await http.get(
        Uri.parse('$url?action=test'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Test connection error: $e');
      return false;
    }
  }

  // ✅ MÉTHODE ORIGINALE (conservée pour compatibilité)
  Future<ImportResult> importFromSheet() async {
    return importFromSheetOptimized();
  }

  // ✅ NOUVELLE MÉTHODE : Import optimisé avec batch et progression
  Future<ImportResult> importFromSheetOptimized({
    void Function(int current, int total)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final url = await getScriptUrl();
      if (url == null) {
        throw Exception('URL du script non configurée');
      }

      // ✅ Une seule requête HTTP pour tout récupérer
      final response = await http.get(
        Uri.parse('$url?action=getProducts'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Erreur inconnue');
      }

      final products = (data['products'] as List).cast<Map<String, dynamic>>();
      final total = products.length;
      
      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      // ✅ Traitement par batch de 50 pour la base de données
      const batchSize = 50;
      
      for (var i = 0; i < products.length; i += batchSize) {
        final batch = products.skip(i).take(batchSize).toList();
        
        // ✅ Transaction batch - beaucoup plus rapide !
        await _database.transaction(() async {
          for (final productData in batch) {
            try {
              final companion = _parseProductData(productData);
              
              await _database.into(_database.products).insert(
                companion,
                mode: InsertMode.insertOrReplace,
              );
              successCount++;
            } catch (e) {
              errorCount++;
              errors.add('${productData['code']}: $e');
            }
          }
        });
        
        // Notifier la progression
        onProgress?.call((i + batch.length).clamp(0, total), total);
      }

      stopwatch.stop();

      return ImportResult(
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return ImportResult(
        successCount: 0,
        errorCount: 1,
        errors: [e.toString()],
        duration: stopwatch.elapsed,
      );
    }
  }

  // ✅ Helper : Parse les données produit en companion
  ProductsCompanion _parseProductData(Map<String, dynamic> data) {
    final code = _toString(data['code']);
    final designation = _toString(data['designation']);
    final barcode = _toStringNullable(data['barcode']);

    if (code == null || code.isEmpty) {
      throw Exception('Code manquant');
    }
    if (designation == null || designation.isEmpty) {
      throw Exception('Designation manquante');
    }

    return ProductsCompanion(
      code: Value(code),
      designation: Value(designation),
      barcode: Value(barcode),
      category: Value.absent(),
      unit: Value('U'),
    );
  }

  Future<bool> exportToSheet(int inventoryId, String inventoryName) async {
    try {
      final url = await getScriptUrl();
      if (url == null) return false;

      final items = await _database.customSelect('''
        SELECT ii.*, p.code, p.designation, p.unit
        FROM inventory_items ii
        JOIN products p ON ii.product_id = p.id
        WHERE ii.inventory_id = ?
      ''', variables: [Variable(inventoryId)]).get();

      final exportData = items.map((row) => {
        'code': row.read<String>('code'),
        'designation': row.read<String>('designation'),
        'quantity': row.read<double>('quantity'),
        'unit': row.read<String>('unit') ?? 'U',
        'notes': row.read<String?>('notes'),
      }).toList();

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'saveInventory',
          'inventoryName': inventoryName,
          'items': exportData,
        }),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }

  // ✅ Helper : Convertit n'importe quel type en String
  String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }

  // ✅ Helper : Convertit en String ou null
  String? _toStringNullable(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isEmpty) return null;
    return _toString(value);
  }
}

// ✅ ImportResult mis à jour avec duration
class ImportResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;
  final Duration duration;

  ImportResult({
    required this.successCount,
    required this.errorCount,
    this.errors = const [],
    this.duration = Duration.zero,
  });
}