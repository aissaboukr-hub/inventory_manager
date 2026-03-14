import 'dart:isolate';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import '../core/database/database_service.dart';

// ─── Payload passé à l'isolate ────────────────────────────────────────────────
class _IsolatePayload {
  final SendPort sendPort;
  final List<int> bytes;
  _IsolatePayload(this.sendPort, this.bytes);
}

// ─── Exécuté dans l'isolate (thread séparé) ───────────────────────────────────
void _parseExcelIsolate(_IsolatePayload payload) {
  try {
    final excel = Excel.decodeBytes(payload.bytes);
    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) {
      payload.sendPort.send(<Map<String, String>>[]);
      return;
    }

    final headers = sheet.rows.first
        .map((c) => c?.value?.toString().toLowerCase().trim() ?? '')
        .toList();

    int codeIdx    = _findCol(headers, ['code produit', 'code', 'ref', 'référence']);
    int desigIdx   = _findCol(headers, ['désignation', 'designation', 'libellé', 'libelle', 'nom', 'article']);
    int barcodeIdx = _findCol(headers, ['code-barres', 'barcode', 'code barre', 'ean', 'upc', 'gtin']);

    final products = <Map<String, String>>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final code    = _cellVal(row, codeIdx);
      final desig   = _cellVal(row, desigIdx);
      final barcode = _cellVal(row, barcodeIdx);
      if (code.isNotEmpty) {
        products.add({
          'code': code,
          'designation': desig.isEmpty ? code : desig,
          'barcode': barcode,
        });
      }
    }
    payload.sendPort.send(products);
  } catch (e) {
    payload.sendPort.send('ERROR:$e');
  }
}

int _findCol(List<String> headers, List<String> candidates) {
  for (final c in candidates) {
    final idx = headers.indexWhere((h) => h.contains(c));
    if (idx >= 0) return idx;
  }
  return 0; // fallback première colonne
}

String _cellVal(List<dynamic> row, int idx) {
  if (idx < 0 || idx >= row.length) return '';
  return row[idx]?.value?.toString().trim() ?? '';
}

// ─── Service public ───────────────────────────────────────────────────────────
class ImportService {
  ImportService._();
  static final ImportService instance = ImportService._();

  /// Sélectionne et importe un fichier Excel — parsing dans un Isolate
  Future<ImportResult> importFromExcel({
    void Function(int current, int total)? onProgress,
  }) async {
    // 1. Sélection du fichier
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return ImportResult(success: false, message: 'Aucun fichier sélectionné');
    }

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      return ImportResult(success: false, message: 'Impossible de lire le fichier');
    }

    // 2. Parsing dans un Isolate pour ne pas figer l'UI
    final products = await _parseInIsolate(bytes.toList());
    if (products == null) {
      return ImportResult(success: false, message: 'Erreur lors du parsing Excel');
    }

    // 3. Insertion batch en SQLite
    onProgress?.call(0, products.length);
    final count = await DatabaseService.instance.batchInsertProducts(products);
    onProgress?.call(count, products.length);

    return ImportResult(
      success: true,
      count: count,
      message: '$count produits importés avec succès',
    );
  }

  /// Import depuis Google Sheets via Apps Script
  Future<ImportResult> importFromGoogleSheets({
    required String scriptUrl,
    required String sheetUrl,
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      final uri = Uri.parse('$scriptUrl?action=import&sheetUrl=${Uri.encodeComponent(sheetUrl)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        return ImportResult(
          success: false,
          message: 'Erreur HTTP ${response.statusCode}',
        );
      }

      final List<dynamic> jsonList = json.decode(response.body);
      final products = jsonList.map((e) => Product(
            code: e['code']?.toString() ?? '',
            designation: e['designation']?.toString() ?? '',
            barcode: e['barcode']?.toString() ?? '',
          )).where((p) => p.code.isNotEmpty).toList();

      onProgress?.call(0, products.length);
      final count = await DatabaseService.instance.batchInsertProducts(products);
      onProgress?.call(count, products.length);

      return ImportResult(
        success: true,
        count: count,
        message: '$count produits importés depuis Google Sheets',
      );
    } catch (e) {
      return ImportResult(success: false, message: 'Erreur: $e');
    }
  }

  Future<List<Product>?> _parseInIsolate(List<int> bytes) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _parseExcelIsolate,
      _IsolatePayload(receivePort.sendPort, bytes),
    );

    final result = await receivePort.first;
    receivePort.close();
    isolate.kill();

    if (result is String && result.startsWith('ERROR:')) return null;

    final rawList = result as List<Map<String, String>>;
    return rawList.map((m) => Product(
          code: m['code']!,
          designation: m['designation']!,
          barcode: m['barcode']!,
        )).toList();
  }
}

class ImportResult {
  final bool success;
  final int count;
  final String message;

  const ImportResult({
    required this.success,
    this.count = 0,
    required this.message,
  });
}
