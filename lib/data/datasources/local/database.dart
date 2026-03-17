import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ============== TABLES ==============

class Inventories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get description => text().nullable()();
  
  @override
  List<String> get customConstraints => [
    'UNIQUE(name)'
  ];
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 1, max: 50)();
  TextColumn get designation => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('U'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  List<String> get customConstraints => [
    'UNIQUE(code)',
    'UNIQUE(barcode)'
  ];
}

class InventoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get inventoryId => integer().references(Inventories, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  RealColumn get quantity => real()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  TextColumn get scannedBy => text().nullable()();
  
  @override
  List<String> get customConstraints => [
    'CHECK(quantity != 0)'
  ];
}

// ============== INDEXES ==============

@DriftDatabase(
  tables: [Inventories, Products, InventoryItems],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Création d'index pour performances
      await customStatement('CREATE INDEX idx_products_barcode ON products(barcode)');
      await customStatement('CREATE INDEX idx_products_code ON products(code)');
      await customStatement('CREATE INDEX idx_products_designation ON products(designation)');
      await customStatement('CREATE INDEX idx_items_inventory ON inventory_items(inventory_id)');
      await customStatement('CREATE INDEX idx_items_product ON inventory_items(product_id)');
      await customStatement('CREATE INDEX idx_items_timestamp ON inventory_items(timestamp)');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'inventory_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  // ============== INVENTORY METHODS ==============

  Future<List<Inventory>> getAllInventories() async {
    return (select(inventories)
      ..where((i) => i.isActive.equals(true))
      ..orderBy([(i) => OrderingTerm.desc(i.updatedAt)])
    ).get();
  }

  Future<Inventory> getInventory(int id) async {
    return (select(inventories)..where((i) => i.id.equals(id))).getSingle();
  }

  Future<int> createInventory(String name, {String? description}) async {
    final id = await into(inventories).insert(
      InventoriesCompanion(
        name: Value(name),
        description: Value(description),
      ),
    );
    return id;
  }

  Future<bool> updateInventory(int id, String name, {String? description}) async {
    return update(inventories).replace(
      InventoriesCompanion(
        id: Value(id),
        name: Value(name),
        description: Value(description),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteInventory(int id) async {
    return (delete(inventories)..where((i) => i.id.equals(id))).go();
  }

  Future<void> softDeleteInventory(int id) async {
    await update(inventories).write(
      InventoriesCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============== PRODUCT METHODS ==============

  Future<List<Product>> getAllProducts({
    int limit = 50,
    int offset = 0,
  }) async {
    return (select(products)
      ..orderBy([(p) => OrderingTerm.asc(p.designation)])
      ..limit(limit, offset: offset)
    ).get();
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

  Future<List<Product>> searchProducts(
    String query, {
    int limit = 50,
  }) async {
    final lowerQuery = query.toLowerCase();
    return (select(products)
      ..where((p) => 
        p.code.lower().contains(lowerQuery) |
        p.designation.lower().contains(lowerQuery) |
        p.barcode.lower().contains(lowerQuery)
      )
      ..limit(limit)
    ).get();
  }

  Future<int> createProduct({
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
    return update(products).replace(product.copyWith(
      updatedAt: DateTime.now(),
    ));
  }

  Future<int> deleteProduct(int id) async {
    return (delete(products)..where((p) => p.id.equals(id))).go();
  }

  // Batch insert pour import
  Future<void> batchInsertProducts(List<ProductsCompanion> items) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(products, items);
    });
  }

  // ============== INVENTORY ITEMS METHODS ==============

  Future<List<InventoryItemWithProduct>> getInventoryItems(
    int inventoryId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final query = customSelect(
      '''
      SELECT 
        i.id as item_id,
        i.quantity,
        i.timestamp,
        i.notes,
        i.scanned_by,  // ← AJOUTER
        p.id as product_id,
        p.code as product_code,
        p.designation as product_designation,
        p.barcode as product_barcode,
        p.unit as product_unit
      FROM inventory_items i
      JOIN products p ON i.product_id = p.id
      WHERE i.inventory_id = ?
      ORDER BY i.timestamp DESC
      LIMIT ? OFFSET ?
      ''',
      variables: [
        Variable.withInt(inventoryId),
        Variable.withInt(limit),
        Variable.withInt(offset),
      ],
    );

    return query.map((row) => InventoryItemWithProduct(
      itemId: row.read<int>('item_id'),
      quantity: row.read<double>('quantity'),
      timestamp: row.read<DateTime>('timestamp'),
      notes: row.read<String?>('notes'),
      scannedBy: row.read<String?>('scanned_by'),  // ← AJOUTER
      productId: row.read<int>('product_id'),
      productCode: row.read<String>('product_code'),
      productDesignation: row.read<String>('product_designation'),
      productBarcode: row.read<String?>('product_barcode'),
      productUnit: row.read<String>('product_unit'),
    )).get();
  }

  Future<int> addInventoryItem({
    required int inventoryId,
    required int productId,
    required double quantity,
    String? notes,
    String? scannedBy,
  }) async {
    // Mettre à jour le timestamp de l'inventaire
    await update(inventories).write(
      InventoriesCompanion(updatedAt: Value(DateTime.now())),
    );

    return into(inventoryItems).insert(
      InventoryItemsCompanion(
        inventoryId: Value(inventoryId),
        productId: Value(productId),
        quantity: Value(quantity),
        notes: Value(notes),
        scannedBy: Value(scannedBy),
      ),
    );
  }

  Future<bool> updateInventoryItem(int itemId, double quantity, {String? notes}) async {
    return update(inventoryItems).replace(
      InventoryItemsCompanion(
        id: Value(itemId),
        quantity: Value(quantity),
        notes: Value(notes),
      ),
    );
  }

  Future<int> deleteInventoryItem(int itemId) async {
    return (delete(inventoryItems)..where((i) => i.id.equals(itemId))).go();
  }

  // ============== AGGREGATION METHODS ==============

  Future<List<InventorySummary>> getInventorySummary(int inventoryId) async {
    final query = customSelect(
      '''
      SELECT 
        p.id as product_id,
        p.code,
        p.designation,
        p.barcode,
        p.unit,
        SUM(i.quantity) as total_quantity,
        COUNT(i.id) as entry_count,
        MAX(i.timestamp) as last_update
      FROM inventory_items i
      JOIN products p ON i.product_id = p.id
      WHERE i.inventory_id = ?
      GROUP BY p.id
      HAVING total_quantity != 0
      ORDER BY p.designation ASC
      ''',
      variables: [Variable.withInt(inventoryId)],
    );

    return query.map((row) => InventorySummary(
      productId: row.read<int>('product_id'),
      code: row.read<String>('code'),
      designation: row.read<String>('designation'),
      barcode: row.read<String?>('barcode'),
      unit: row.read<String>('unit'),
      totalQuantity: row.read<double>('total_quantity'),
      entryCount: row.read<int>('entry_count'),
      lastUpdate: row.read<DateTime>('last_update'),
    )).get();
  }

  Future<InventoryStats> getInventoryStats(int inventoryId) async {
    final countResult = await customSelect(
      'SELECT COUNT(DISTINCT product_id) as product_count, '
      'SUM(quantity) as total_items FROM inventory_items WHERE inventory_id = ?',
      variables: [Variable.withInt(inventoryId)],
    ).getSingle();

    return InventoryStats(
      productCount: countResult.read<int>('product_count'),
      totalItems: countResult.read<double>('total_items'),
    );
  }

  // ============== EXPORT METHODS ==============

  Future<List<InventoryExportRow>> getInventoryForExport(int inventoryId) async {
    final query = customSelect(
      '''
      SELECT 
        p.code,
        p.designation,
        p.barcode,
        i.quantity,
        i.timestamp,
        i.notes
      FROM inventory_items i
      JOIN products p ON i.product_id = p.id
      WHERE i.inventory_id = ?
      ORDER BY i.timestamp ASC
      ''',
      variables: [Variable.withInt(inventoryId)],
    );

    return query.map((row) => InventoryExportRow(
      code: row.read<String>('code'),
      designation: row.read<String>('designation'),
      barcode: row.read<String?>('barcode'),
      quantity: row.read<double>('quantity'),
      timestamp: row.read<DateTime>('timestamp'),
      notes: row.read<String?>('notes'),
    )).get();
  }

  // Nettoyer les doublons potentiels
  Future<void> cleanupDuplicateItems(int inventoryId) async {
    await customStatement('''
      DELETE FROM inventory_items 
      WHERE id NOT IN (
        SELECT MIN(id) 
        FROM inventory_items 
        WHERE inventory_id = ?
        GROUP BY product_id, timestamp
      ) AND inventory_id = ?
    ''', [inventoryId, inventoryId]);
  }
}

// ============== DATA CLASSES ==============

class InventoryItemWithProduct {
  final int itemId;
  final double quantity;
  final DateTime timestamp;
  final String? notes;
  final String? scannedBy;  // ← AJOUTER
  final int productId;
  final String productCode;
  final String productDesignation;
  final String? productBarcode;
  final String productUnit;
  final String? productCategory;

  InventoryItemWithProduct({
    required this.itemId,
    required this.quantity,
    required this.timestamp,
    this.notes,
    this.scannedBy,  // ← AJOUTER
    required this.productId,
    required this.productCode,
    required this.productDesignation,
    this.productBarcode,
    required this.productUnit,
    this.productCategory,
  });
}

class InventorySummary {
  final int productId;
  final String code;
  final String designation;
  final String? barcode;
  final String unit;
  final double totalQuantity;
  final int entryCount;
  final DateTime lastUpdate;

  InventorySummary({
    required this.productId,
    required this.code,
    required this.designation,
    this.barcode,
    required this.unit,
    required this.totalQuantity,
    required this.entryCount,
    required this.lastUpdate,
  });
}

class InventoryStats {
  final int productCount;
  final double totalItems;

  InventoryStats({
    required this.productCount,
    required this.totalItems,
  });
}

class InventoryExportRow {
  final String code;
  final String designation;
  final String? barcode;
  final double quantity;
  final DateTime timestamp;
  final String? notes;

  InventoryExportRow({
    required this.code,
    required this.designation,
    this.barcode,
    required this.quantity,
    required this.timestamp,
    this.notes,
  });
}