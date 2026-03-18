import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:inventory_manager/data/datasources/local/database.dart';

class ExportService {
  final AppDatabase _database;

  ExportService(this._database);

  Future<String> exportToExcel(int inventoryId, String inventoryName) async {
    final excel = Excel.createExcel();
    
    excel.delete('Sheet1');
    
    final historySheet = excel['Historique'];
    _setupHeader(historySheet, ['Code', 'Désignation', 'Code-barres', 'Quantité', 'Date', 'Notes']);
    
    final totalsSheet = excel['Totaux'];
    _setupHeader(totalsSheet, ['Code', 'Désignation', 'Code-barres', 'Quantité Totale', 'Unité', 'Dernière MàJ']);

    final historyData = await _database.getInventoryForExport(inventoryId);
    final summaryData = await _database.getInventorySummary(inventoryId);

    for (final row in historyData) {
      historySheet.appendRow([
        TextCellValue(row.code),
        TextCellValue(row.designation),
        TextCellValue(row.barcode ?? ''),
        DoubleCellValue(row.quantity),
        DateTimeCellValue(
          year: row.timestamp.year,
          month: row.timestamp.month,
          day: row.timestamp.day,
          hour: row.timestamp.hour,
          minute: row.timestamp.minute,
        ),
        TextCellValue(row.notes ?? ''),
      ]);
    }

    for (final row in summaryData) {
      totalsSheet.appendRow([
        TextCellValue(row.code),
        TextCellValue(row.designation),
        TextCellValue(row.barcode ?? ''),
        DoubleCellValue(row.totalQuantity),
        TextCellValue(row.unit),
        DateTimeCellValue(
          year: row.lastUpdate.year,
          month: row.lastUpdate.month,
          day: row.lastUpdate.day,
          hour: row.lastUpdate.hour,
          minute: row.lastUpdate.minute,
        ),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = _sanitizeFileName(inventoryName);
    final fileName = 'Inventaire_${safeName}_$timestamp.xlsx';
    final filePath = '${directory.path}/$fileName';

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
    
    final headerRowIndex = 0;
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: headerRowIndex));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }
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