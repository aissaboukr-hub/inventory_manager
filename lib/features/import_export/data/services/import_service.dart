import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:inventory_manager/data/datasources/local/database.dart';

class ImportService {
  final AppDatabase _database;

  ImportService(this._database);

  Future<ImportResult> importFromExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return ImportResult.canceled();
    }

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();

    // Décoder le fichier Excel
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];

    if (sheet == null) {
      return ImportResult(
        successCount: 0,
        errorCount: 1,
        errors: ['Feuille de calcul vide'],
      );
    }

    final products = <ProductsCompanion>[];
    final errors = <String>[];

    // Commencer à la ligne 1 (après l'en-tête ligne 0)
    for (var i = 1; i < sheet.maxRows; i++) {
      try {
        final row = sheet.row(i);
        
        if (row.isEmpty) continue;

        final code = row[0]?.value?.toString().trim();
        final designation = row.length > 1 ? row[1]?.value?.toString().trim() : null;
        final barcode = row.length > 2 ? row[2]?.value?.toString().trim() : null;

        if (code == null || code.isEmpty) {
          errors.add('Ligne ${i + 1}: Code manquant');
          continue;
        }

        if (designation == null || designation.isEmpty) {
          errors.add('Ligne ${i + 1}: Désignation manquante pour $code');
          continue;
        }

        products.add(ProductsCompanion(
          code: drift.Value(code),
          designation: drift.Value(designation),
          barcode: drift.Value(barcode?.isEmpty ?? true ? null : barcode),
          category: const drift.Value.absent(),
          unit: const drift.Value('U'),
        ));
      } catch (e) {
        errors.add('Ligne ${i + 1}: Erreur - $e');
      }
    }

    if (products.isNotEmpty) {
      await _database.batchInsertProducts(products);
    }

    return ImportResult(
      successCount: products.length,
      errorCount: errors.length,
      errors: errors,
    );
  }

  Future<ImportResult> importFromGoogleSheets(String sheetId) async {
    throw UnimplementedError();
  }
}

class ImportResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;
  final bool canceled;

  ImportResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
    this.canceled = false,
  });

  ImportResult.canceled()
      : successCount = 0,
        errorCount = 0,
        errors = [],
        canceled = true;

  bool get hasErrors => errorCount > 0;
  bool get isSuccess => successCount > 0 && errorCount == 0;
}