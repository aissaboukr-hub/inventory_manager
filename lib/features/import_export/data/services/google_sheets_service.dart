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

  Future<ImportResult> importFromSheet() async {
    return importFromSheetOptimized();
  }

  Future<ImportResult> importFromSheetOptimized({
    void Function(int current, int total)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final url = await getScriptUrl();
      if (url == null) {
        throw Exception('URL du script non configurée');
      }

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

      const batchSize = 50;
      
      for (var i = 0; i < products.length; i += batchSize) {
        final batch = products.skip(i).take(batchSize).toList();
        
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

  // ✅ CORRIGÉ : Validation robuste du code
  ProductsCompanion _parseProductData(Map<String, dynamic> data) {
    String? code = _toString(data['code']);
    final designation = _toString(data['designation']);
    final barcode = _toStringNullable(data['barcode']);

    // ✅ Détection et correction des dates converties
    if (code != null && _looksLikeDate(code)) {
      print('⚠️ Date détectée dans le code, tentative de conversion: $code');
      // Essayer de récupérer le format original si possible
      code = _extractCodeFromDateString(code);
    }

    // ✅ Validation et troncature
    if (code == null || code.isEmpty) {
      throw Exception('Code manquant');
    }
    
    // Tronquer à 50 caractères (limite de la DB)
    if (code.length > 50) {
      print('⚠️ Code trop long (${code.length} chars), tronqué à 50: ${code.substring(0, 50)}');
      code = code.substring(0, 50);
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

  // ✅ Détecte si une chaîne ressemble à une date
  bool _looksLikeDate(String value) {
    final datePatterns = [
      r'^\w{3} \w{3} \d{2} \d{4}',  // Wed Apr 01 1018
      r'GMT[+-]\d{4}',               // Contient GMT
      r'\d{2}/\d{2}/\d{4}',          // 01/04/1018
    ];
    
    return datePatterns.any((pattern) => 
      RegExp(pattern, caseSensitive: false).hasMatch(value)
    );
  }

  // ✅ Essaie d'extraire un code valide d'une date
  String _extractCodeFromDateString(String value) {
    // Si c'est une date au format JJ/MM/AAAA, la garder comme ça
    final dateMatch = RegExp(r'(\d{2})/(\d{2})/(\d{4})').firstMatch(value);
    if (dateMatch != null) {
      return '${dateMatch.group(1)}/${dateMatch.group(2)}/${dateMatch.group(3)}';
    }
    
    // Si c'est une date longue, essayer de trouver un pattern de code
    if (value.contains('GMT')) {
      // Retourner une valeur par défaut ou essayer de parser
      return 'CODE_DATE_INVALIDE';
    }
    
    return value;
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

  String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString().trim();
  }

  String? _toStringNullable(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isEmpty) return null;
    return _toString(value);
  }
}

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