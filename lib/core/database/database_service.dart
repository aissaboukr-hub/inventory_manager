import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/product.dart';
import '../../models/inventory.dart';
import '../../models/inventory_entry.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<void> init() async => await database;

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        // Assurez-vous que les PRAGMA sont exécutées correctement avant toute requête
        await db.execute('PRAGMA journal_mode=WAL');
        await db.execute('PRAGMA synchronous=NORMAL');
        await db.execute('PRAGMA cache_size=10000');
        await db.execute('PRAGMA foreign_keys=ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        code      TEXT PRIMARY KEY,
        designation TEXT NOT NULL,
        barcode   TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('CREATE INDEX idx_product_barcode ON products(barcode)');
    await db.execute(
        'CREATE INDEX idx_product_designation ON products(designation)');

    await db.execute('''
      CREATE TABLE inventories (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_active  INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_entries (
        id           TEXT PRIMARY KEY,
        inventory_id TEXT NOT NULL,
        product_code TEXT NOT NULL,
        designation  TEXT NOT NULL,
        barcode      TEXT NOT NULL DEFAULT '',
        quantity     REAL NOT NULL,
        date         TEXT NOT NULL,
        FOREIGN KEY (inventory_id) REFERENCES inventories(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_entry_inventory ON inventory_entries(inventory_id)');
    await db.execute(
        'CREATE INDEX idx_entry_barcode ON inventory_entries(barcode)');
  }

  // ─── PRODUCTS ──────────────────────────────────────────────────────────────

  Future<int> batchInsertProducts(List<Product> products) async {
    final db = await database;
    const chunkSize = 500;
    int total = 0;

    for (int i = 0; i < products.length; i += chunkSize) {
      final chunk =
          products.sublist(i, (i + chunkSize).clamp(0, products.length));

      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final p in chunk) {
          batch.insert(
            'products',
            p.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        total += chunk.length;
      });
    }
    return total;
  }

  Future<Product?> findProductByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  Future<Product?> findProductByCode(String code) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  Future<List<Product>> searchProducts(String query, {int limit = 50}) async {
    final db = await database;
    final q = '%$query%';
    final rows = await db.query(
      'products',
      where: 'designation LIKE ? OR code LIKE ? OR barcode LIKE ?',
      whereArgs: [q, q, q],
      limit: limit,
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<int> getProductCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> insertOrUpdateProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProduct(String code) async {
    final db = await database;
    await db.delete('products', where: 'code = ?', whereArgs: [code]);
  }

  // ─── INVENTORIES ───────────────────────────────────────────────────────────

  Future<void> insertInventory(Inventory inv) async {
    final db = await database;
    await db.insert('inventories', inv.toMap());
  }

  Future<List<Inventory>> getAllInventories() async {
    final db = await database;
    final rows = await db.rawQuery(''' 
      SELECT i.*, COUNT(e.id) as entry_count
      FROM inventories i
      LEFT JOIN inventory_entries e ON e.inventory_id = i.id
      GROUP BY i.id
      ORDER BY i.created_at DESC
    ''');
    return rows.map(Inventory.fromMap).toList();
  }

  Future<void> updateInventoryName(String id, String name) async {
    final db = await database;
    await db.update(
      'inventories',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> closeInventory(String id) async {
    final db = await database;
    await db.update(
      'inventories',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteInventory(String id) async {
    final db = await database;
    await db.delete('inventories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── INVENTORY ENTRIES ─────────────────────────────────────────────────────

  Future<void> insertEntry(InventoryEntry entry) async {
    final db = await database;
    await db.insert(
      'inventory_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InventoryEntry>> getEntriesByInventory(
      String inventoryId) async {
    final db = await database;
    final rows = await db.query(
      'inventory_entries',
      where: 'inventory_id = ?',
      whereArgs: [inventoryId],
      orderBy: 'date DESC',
    );
    return rows.map(InventoryEntry.fromMap).toList();
  }

  Future<void> updateEntryQuantity(String id, double quantity) async {
    final db = await database;
    await db.update(
      'inventory_entries',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete('inventory_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTotalsByInventory(
      String inventoryId) async {
    final db = await database;
    return await db.rawQuery(''' 
      SELECT product_code, designation, barcode, SUM(quantity) as total_quantity
      FROM inventory_entries
      WHERE inventory_id = ?
      GROUP BY product_code
      ORDER BY designation ASC
    ''', [inventoryId]);
  }
}
