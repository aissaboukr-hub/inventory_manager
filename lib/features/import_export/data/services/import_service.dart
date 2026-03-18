import 'dart:io';
import 'package:drift/drift.dart' as drift;  // ← AJOUTER CECI
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:inventory_manager/data/datasources/local/database.dart';
import 'package:inventory_manager/domain/entities/product.dart';

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

    final workbook = xlsio.Workbook.openStream(bytes);
    final worksheet = workbook.worksheets[0];

    final products = <ProductsCompanion>[];
    final errors = <String>[];

    // Start from row 2 (skip header)
    for (var i = 2; i <= worksheet.rows.count; i++) {
      try {
        final row = worksheet.rows[i - 1]; // 0-based index
        
        final code = row[0]?.text?.trim();
        final designation = row[1]?.text?.trim();
        final barcode = row[2]?.text?.trim();

        if (code == null || code.isEmpty) {
          errors.add('Ligne $i: Code manquant');
          continue;
        }

        if (designation == null || designation.isEmpty) {
          errors.add('Ligne $i: Désignation manquante pour $code');
          continue;
        }

        // ← CORRIGÉ: Utiliser directement ProductsCompanion
        products.add(ProductsCompanion(
          code: drift.Value(code),
          designation: drift.Value(designation),
          barcode: drift.Value(barcode?.isEmpty ?? true ? null : barcode),
          category: const drift.Value.absent(),
          unit: const drift.Value('U'),
        ));
      } catch (e) {
        errors.add('Ligne $i: Erreur - $e');
      }
    }

    workbook.dispose();

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
    // TODO: Implement Google Sheets import
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