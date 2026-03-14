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

  // Méthode pour initialiser la base de données
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory_manager.db');

    // Ouvre la base de données en mode configuration
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        // Assurez-vous que les PRAGMA sont exécutées correctement avant toute requête
        await db.execute('PRAGMA journal_mode=WAL'); // Active le mode WAL
        await db.execute('PRAGMA synchronous=NORMAL'); // Configure la synchronisation
        await db.execute('PRAGMA cache_size=10000'); // Configure la taille du cache
        await db.execute('PRAGMA foreign_keys=ON'); // Active les clés étrangères
      },
    );
  }

  // Création des tables et des indices lors de la création de la base de données
  Future<void> _onCreate(Database db, int version) async {
    // Création de la table des produits
    await db.execute('''
      CREATE TABLE products (
        code      TEXT PRIMARY KEY,
        designation TEXT NOT NULL,
        barcode   TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Création d'index pour améliorer les performances des requêtes
    await db.execute('CREATE INDEX idx_product_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_product_designation ON products(designation)');

    // Création de la table des inventaires
    await db.execute('''
      CREATE TABLE inventories (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_active  INTEGER DEFAULT 1
      )
    ''');

    // Création de la table des entrées d'inventaire
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

    // Création des indices pour les entrées d'inventaire
    await db.execute('CREATE INDEX idx_entry_inventory ON inventory_entries(inventory_id)');
    await db.execute('CREATE INDEX idx_entry_barcode ON inventory_entries(barcode)');
  }

  // ─── PRODUCTS ──────────────────────────────────────────────────────────────

  /// Méthode d'insertion par batch optimisée avec des transactions
  Future<int> batchInsertProducts(List<Product> products) async {
    final db = await database;
    const chunkSize = 500; // Taille des morceaux pour l'insertion par lot
    int total = 0;

    // Diviser les produits en morceaux pour optimiser l'insertion
    for (int i = 0; i < products.length; i += chunkSize) {
      final chunk = products.sublist(i, (i + chunkSize).clamp(0, products.length));

      // Utilisation d'une transaction pour insérer les produits en batch
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final p in chunk) {
          batch.insert(
            'products',
            p.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace, // Remplacer en cas de conflit
          );
        }
        await batch.commit(noResult: true); // Exécuter le batch sans attendre un résultat
        total += chunk.length;
      });
    }
    return total;
  }

  // Recherche un produit par son code-barres
  Future<Product?> findProductByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromMap(rows.first); // Retourne le produit trouvé ou null
  }

  // Recherche un produit par son code
  Future<Product?> findProductByCode(String code) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromMap(rows.first); // Retourne le produit trouvé ou null
  }

  // Recherche des produits avec un filtre de texte
  Future<List<Product>> searchProducts(String query, {int limit = 50}) async {
    final db = await database;
    final q = '%$query%'; // Création d'un motif de recherche
    final rows = await db.query(
      'products',
      where: 'designation LIKE ? OR code LIKE ? OR barcode LIKE ?',
      whereArgs: [q, q, q],
      limit: limit,
    );
    return rows.map(Product.fromMap).toList(); // Retourne la liste des produits trouvés
  }

  // Récupère le nombre total de produits
  Future<int> getProductCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return (result.first['count'] as int?) ?? 0; // Retourne le nombre de produits
  }

  // Insère ou met à jour un produit dans la base de données
  Future<void> insertOrUpdateProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Remplacer en cas de conflit
    );
  }

  // Supprime un produit par son code
  Future<void> deleteProduct(String code) async {
    final db = await database;
    await db.delete('products', where: 'code = ?', whereArgs: [code]);
  }

  // ─── INVENTORIES ───────────────────────────────────────────────────────────

  // Insère un nouvel inventaire dans la base de données
  Future<void> insertInventory(Inventory inv) async {
    final db = await database;
    await db.insert('inventories', inv.toMap());
  }

  // Récupère tous les inventaires avec le nombre d'entrées associés
  Future<List<Inventory>> getAllInventories() async {
    final db = await database;
    final rows = await db.rawQuery(''' 
      SELECT i.*, COUNT(e.id) as entry_count
      FROM inventories i
      LEFT JOIN inventory_entries e ON e.inventory_id = i.id
      GROUP BY i.id
      ORDER BY i.created_at DESC
    ''');
    return rows.map(Inventory.fromMap).toList(); // Retourne la liste des inventaires
  }

  // Met à jour le nom d'un inventaire
  Future<void> updateInventoryName(String id, String name) async {
    final db = await database;
    await db.update(
      'inventories',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Ferme un inventaire en le marquant comme inactif
  Future<void> closeInventory(String id) async {
    final db = await database;
    await db.update(
      'inventories',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprime un inventaire par son ID
  Future<void> deleteInventory(String id) async {
    final db = await database;
    await db.delete('inventories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── INVENTORY ENTRIES ─────────────────────────────────────────────────────

  // Insère une entrée d'inventaire
  Future<void> insertEntry(InventoryEntry entry) async {
    final db = await database;
    await db.insert(
      'inventory_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Remplacer en cas de conflit
    );
  }

  // Récupère les entrées d'un inventaire spécifique
  Future<List<InventoryEntry>> getEntriesByInventory(
      String inventoryId) async {
    final db = await database;
    final rows = await db.query(
      'inventory_entries',
      where: 'inventory_id = ?',
      whereArgs: [inventoryId],
      orderBy: 'date DESC',
    );
    return rows.map(InventoryEntry.fromMap).toList(); // Retourne la liste des entrées
  }

  // Met à jour la quantité d'une entrée d'inventaire
  Future<void> updateEntryQuantity(String id, double quantity) async {
    final db = await database;
    await db.update(
      'inventory_entries',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprime une entrée d'inventaire par son ID
  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete('inventory_entries', where: 'id = ?', whereArgs: [id]);
  }

  // Récupère les totaux des quantités par produit pour un inventaire donné
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
