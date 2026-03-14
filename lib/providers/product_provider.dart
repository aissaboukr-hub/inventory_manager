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
  bool _importStatusSuccess = false;

  List<Product> get searchResults => _searchResults;
  int get productCount => _productCount;
  bool get loading => _loading;
  String get importStatus => _importStatus;
  double get importProgress => _importProgress;
  bool get importStatusSuccess => _importStatusSuccess;

  set importProgress(double progress) {
    _importProgress = progress;
    notifyListeners();
  }

  set importStatus(String status) {
    _importStatus = status;
    notifyListeners();
  }

  set importStatusSuccess(bool success) {
    _importStatusSuccess = success;
    notifyListeners();
  }

  Future<void> loadProductCount() async {
    _productCount = await _db.getProductCount();
    notifyListeners();
  }

  // Changement de la méthode pour retourner un Stream
  Stream<double> importFromExcel() async* {
    _loading = true;
    _importStatus = 'Lecture du fichier…';
    _importProgress = 0.0;
    notifyListeners();

    final result = await ImportService.instance.importFromExcel(
      onProgress: (current, total) {
        _importProgress = total > 0 ? current / total : 0;
        _importStatus = 'Insertion $current / $total produits…';
        notifyListeners();
      },
    );

    _loading = false;
    _importStatus = result.message;
    _importStatusSuccess = result.success;

    await loadProductCount();
    notifyListeners();

    // Utilisez un stream pour émettre la progression à chaque étape
    for (double i = 0; i <= 1; i += 0.1) {
      yield i;
    }

    yield 1.0;  // Fin de la progression
  }

  Future<ImportResult> importFromGoogleSheets({
    required String scriptUrl,
    required String sheetUrl,
  }) async {
    _loading = true;
    _importStatus = 'Connexion à Google Sheets…';
    _importProgress = 0.0;
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
    _importStatusSuccess = result.success;
    await loadProductCount();
    notifyListeners();
    return result;
  }
}
