import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelHelper {
  /// Crée un fichier Excel avec les headers spécifiés
  static Workbook createWorkbook(List<String> headers, {String sheetName = 'Sheet1'}) {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = sheetName;
    
    // Style header
    final headerStyle = CellStyle(workbook);
    headerStyle.bold = true;
    headerStyle.backColor = '#4472C4';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.fontSize = 11;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;
    
    // Écriture headers
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle = headerStyle;
    }
    
    // Freeze panes
    sheet.getRangeByIndex(2, 1).freezePanes();
    
    return workbook;
  }

  /// Ajoute une ligne de données
  static void addRow(Worksheet sheet, int rowIndex, List<dynamic> values) {
    for (var i = 0; i < values.length; i++) {
      final cell = sheet.getRangeByIndex(rowIndex, i + 1);
      final value = values[i];
      
      if (value is String) {
        cell.setText(value);
      } else if (value is num) {
        cell.setNumber(value.toDouble());
      } else if (value is DateTime) {
        cell.setDateTime(value);
        cell.numberFormat = 'dd/mm/yyyy hh:mm';
      } else if (value == null) {
        cell.setText('');
      } else {
        cell.setText(value.toString());
      }
    }
  }

  /// Applique un style de cellule conditionnel
  static void applyConditionalFormatting(
    Worksheet sheet,
    int row,
    int column,
    String condition, {
    String? backColor,
    String? fontColor,
  }) {
    final cell = sheet.getRangeByIndex(row, column);
    
    if (backColor != null) {
      cell.cellStyle.backColor = backColor;
    }
    if (fontColor != null) {
      cell.cellStyle.fontColor = fontColor;
    }
  }

  /// Auto-fit toutes les colonnes
  static void autoFitColumns(Worksheet sheet, int columnCount) {
    for (var i = 1; i <= columnCount; i++) {
      sheet.getRangeByIndex(1, i).autoFitColumns();
    }
  }

  /// Sauvegarde et partage le fichier
  static Future<String> saveAndShare(
    Workbook workbook,
    String fileName, {
    bool share = true,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = _sanitizeFileName(fileName);
    final filePath = '${directory.path}/${safeFileName}_$timestamp.xlsx';
    
    final bytes = workbook.saveAsStream();
    workbook.dispose();
    
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    
    if (share) {
      await Share.shareXFiles([XFile(filePath)]);
    }
    
    return filePath;
  }

  /// Lit un fichier Excel et retourne les données
  static List<List<dynamic>> readExcelFile(String filePath) {
    final file = File(filePath);
    final bytes = file.readAsBytesSync();
    final workbook = Workbook.openStream(bytes);
    
    final sheet = workbook.worksheets[0];
    final data = <List<dynamic>>[];
    
    for (var i = 1; i <= sheet.rows.count; i++) {
      final row = sheet.rows[i - 1];
      final rowData = <dynamic>[];
      
      for (var j = 0; j < row.length; j++) {
        final cell = row[j];
        if (cell != null) {
          rowData.add(cell.text ?? cell.number ?? cell.dateTime);
        } else {
          rowData.add(null);
        }
      }
      
      data.add(rowData);
    }
    
    workbook.dispose();
    return data;
  }

  /// Validation des données d'import
  static ImportValidationResult validateImportData(
    List<List<dynamic>> data, {
    required int requiredColumns,
    int headerRow = 0,
  }) {
    final errors = <String>[];
    final validRows = <List<dynamic>>[];
    
    if (data.isEmpty) {
      return ImportValidationResult(
        isValid: false,
        errors: ['Fichier vide'],
        validRows: [],
      );
    }
    
    // Skip header row
    final startIndex = headerRow + 1;
    
    for (var i = startIndex; i < data.length; i++) {
      final row = data[i];
      
      if (row.length < requiredColumns) {
        errors.add('Ligne ${i + 1}: Nombre de colonnes insuffisant');
        continue;
      }
      
      // Vérification première colonne (code) non vide
      if (row[0] == null || row[0].toString().trim().isEmpty) {
        errors.add('Ligne ${i + 1}: Code produit manquant');
        continue;
      }
      
      validRows.add(row);
    }
    
    return ImportValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      validRows: validRows,
    );
  }

  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
}

class ImportValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<List<dynamic>> validRows;

  ImportValidationResult({
    required this.isValid,
    required this.errors,
    required this.validRows,
  });

  int get errorCount => errors.length;
  int get validRowCount => validRows.length;
}