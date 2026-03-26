import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventory_manager/data/datasources/local/database.dart';
import 'package:inventory_manager/data/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleSheetsService {
  static const String _scriptUrlKey = 'google_script_url';
  final AppDatabase _database;

  GoogleSheetsService(this._database);

  // Sauvegarder l'URL du script
  Future<void> saveScriptUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scriptUrlKey, url);
  }

  // Récupérer l'URL du script
  Future<String?> getScriptUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scriptUrlKey);
  }

  // Vérifier si configuré
  Future<bool> isConfigured() async {
    final url = await getScriptUrl();
    return url != null && url.isNotEmpty;
  }

  // Tester la connexion
  Future<bool> testConnection() async {
    try {
      final url = await getScriptUrl();
      if (url == null) return false;

      final response = await http.get(Uri.parse('$url?action=test'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Importer depuis Google Sheets
  Future<ImportResult> importFromSheet() async {
    try {
      final url = await getScriptUrl();
      if (url == null) {
        throw Exception('URL du script non configurée');
      }

      final response = await http.get(
        Uri.parse('$url?action=getProducts'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Erreur inconnue');
      }

      final products = (data['products'] as List).cast<Map<String, dynamic>>();
      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      for (final productData in products) {
        try {
          await _database.into(_database.products).insert(
            ProductsCompanion(
              code: Value(productData['code'] as String),
              designation: Value(productData['designation'] as String),
              barcode: Value(productData['barcode'] as String?),
              category: Value(productData['category'] as String?),
              unit: Value(productData['unit'] as String? ?? 'U'),
            ),
            mode: InsertMode.insertOrReplace,
          );
          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('${productData['code']}: $e');
        }
      }

      return ImportResult(
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        successCount: 0,
        errorCount: 1,
        errors: [e.toString()],
      );
    }
  }

  // Exporter vers Google Sheets
  Future<bool> exportToSheet(int inventoryId, String inventoryName) async {
    try {
      final url = await getScriptUrl();
      if (url == null) return false;

      // Récupérer les items de l'inventaire
      final items = await _database.customSelect('''
        SELECT ii.*, p.code, p.designation, p.unit
        FROM inventory_items ii
        JOIN products p ON ii.product_id = p.id
        WHERE ii.inventory_id = ?
      ''', variables: [Variable(inventoryId)]).get();

      final exportData = items.map((row) => {
        'code': row.data['code'],
        'designation': row.data['designation'],
        'quantity': row.data['quantity'],
        'unit': row.data['unit'],
        'notes': row.data['notes'],
      }).toList();

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'saveInventory',
          'inventoryName': inventoryName,
          'items': exportData,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class ImportResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;

  ImportResult({
    required this.successCount,
    required this.errorCount,
    this.errors = const [],
  });
}