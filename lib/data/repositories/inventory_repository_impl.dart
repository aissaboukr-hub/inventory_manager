import 'package:drift/drift.dart' as drift;  // ← AJOUTER CECI
import 'package:inventory_manager/core/errors/failures.dart';
import 'package:inventory_manager/data/datasources/local/dao/inventory_dao.dart' as dao;
import 'package:inventory_manager/data/datasources/local/dao/product_dao.dart';
import 'package:inventory_manager/data/datasources/local/database.dart' as db;
import 'package:inventory_manager/data/models/inventory_item_model.dart';
import 'package:inventory_manager/data/models/inventory_model.dart';
import 'package:inventory_manager/data/models/product_model.dart';
import 'package:inventory_manager/domain/entities/inventory.dart';
import 'package:inventory_manager/domain/entities/inventory_item.dart';
import 'package:inventory_manager/domain/entities/product.dart';
import 'package:inventory_manager/domain/repositories/inventory_repository.dart' as repo;

// Renommer les classes en conflit
typedef DomainInventorySummary = repo.InventorySummary;
typedef DomainInventoryStats = repo.InventoryStats;

class InventoryRepositoryImpl implements repo.InventoryRepository {
  final db.AppDatabase _database;
  late final dao.InventoryDao _inventoryDao;
  late final ProductDao _productDao;

  InventoryRepositoryImpl(this._database) {
    _inventoryDao = dao.InventoryDao(_database);
    _productDao = ProductDao(_database);
  }

  // ============== INVENTORIES ==============

  @override
  Future<List<Inventory>> getAllInventories() async {
    try {
      final inventories = await _inventoryDao.getAllInventories();
      
      final List<Inventory> result = [];
      for (final inv in inventories) {
        final stats = await _inventoryDao.getInventoryStats(inv.id);
        result.add(InventoryModel.fromDrift(inv).copyWith(
          itemCount: stats.productCount,
        ).toEntity());
      }
      
      return result;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to load inventories: $e');
    }
  }

