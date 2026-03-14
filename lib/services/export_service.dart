import 'dart:isolate';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/inventory_entry.dart';
import '../core/database/database_service.dart';

// ─── Payload Isolate ──────────────────────────────────────────────────────────
class _ExportPayload {
  final SendPort sendPort;
  final List<Map<String, dynamic>> entries;
  final List<Map<String, dynamic>> totals;
  _ExportPayload(this.sendPort, this.entries, this.totals);
}

// ─── Génération Excel dans un Isolate ─────────────────────────────────────────
void _buildExcelIsolate(_ExportPayload payload) {
  try {
    final excel = Excel.createExcel();

    // ── Feuille 1 : Historique ──────────────────────────────────────────────
    final histSheet = excel['Historique'];
    excel.setDefaultSheet('Historique');

    final headers = ['Code', 'Désignation', 'Code-barres', 'Quantité', 'Date'];
    for (int col = 0; col < headers.length; col++) {
      final cell = histSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E88E5'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    for (int i = 0; i < payload.entries.length; i++) {
      final e = payload.entries[i];
      final row = i + 1;
      histSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(e['product_code']?.toString() ?? '');
      histSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(e['designation']?.toString() ?? '');
      histSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(e['barcode']?.toString() ?? '');
      histSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = DoubleCellValue((e['quantity'] as num).toDouble());
      histSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(e['date']?.toString() ?? '');
    }

    // ── Feuille 2 : Totaux ─────────────────────────────────────────────────
    final totSheet = excel['Totaux'];
    final totHeaders = ['Code', 'Désignation', 'Code-barres', 'Quantité Totale'];
    for (int col = 0; col < totHeaders.length; col++) {
      final cell = totSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(totHeaders[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#43A047'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }
    for (int i = 0; i < payload.totals.length; i++) {
      final t = payload.totals[i];
      final row = i + 1;
      totSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(t['product_code']?.toString() ?? '');
      totSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(t['designation']?.toString() ?? '');
      totSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(t['barcode']?.toString() ?? '');
      totSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = DoubleCellValue((t['total_quantity'] as num).toDouble());
    }

    // Supprimer la feuille par défaut
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

    final bytes = excel.encode()!;
    payload.sendPort.send(bytes);
  } catch (e) {
    payload.sendPort.send('ERROR:$e');
  }
}

// ─── Service public ───────────────────────────────────────────────────────────
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  /// Génère et partage le fichier Excel
  Future<ExportResult> exportToExcel({
    required String inventoryId,
    required String inventoryName,
  }) async {
    try {
      final entries = await DatabaseService.instance
          .getEntriesByInventory(inventoryId);
      final totals = await DatabaseService.instance
          .getTotalsByInventory(inventoryId);

      // Construction Excel dans un Isolate
      final bytes = await _buildInIsolate(
        entries.map((e) => e.toMap()).toList(),
        totals,
      );
      if (bytes == null) {
        return ExportResult(
            success: false, message: 'Erreur lors de la génération Excel');
      }

      // Sauvegarde temporaire
      final dir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName =
          'inventaire_${inventoryName.replaceAll(' ', '_')}_$dateStr.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Partage
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: 'Inventaire - $inventoryName',
      );

      return ExportResult(
        success: true,
        filePath: file.path,
        message: 'Export réussi : $fileName',
      );
    } catch (e) {
      return ExportResult(success: false, message: 'Erreur: $e');
    }
  }

  /// Export vers Google Sheets via Apps Script
  Future<ExportResult> exportToGoogleSheets({
    required String scriptUrl,
    required String inventoryId,
    required String inventoryName,
  }) async {
    try {
      final entries = await DatabaseService.instance
          .getEntriesByInventory(inventoryId);

      final payload = {
        'action': 'export',
        'inventoryName': inventoryName,
        'entries': entries
            .map((e) => {
                  'code': e.productCode,
                  'designation': e.designation,
                  'barcode': e.barcode,
                  'quantity': e.quantity,
                  'date': DateFormat('dd/MM/yyyy HH:mm').format(e.date),
                })
            .toList(),
      };

      final response = await http
          .post(
            Uri.parse(scriptUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return ExportResult(
          success: result['success'] == true,
          message: result['success'] == true
              ? '${result['count']} lignes exportées vers Google Sheets'
              : 'Erreur Apps Script',
        );
      }
      return ExportResult(
          success: false, message: 'Erreur HTTP ${response.statusCode}');
    } catch (e) {
      return ExportResult(success: false, message: 'Erreur: $e');
    }
  }

  Future<List<int>?> _buildInIsolate(
    List<Map<String, dynamic>> entries,
    List<Map<String, dynamic>> totals,
  ) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _buildExcelIsolate,
      _ExportPayload(receivePort.sendPort, entries, totals),
    );

    final result = await receivePort.first;
    receivePort.close();
    isolate.kill();

    if (result is String && result.startsWith('ERROR:')) return null;
    return result as List<int>;
  }
}

class ExportResult {
  final bool success;
  final String message;
  final String? filePath;

  const ExportResult({
    required this.success,
    required this.message,
    this.filePath,
  });
}
