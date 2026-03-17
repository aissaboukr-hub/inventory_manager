import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:inventory_manager/data/datasources/local/database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExportService {
  final AppDatabase _database;

  ExportService(this._database);

  Future<String> exportToExcel(int inventoryId, String inventoryName) async {
    final workbook = Workbook();

    // Feuille 1: Historique détaillé
    final historySheet = workbook.worksheets[0];
    historySheet.name = 'Historique';
    _setupHistorySheet(historySheet);

    // Feuille 2: Totaux
    final totalsSheet = workbook.worksheets.add();
    totalsSheet.name = 'Totaux';
    _setupTotalsSheet(totalsSheet);

    // Récupération des données
    final historyData = await _database.getInventoryForExport(inventoryId);
    final summaryData = await _database.getInventorySummary(inventoryId);

    // Remplissage Historique
    for (var i = 0; i < historyData.length; i++) {
      final row = historyData[i];
      historySheet.getRangeByIndex(i + 2, 1).setText(row.code);
      historySheet.getRangeByIndex(i + 2, 2).setText(row.designation);
      historySheet.getRangeByIndex(i + 2, 3).setText(row.barcode ?? '');
      historySheet.getRangeByIndex(i + 2, 4).setNumber(row.quantity);
      historySheet.getRangeByIndex(i + 2, 5).setDateTime(row.timestamp);
      historySheet.getRangeByIndex(i + 2, 6).setText(row.notes ?? '');
    }

    // Remplissage Totaux
    for (var i = 0; i < summaryData.length; i++) {
      final row = summaryData[i];
      totalsSheet.getRangeByIndex(i + 2, 1).setText(row.code);
      totalsSheet.getRangeByIndex(i + 2, 2).setText(row.designation);
      totalsSheet.getRangeByIndex(i + 2, 3).setText(row.barcode ?? '');
      totalsSheet.getRangeByIndex(i + 2, 4).setNumber(row.totalQuantity);
      totalsSheet.getRangeByIndex(i + 2, 5).setText(row.unit);
      totalsSheet.getRangeByIndex(i + 2, 6).setDateTime(row.lastUpdate);
    }

    // Auto-fit columns
    for (var i = 1; i <= 6; i++) {
      historySheet.getRangeByIndex(1, i, historyData.length + 1, i).autoFitColumns();
      totalsSheet.getRangeByIndex(1, i, summaryData.length + 1, i).autoFitColumns();
    }

    // Sauvegarde
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Inventaire_${_sanitizeFileName(inventoryName)}_$timestamp.xlsx';
    final filePath = '${directory.path}/$fileName';

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  void _setupHistorySheet(Worksheet sheet) {
    final headers = ['Code', 'Désignation', 'Code-barres', 'Quantité', 'Date', 'Notes'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#4472C4';
      cell.cellStyle.fontColor = '#FFFFFF';
      cell.cellStyle.fontSize = 11;
    }
  }

  void _setupTotalsSheet(Worksheet sheet) {
    final headers = ['Code', 'Désignation', 'Code-barres', 'Quantité Totale', 'Unité', 'Dernière MàJ'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#70AD47';
      cell.cellStyle.fontColor = '#FFFFFF';
      cell.cellStyle.fontSize = 11;
    }
  }

  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}

class GoogleSheetsService {
  static const String _scriptUrl = 'https://script.google.com/macros/s/VOTRE_SCRIPT_ID/exec';

  Future<Map<String, dynamic>> exportToGoogleSheets(
    int inventoryId,
    String inventoryName,
    List<InventorySummary> data,
  ) async {
    final payload = {
      'inventoryName': inventoryName,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data.map((e) => {
        'code': e.code,
        'designation': e.designation,
        'barcode': e.barcode,
        'quantity': e.totalQuantity,
        'unit': e.unit,
        'lastUpdate': e.lastUpdate.toIso8601String(),
      }).toList(),
    };

    final response = await http.post(
      Uri.parse(_scriptUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Export failed: ${response.body}');
    }

    return jsonDecode(response.body);
  }
}

class InventorySummary {
  final String code;
  final String designation;
  final String? barcode;
  final double totalQuantity;
  final String unit;
  final DateTime lastUpdate;

  InventorySummary({
    required this.code,
    required this.designation,
    this.barcode,
    required this.totalQuantity,
    required this.unit,
    required this.lastUpdate,
  });
}