  @override
  Future<Inventory> getInventory(int id) async {
    try {
      final inventory = await _inventoryDao.getInventoryById(id);
      if (inventory == null) {
        throw NotFoundFailure(message: 'Inventory not found');
      }
      
      final stats = await _inventoryDao.getInventoryStats(id);
      return InventoryModel.fromDrift(inventory).copyWith(
        itemCount: stats.productCount,
      ).toEntity();
    } on NotFoundFailure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to get inventory: $e');
    }
  }

  @override
  Future<Inventory> createInventory(String name, {String? description}) async {
    try {
      final id = await _inventoryDao.insertInventory(name, description: description);
      return getInventory(id);
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to create inventory: $e');
    }
  }

  @override
  Future<void> updateInventory(Inventory inventory) async {
    try {
      final success = await _inventoryDao.updateInventory(
        inventory.id,
        inventory.name,
        description: inventory.description,
      );
      
      if (!success) {
        throw NotFoundFailure(message: 'Inventory not found');
      }
    } on NotFoundFailure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to update inventory: $e');
    }
  }

  @override
  Future<void> deleteInventory(int id) async {
    try {
      final deleted = await _inventoryDao.deleteInventory(id);
      if (deleted == 0) {
        throw NotFoundFailure(message: 'Inventory not found');
      }
    } on NotFoundFailure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to delete inventory: $e');
    }
  }

  // ============== PRODUCTS ==============

  @override
  Future<List<Product>> getAllProducts({int limit = 50, int offset = 0}) async {
    try {
      final products = await _productDao.getAllProducts(limit: limit, offset: offset);
      return products.map((p) => ProductModel.fromDrift(p).toEntity()).toList();
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to load products: $e');
    }
  }

  @override
  Future<Product?> getProductById(int id) async {
    try {
      final product = await _productDao.getProductById(id);
      return product != null ? ProductModel.fromDrift(product).toEntity() : null;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to get product: $e');
    }
  }

  @override
  Future<Product?> getProductByCode(String code) async {
    try {
      final product = await _productDao.getProductByCode(code);
      return product != null ? ProductModel.fromDrift(product).toEntity() : null;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to get product by code: $e');
    }
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final product = await _productDao.getProductByBarcode(barcode);
      return product != null ? ProductModel.fromDrift(product).toEntity() : null;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to get product by barcode: $e');
    }
  }

  @override
  Future<List<Product>> searchProducts(String query, {int limit = 50}) async {
    try {
      final products = await _productDao.searchProducts(query, limit: limit);
      return products.map((p) => ProductModel.fromDrift(p).toEntity()).toList();
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to search products: $e');
    }
  }

  @override
  Future<Product> createProduct({
    required String code,
    required String designation,
    String? barcode,
    String? category,
    String unit = 'U',
  }) async {
    try {
      if (code.isEmpty) {
        throw ValidationFailure(message: 'Product code is required');
      }
      if (designation.isEmpty) {
        throw ValidationFailure(message: 'Product designation is required');
      }
      
      final existingCode = await _productDao.codeExists(code);
      if (existingCode) {
        throw ValidationFailure(message: 'Product code already exists');
      }
      
      if (barcode != null && barcode.isNotEmpty) {
        final existingBarcode = await _productDao.barcodeExists(barcode);
        if (existingBarcode) {
          throw ValidationFailure(message: 'Barcode already exists');
        }
      }
      
      final id = await _productDao.insertProduct(
        code: code,
        designation: designation,
        barcode: barcode,
        category: category,
        unit: unit,
      );
      
      final product = await _productDao.getProductById(id);
      return ProductModel.fromDrift(product!).toEntity();
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to create product: $e');
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    try {
      if (product.id == null) {
        throw ValidationFailure(message: 'Product ID is required');
      }
      
      final existingCode = await _productDao.codeExists(
        product.code,
        excludeId: product.id,
      );
      if (existingCode) {
        throw ValidationFailure(message: 'Product code already exists');
      }
      
      if (product.barcode != null) {
        final existingBarcode = await _productDao.barcodeExists(
          product.barcode!,
          excludeId: product.id,
        );
        if (existingBarcode) {
          throw ValidationFailure(message: 'Barcode already exists');
        }
      }
      
      final success = await _productDao.updateProduct(
        db.Product(
          id: product.id!,
          code: product.code,
          designation: product.designation,
          barcode: product.barcode,
          category: product.category,
          unit: product.unit,
          createdAt: product.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      if (!success) {
        throw NotFoundFailure(message: 'Product not found');
      }
    } on ValidationFailure {
      rethrow;
    } on NotFoundFailure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      final deleted = await _productDao.deleteProduct(id);
      if (deleted == 0) {
        throw NotFoundFailure(message: 'Product not found');
      }
    } on NotFoundFailure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to delete product: $e');
    }
  }

  @override
  Future<void> batchInsertProducts(List<Product> products) async {
    try {
      final companions = products.map((p) {
        return db.ProductsCompanion(
          code: drift.Value(p.code),           // ← CORRIGÉ: drift.Value
          designation: drift.Value(p.designation), // ← CORRIGÉ: drift.Value
          barcode: drift.Value(p.barcode),     // ← CORRIGÉ: drift.Value
          category: drift.Value(p.category),   // ← CORRIGÉ: drift.Value
          unit: drift.Value(p.unit),           // ← CORRIGÉ: drift.Value
        );
      }).toList();
      
      await _productDao.batchInsert(companions);
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to batch insert products: $e');
    }
  }

  // ============== INVENTORY ITEMS ==============

  @override
  Future<List<InventoryItem>> getInventoryItems(
    int inventoryId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final items = await _inventoryDao.getItemsByInventory(
        inventoryId,
        limit: limit,
        offset: offset,
      );
      
      return items.map((item) {
        // ← CORRIGÉ: Conversion explicite du type
        final convertedItem = _convertInventoryItemWithProduct(item);
        return InventoryItemModel.fromDriftWithProduct(convertedItem)
            .copyWith(inventoryId: inventoryId)
            .toEntity();
      }).toList();
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to load inventory items: $e');
    }
  }

  @override
  Future<InventoryItem> addInventoryItem({
    required int inventoryId,
    required int productId,
    required double quantity,
    String? notes,
    String? scannedBy,
  }) async {
    try {
      if (quantity == 0) {
        throw ValidationFailure(message: 'Quantity cannot be zero');
      }
      
      final id = await _inventoryDao.insertInventoryItem(
        inventoryId: inventoryId,
        productId: productId,
        quantity: quantity,
        notes: notes,
        scannedBy: scannedBy,
      );
      
      final items = await _inventoryDao.getItemsByInventory(inventoryId, limit: 1);
      final item = items.firstWhere((i) => i.itemId == id);
      
      // ← CORRIGÉ: Conversion explicite du type
      final convertedItem = _convertInventoryItemWithProduct(item);
      return InventoryItemModel.fromDriftWithProduct(convertedItem)
          .copyWith(inventoryId: inventoryId)
          .toEntity();
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to add inventory item: $e');
    }
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      if (item.id == null) {
        throw ValidationFailure(message: 'Item ID is required');
      }
      
      final success = await _inventoryDao.updateItemQuantity(
        item.id!,
        item.quantity,
        notes: item.notes,
      );
      
      if (!success) {
        throw NotFoundFailure(message: 'Inventory item not found');
      }
    } on ValidationFailure {
      rethrow;
    } on NotFoundFailure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to update inventory item: $e');
    }
  }

  @override
  Future<void> deleteInventoryItem(int itemId) async {
    try {
      final deleted = await _inventoryDao.deleteInventoryItem(itemId);
      if (deleted == 0) {
        throw NotFoundFailure(message: 'Inventory item not found');
      }
    } on NotFoundFailure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to delete inventory item: $e');
    }
  }

  // ============== AGGREGATION ==============

  @override
  Future<List<DomainInventorySummary>> getInventorySummary(int inventoryId) async {
    try {
      final summary = await _inventoryDao.getInventorySummary(inventoryId);
      
      return summary.map((row) => DomainInventorySummary(
        productId: row.productId,
        code: row.code,
        designation: row.designation,
        barcode: row.barcode,
        unit: row.unit,
        totalQuantity: row.totalQuantity,
        entryCount: row.entryCount,
        lastUpdate: row.lastUpdate,
      )).toList();
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to get inventory summary: $e');
    }
  }

  @override
  Future<DomainInventoryStats> getInventoryStats(int inventoryId) async {
    try {
      final stats = await _inventoryDao.getInventoryStats(inventoryId);
      return DomainInventoryStats(
        productCount: stats.productCount,
        totalItems: stats.totalItems,
      );
    } catch (e) {
      throw DatabaseFailure(message: 'Failed to get inventory stats: $e');
    }
  }

  // ============== HELPER METHODS ==============

  /// Convertit le type du DAO vers le type de la database
  db.InventoryItemWithProduct _convertInventoryItemWithProduct(dao.InventoryItemWithProduct item) {
    return db.InventoryItemWithProduct(
      itemId: item.itemId,
      quantity: item.quantity,
      timestamp: item.timestamp,
      notes: item.notes,
      scannedBy: item.scannedBy,
      productId: item.productId,
      productCode: item.productCode,
      productDesignation: item.productDesignation,
      productBarcode: item.productBarcode,
      productUnit: item.productUnit,
      productCategory: item.productCategory,
    );
  }
}