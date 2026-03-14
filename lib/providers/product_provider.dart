import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../core/database/database_service.dart';
import '../services/import_service.dart';

class ProductProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;

  List<Product> _searchResults = [];
  int _productCount = 0;
  bool _loading = false;
  String _importStatus = '';
  double _importProgress = 0.0;
  bool _importStatusSuccess = false;  // Ajout de la propriété pour le statut d'importation

  List<Product> get searchResults => _searchResults;
  int get productCount => _productCount;
  bool get loading => _loading;
  String get importStatus => _importStatus;
  double get importProgress => _importProgress;
  bool get importStatusSuccess => _importStatusSuccess;  // Getter pour le succès

  // Setter pour la progression de l'importation
  set importProgress(double progress) {
    _importProgress = progress;
    notifyListeners();
  }

  // Setter pour le statut de l'importation
  set importStatus(String status) {
    _importStatus = status;
    notifyListeners();
  }

  // Setter pour indiquer si l'importation a réussi
  set importStatusSuccess(bool success) {
    _importStatusSuccess = success;
    notifyListeners();
  }

  Future<void> loadProductCount() async {
    _productCount = await _db.getProductCount();
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _searchResults = await _db.searchProducts(query);
    notifyListeners();
  }

  Future<Product?> findByBarcode(String barcode) async {
    return await _db.findProductByBarcode(barcode);
  }

  Future<void> saveProduct(Product product) async {
    await _db.insertOrUpdateProduct(product);
    await loadProductCount();
  }

  Future<void> deleteProduct(String code) async {
    await _db.deleteProduct(code);
    await loadProductCount();
    _searchResults.removeWhere((p) => p.code == code);
    notifyListeners();
  }

  // Méthode pour l'importation depuis Excel
  Future<ImportResult> importFromExcel() async {
    _loading = true;
    _importStatus = 'Lecture du fichier…';
    _importProgress = 0;
    notifyListeners();

    final result = await ImportService.instance.importFromExcel(
      onProgress: (current, total) {
        _importProgress = total > 0 ? current / total : 0;
        _importStatus =
            'Insertion $current / $total produits…';
        notifyListeners();
      },
    );

    _loading = false;
    _importStatus = result.message;
    _importStatusSuccess = result.success;  // Mise à jour du statut d'importation
    await loadProductCount();
    notifyListeners();
    return result;
  }

  // Méthode pour l'importation depuis Google Sheets
  Future<ImportResult> importFromGoogleSheets({
    required String scriptUrl,
    required String sheetUrl,
  }) async {
    _loading = true;
    _importStatus = 'Connexion à Google Sheets…';
    _importProgress = 0;
    notifyListeners();

    final result = await ImportService.instance.importFromGoogleSheets(
      scriptUrl: scriptUrl,
      sheetUrl: sheetUrl,
      onProgress: (current, total) {
        _importProgress = total > 0 ? current / total : 0;
        _importStatus = 'Insertion $current / $total produits…';
        notifyListeners();
      },
    );

    _loading = false;
    _importStatus = result.message;
    _importStatusSuccess = result.success;  // Mise à jour du statut d'importation
    await loadProductCount();
    notifyListeners();
    return result;
  }
}
