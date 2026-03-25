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

// ============== CLASSES DE DONNÉES ==============

class InventoryItemWithProduct {
  final InventoryItem item;
  final Product product;

  InventoryItemWithProduct({required this.item, required this.product});

  int get id => item.id;
  int get inventoryId => item.inventoryId;
  int get productId => item.productId;
  double get quantity => item.quantity;
  DateTime get timestamp => item.timestamp;
  String? get notes => item.notes;
  String? get scannedBy => item.scannedBy;
  String get code => product.code;
  String get designation => product.designation;
  String? get barcode => product.barcode;
  String? get category => product.category;
  String get unit => product.unit;
}

class ProductSummary {
  final String code;
  final String designation;
  final String? barcode;
  final double totalQuantity;
  final String unit;
  final DateTime lastUpdate;

  ProductSummary({
    required this.code,
    required this.designation,
    this.barcode,
    required this.totalQuantity,
    required this.unit,
    required this.lastUpdate,
  });
}

// ============== DATABASE ==============

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
      await customStatement('CREATE INDEX idx_inventory_items_inventory_id ON inventory_items(inventory_id)');
      await customStatement('CREATE INDEX idx_inventory_items_product_id ON inventory_items(product_id)');
      await customStatement('CREATE INDEX idx_products_code ON products(code)');
      await customStatement('CREATE INDEX idx_products_barcode ON products(barcode)');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'inventory_database');
  }

  // ========== MÉTHODES D'EXPORT ==========

  Future<List<InventoryItemWithProduct>> getInventoryForExport(int inventoryId) async {
    final query = select(inventoryItems).join([
      innerJoin(products, products.id.equalsExp(inventoryItems.productId)),
    ])
      ..where(inventoryItems.inventoryId.equals(inventoryId))
      ..orderBy([OrderingTerm.desc(inventoryItems.timestamp)]);

    return query.map((row) {
      return InventoryItemWithProduct(
        item: row.readTable(inventoryItems),
        product: row.readTable(products),
      );
    }).get();
  }

  Future<List<ProductSummary>> getInventorySummary(int inventoryId) async {
    final query = customSelect('''
      SELECT 
        p.code,
        p.designation,
        p.barcode,
        p.unit,
        SUM(i.quantity) as total_quantity,
        MAX(i.timestamp) as last_update
      FROM products p
      INNER JOIN inventory_items i ON p.id = i.product_id
      WHERE i.inventory_id = ?
      GROUP BY p.id, p.code, p.designation, p.barcode, p.unit
    ''', variables: [Variable<int>(inventoryId)]);

    return query.map((row) {
      return ProductSummary(
        code: row.read<String>('code'),
        designation: row.read<String>('designation'),
        barcode: row.read<String?>('barcode'),
        totalQuantity: row.read<double>('total_quantity'),
        unit: row.read<String>('unit'),
        lastUpdate: row.read<DateTime>('last_update'),
      );
    }).get();
  }

  // ========== MÉTHODES D'IMPORT (OPTIMISÉES AVEC CHUNKS) ==========

  Future<void> batchInsertProducts(List<ProductsCompanion> productsList) async {
    if (productsList.isEmpty) return;
    
    // Limite SQLite: 999 variables / 7 colonnes = ~142 produits par batch
    // On prend 140 pour avoir une marge de sécurité
    const batchSize = 140;
    
    await transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Traiter par chunks pour éviter "too many SQL variables"
      for (var i = 0; i < productsList.length; i += batchSize) {
        final end = (i + batchSize < productsList.length) ? i + batchSize : productsList.length;
        final chunk = productsList.sublist(i, end);
        
        final valuesList = <String>[];
        final args = <dynamic>[];
        
        for (final product in chunk) {
          valuesList.add('(?, ?, ?, ?, ?, ?, ?)');
          args.addAll([
            product.code.value,
            product.designation.value,
            product.barcode.value,
            product.category.value,
            product.unit.value,
            now,
            now,
          ]);
        }
        
        await customStatement('''
          INSERT INTO products (code, designation, barcode, category, unit, created_at, updated_at)
          VALUES ${valuesList.join(', ')}
          ON CONFLICT(code) DO UPDATE SET
            designation = excluded.designation,
            barcode = excluded.barcode,
            category = excluded.category,
            unit = excluded.unit,
            updated_at = excluded.updated_at
        ''', args);
      }
    });
  }

  // ========== MÉTHODES UTILITAIRES ==========

  Future<List<Product>> searchProducts(String query) async {
    final searchTerm = '%$query%';
    return (select(products)
      ..where((p) => p.code.like(searchTerm) | p.designation.like(searchTerm) | p.barcode.like(searchTerm)))
      .get();
  }

  Future<Product?> getProductByCode(String code) async {
    return (select(products)..where((p) => p.code.equals(code))).getSingleOrNull();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    return (select(products)..where((p) => p.barcode.equals(barcode))).getSingleOrNull();
  }

  Future<int> createInventory(String name, {String? description}) async {
    final companion = InventoriesCompanion(
      name: Value(name),
      description: Value(description),
    );
    return await into(inventories).insert(companion);
  }

  Future<void> addInventoryItem({
    required int inventoryId,
    required int productId,
    required double quantity,
    String? notes,
    String? scannedBy,
  }) async {
    await into(inventoryItems).insert(InventoryItemsCompanion(
      inventoryId: Value(inventoryId),
      productId: Value(productId),
      quantity: Value(quantity),
      notes: Value(notes),
      scannedBy: Value(scannedBy),
    ));
  }

  Future<List<Inventory>> getActiveInventories() async {
    return (select(inventories)..where((i) => i.isActive.equals(true))).get();
  }

  Future<void> closeInventory(int inventoryId) async {
    await (update(inventories)..where((i) => i.id.equals(inventoryId))).write(
      InventoriesCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}