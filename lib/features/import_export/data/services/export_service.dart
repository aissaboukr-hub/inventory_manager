import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:inventory_manager/data/datasources/local/database.dart';

class ExportService {
  final AppDatabase _database;

  ExportService(this._database);

  Future<String> exportToExcel(int inventoryId, String inventoryName) async {
    // Créer un nouveau fichier Excel
    final excel = Excel.createExcel();
    
    // Supprimer la feuille par défaut "Sheet1"
    excel.delete('Sheet1');
    
    // Feuille 1: Historique détaillé
    final historySheet = excel['Historique'];
    _setupHeader(historySheet, ['Code', 'Désignation', 'Code-barres', 'Quantité', 'Date', 'Notes']);
    
    // Feuille 2: Totaux
    final totalsSheet = excel['Totaux'];
    _setupHeader(totalsSheet, ['Code', 'Désignation', 'Code-barres', 'Quantité Totale', 'Unité', 'Dernière MàJ']);

    // Récupération des données
    final historyData = await _database.getInventoryForExport(inventoryId);
    final summaryData = await _database.getInventorySummary(inventoryId);

    // Remplissage Historique
    for (final row in historyData) {
      historySheet.appendRow([
        TextCellValue(row.code),
        TextCellValue(row.designation),
        TextCellValue(row.barcode ?? ''),
        DoubleCellValue(row.quantity),
        DateTimeCellValue(row.timestamp),
        TextCellValue(row.notes ?? ''),
      ]);
    }

    // Remplissage Totaux
    for (final row in summaryData) {
      totalsSheet.appendRow([
        TextCellValue(row.code),
        TextCellValue(row.designation),
        TextCellValue(row.barcode ?? ''),
        DoubleCellValue(row.totalQuantity),
        TextCellValue(row.unit),
        DateTimeCellValue(row.lastUpdate),
      ]);
    }

    // Sauvegarde
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = _sanitizeFileName(inventoryName);
    final fileName = 'Inventaire_${safeName}_$timestamp.xlsx';
    final filePath = '${directory.path}/$fileName';

    // Encoder et sauvegarder
    final fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception('Failed to encode Excel file');
    }

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    return filePath;
  }

  void _setupHeader(Sheet sheet, List<String> headers) {
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
  }

  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
}