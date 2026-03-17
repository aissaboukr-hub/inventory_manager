import 'package:drift/drift.dart';
import '../database.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [Inventories, InventoryItems])
class InventoryDao extends DatabaseAccessor<AppDatabase> with _$InventoryDaoMixin {
  InventoryDao(super.db);

  // ============== CRUD INVENTORIES ==============

  Future<List<Inventory>> getAllInventories() async {
    return (select(inventories)
      ..where((i) => i.isActive.equals(true))
      ..orderBy([(i) => OrderingTerm.desc(i.updatedAt)])
    ).get();
  }

  Future<Inventory?> getInventoryById(int id) async {
    return (select(inventories)..where((i) => i.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertInventory(String name, {String? description}) async {
    return into(inventories).insert(
      InventoriesCompanion(
        name: Value(name),
        description: Value(description),
      ),
    );
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

  Future<int> softDeleteInventory(int id) async {
    return (update(inventories)..where((i) => i.id.equals(id))).write(
      InventoriesCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============== INVENTORY ITEMS ==============

  Future<List<InventoryItemWithProduct>> getItemsByInventory(
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
        i.scanned_by,
        p.id as product_id,
        p.code as product_code,
        p.designation as product_designation,
        p.barcode as product_barcode,
        p.unit as product_unit,
        p.category as product_category
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
      scannedBy: row.read<String?>('scanned_by'),
      productId: row.read<int>('product_id'),
      productCode: row.read<String>('product_code'),
      productDesignation: row.read<String>('product_designation'),
      productBarcode: row.read<String?>('product_barcode'),
      productUnit: row.read<String>('product_unit'),
      productCategory: row.read<String?>('product_category'),
    )).get();
  }

  Future<int> insertInventoryItem({
    required int inventoryId,
    required int productId,
    required double quantity,
    String? notes,
    String? scannedBy,
  }) async {
    // Update inventory timestamp
    await (update(inventories)..where((i) => i.id.equals(inventoryId))).write(
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

  Future<bool> updateItemQuantity(int itemId, double quantity, {String? notes}) async {
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

  // ============== STATISTICS & SUMMARY ==============

  Future<InventoryStats> getInventoryStats(int inventoryId) async {
    final result = await customSelect(
      '''
      SELECT 
        COUNT(DISTINCT product_id) as product_count,
        SUM(quantity) as total_items,
        COUNT(*) as total_entries
      FROM inventory_items
      WHERE inventory_id = ?
      ''',
      variables: [Variable.withInt(inventoryId)],
    ).getSingle();

    return InventoryStats(
      productCount: result.read<int>('product_count'),
      totalItems: result.read<double?>('total_items') ?? 0,
      totalEntries: result.read<int>('total_entries'),
    );
  }

  Future<List<InventorySummaryRow>> getInventorySummary(int inventoryId) async {
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
        MAX(i.timestamp) as last_update,
        MIN(i.timestamp) as first_update
      FROM inventory_items i
      JOIN products p ON i.product_id = p.id
      WHERE i.inventory_id = ?
      GROUP BY p.id
      HAVING total_quantity != 0
      ORDER BY p.designation ASC
      ''',
      variables: [Variable.withInt(inventoryId)],
    );

    return query.map((row) => InventorySummaryRow(
      productId: row.read<int>('product_id'),
      code: row.read<String>('code'),
      designation: row.read<String>('designation'),
      barcode: row.read<String?>('barcode'),
      unit: row.read<String>('unit'),
      totalQuantity: row.read<double>('total_quantity'),
      entryCount: row.read<int>('entry_count'),
      lastUpdate: row.read<DateTime>('last_update'),
      firstUpdate: row.read<DateTime>('first_update'),
    )).get();
  }

  // ============== EXPORT ==============

  Future<List<InventoryExportRow>> getExportData(int inventoryId) async {
    final query = customSelect(
      '''
      SELECT 
        p.code,
        p.designation,
        p.barcode,
        p.unit,
        i.quantity,
        i.timestamp,
        i.notes,
        i.scanned_by
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
      unit: row.read<String>('unit'),
      quantity: row.read<double>('quantity'),
      timestamp: row.read<DateTime>('timestamp'),
      notes: row.read<String?>('notes'),
      scannedBy: row.read<String?>('scanned_by'),
    )).get();
  }

  // ============== MAINTENANCE ==============

  Future<void> cleanupDuplicateItems(int inventoryId) async {
    await customStatement('''
      DELETE FROM inventory_items 
      WHERE id NOT IN (
        SELECT MIN(id) 
        FROM inventory_items 
        WHERE inventory_id = ?
        GROUP BY product_id, CAST(timestamp AS DATE), quantity
      ) AND inventory_id = ?
    ''', [inventoryId, inventoryId]);
  }

  Future<void> deleteZeroQuantityItems(int inventoryId) async {
    await (delete(inventoryItems)
      ..where((i) => i.inventoryId.equals(inventoryId) & i.quantity.equals(0))
    ).go();
  }
}

// ============== DATA CLASSES ==============

class InventoryItemWithProduct {
  final int itemId;
  final double quantity;
  final DateTime timestamp;
  final String? notes;
  final String? scannedBy;
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
    this.scannedBy,
    required this.productId,
    required this.productCode,
    required this.productDesignation,
    this.productBarcode,
    required this.productUnit,
    this.productCategory,
  });
}

class InventoryStats {
  final int productCount;
  final double totalItems;
  final int totalEntries;

  InventoryStats({
    required this.productCount,
    required this.totalItems,
    required this.totalEntries,
  });
}

class InventorySummaryRow {
  final int productId;
  final String code;
  final String designation;
  final String? barcode;
  final String unit;
  final double totalQuantity;
  final int entryCount;
  final DateTime lastUpdate;
  final DateTime firstUpdate;

  InventorySummaryRow({
    required this.productId,
    required this.code,
    required this.designation,
    this.barcode,
    required this.unit,
    required this.totalQuantity,
    required this.entryCount,
    required this.lastUpdate,
    required this.firstUpdate,
  });
}

class InventoryExportRow {
  final String code;
  final String designation;
  final String? barcode;
  final String unit;
  final double quantity;
  final DateTime timestamp;
  final String? notes;
  final String? scannedBy;

  InventoryExportRow({
    required this.code,
    required this.designation,
    this.barcode,
    required this.unit,
    required this.quantity,
    required this.timestamp,
    this.notes,
    this.scannedBy,
  });
}