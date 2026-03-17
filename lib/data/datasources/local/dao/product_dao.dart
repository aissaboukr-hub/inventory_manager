import 'package:drift/drift.dart';
import '../database.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  // ============== CRUD OPERATIONS ==============

  Future<List<Product>> getAllProducts({
    int limit = 50,
    int offset = 0,
    String? category,
  }) async {
    var query = select(products)
      ..orderBy([(p) => OrderingTerm.asc(p.designation)])
      ..limit(limit, offset: offset);
    
    if (category != null) {
      query = query..where((p) => p.category.equals(category));
    }
    
    return query.get();
  }

  Future<Product?> getProductById(int id) async {
    return (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<Product?> getProductByCode(String code) async {
    return (select(products)..where((p) => p.code.equals(code))).getSingleOrNull();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    return (select(products)..where((p) => p.barcode.equals(barcode))).getSingleOrNull();
  }

  Future<int> insertProduct({
    required String code,
    required String designation,
    String? barcode,
    String? category,
    String unit = 'U',
  }) async {
    return into(products).insert(
      ProductsCompanion(
        code: Value(code),
        designation: Value(designation),
        barcode: Value(barcode),
        category: Value(category),
        unit: Value(unit),
      ),
    );
  }

  Future<bool> updateProduct(Product product) async {
    return update(products).replace(product);
  }

  Future<int> deleteProduct(int id) async {
    return (delete(products)..where((p) => p.id.equals(id))).go();
  }

  // ============== SEARCH OPERATIONS ==============

  Future<List<Product>> searchProducts(
    String query, {
    int limit = 50,
    SearchMode mode = SearchMode.all,
  }) async {
    final lowerQuery = query.toLowerCase();
    final pattern = '%$lowerQuery%';

    var selectQuery = select(products);

    switch (mode) {
      case SearchMode.code:
        selectQuery = selectQuery..where((p) => p.code.lower().like(pattern));
        break;
      case SearchMode.designation:
        selectQuery = selectQuery..where((p) => p.designation.lower().like(pattern));
        break;
      case SearchMode.barcode:
        selectQuery = selectQuery..where((p) => p.barcode.lower().like(pattern));
        break;
      case SearchMode.all:
        selectQuery = selectQuery..where((p) => 
          p.code.lower().like(pattern) |
          p.designation.lower().like(pattern) |
          p.barcode.lower().like(pattern)
        );
        break;
    }

    return (selectQuery
      ..orderBy([(p) => OrderingTerm.asc(p.designation)])
      ..limit(limit)
    ).get();
  }

  Future<List<Product>> advancedSearch({
    String? code,
    String? designation,
    String? barcode,
    String? category,
    int limit = 50,
  }) async {
    var query = select(products);

    if (code != null && code.isNotEmpty) {
      query = query..where((p) => p.code.lower().contains(code.toLowerCase()));
    }
    if (designation != null && designation.isNotEmpty) {
      query = query..where((p) => p.designation.lower().contains(designation.toLowerCase()));
    }
    if (barcode != null && barcode.isNotEmpty) {
      query = query..where((p) => p.barcode.equals(barcode));
    }
    if (category != null && category.isNotEmpty) {
      query = query..where((p) => p.category.equals(category));
    }

    return (query
      ..orderBy([(p) => OrderingTerm.asc(p.designation)])
      ..limit(limit)
    ).get();
  }

  // ============== BATCH OPERATIONS ==============

  Future<void> batchInsert(List<ProductsCompanion> items) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(products, items);
    });
  }

  Future<void> batchDelete(List<int> ids) async {
    await (delete(products)..where((p) => p.id.isIn(ids))).go();
  }

  // ============== STATISTICS ==============

  Future<List<String>> getAllCategories() async {
    final query = customSelect(
      'SELECT DISTINCT category FROM products WHERE category IS NOT NULL ORDER BY category',
    );
    final result = await query.get();
    return result.map((r) => r.read<String>('category')).toList();
  }

  Future<int> getProductCount() async {
    final result = await customSelect('SELECT COUNT(*) as count FROM products').getSingle();
    return result.read<int>('count');
  }

  Future<int> getProductCountByCategory(String category) async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM products WHERE category = ?',
      variables: [Variable.withString(category)],
    ).getSingle();
    return result.read<int>('count');
  }

  // ============== VALIDATION ==============

  Future<bool> codeExists(String code, {int? excludeId}) async {
    var query = select(products)..where((p) => p.code.equals(code));
    if (excludeId != null) {
      query = query..where((p) => p.id.isNotValue(excludeId));
    }
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<bool> barcodeExists(String barcode, {int? excludeId}) async {
    var query = select(products)..where((p) => p.barcode.equals(barcode));
    if (excludeId != null) {
      query = query..where((p) => p.id.isNotValue(excludeId));
    }
    final result = await query.get();
    return result.isNotEmpty;
  }

  // ============== MAINTENANCE ==============

  Future<void> updateTimestamps() async {
    await customStatement(
      'UPDATE products SET updated_at = ? WHERE updated_at IS NULL',
      [Variable.withDateTime(DateTime.now())],
    );
  }

  Future<List<Product>> getOrphanedProducts() async {
    return customSelect('''
      SELECT p.* FROM products p
      LEFT JOIN inventory_items i ON p.id = i.product_id
      WHERE i.id IS NULL
    ''').map((row) => Product(
      id: row.read<int>('id'),
      code: row.read<String>('code'),
      designation: row.read<String>('designation'),
      barcode: row.read<String?>('barcode'),
      category: row.read<String?>('category'),
      unit: row.read<String>('unit'),
      createdAt: row.read<DateTime>('created_at'),
      updatedAt: row.read<DateTime>('updated_at'),
    )).get();
  }
}

enum SearchMode {
  all,
  code,
  designation,
  barcode,
}