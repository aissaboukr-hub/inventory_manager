import 'package:inventory_manager/core/errors/failures.dart';
import 'package:inventory_manager/domain/entities/inventory.dart';
import 'package:inventory_manager/domain/entities/product.dart';
import 'package:inventory_manager/domain/entities/inventory_item.dart';

abstract class InventoryRepository {
  // Inventories
  Future<List<Inventory>> getAllInventories();
  Future<Inventory> getInventory(int id);
  Future<Inventory> createInventory(String name, {String? description});
  Future<void> updateInventory(Inventory inventory);
  Future<void> deleteInventory(int id);

  // Products
  Future<List<Product>> getAllProducts({int limit = 50, int offset = 0});
  Future<Product?> getProductById(int id);
  Future<Product?> getProductByCode(String code);
  Future<Product?> getProductByBarcode(String barcode);
  Future<List<Product>> searchProducts(String query, {int limit = 50});
  Future<Product> createProduct({
    required String code,
    required String designation,
    String? barcode,
    String? category,
    String unit = 'U',
  });
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<void> batchInsertProducts(List<Product> products);

  // Inventory Items
  Future<List<InventoryItem>> getInventoryItems(
    int inventoryId, {
    int limit = 50,
    int offset = 0,
  });
  Future<InventoryItem> addInventoryItem({
    required int inventoryId,
    required int productId,
    required double quantity,
    String? notes,
    String? scannedBy,
  });
  Future<void> updateInventoryItem(InventoryItem item);
  Future<void> deleteInventoryItem(int itemId);

  // Aggregation
  Future<List<InventorySummary>> getInventorySummary(int inventoryId);
  Future<InventoryStats> getInventoryStats(int inventoryId);
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