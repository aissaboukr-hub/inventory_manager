import 'package:drift/drift.dart' as drift;
import 'package:inventory_manager/data/datasources/local/database.dart' as db;
import 'package:inventory_manager/data/models/product_model.dart';
import 'package:inventory_manager/domain/entities/inventory_item.dart' as entity;
import 'package:inventory_manager/domain/entities/product.dart' as entity;

class InventoryItemModel {
  final int? id;
  final int inventoryId;
  final int productId;
  final double quantity;
  final DateTime timestamp;
  final String? notes;
  final String? scannedBy;
  final ProductModel? product;

  InventoryItemModel({
    this.id,
    required this.inventoryId,
    required this.productId,
    required this.quantity,
    required this.timestamp,
    this.notes,
    this.scannedBy,
    this.product,
  });

  factory InventoryItemModel.fromDriftWithProduct(db.InventoryItemWithProduct drift) {
    return InventoryItemModel(
      id: drift.id,                    // ← CORRIGÉ: was itemId
      inventoryId: drift.inventoryId,  // ← CORRIGÉ: was 0
      productId: drift.productId,
      quantity: drift.quantity,
      timestamp: drift.timestamp,
      notes: drift.notes,
      scannedBy: drift.scannedBy,
      product: ProductModel(
        id: drift.productId,
        code: drift.code,              // ← CORRIGÉ: was productCode
        designation: drift.designation, // ← CORRIGÉ: was productDesignation
        barcode: drift.barcode,        // ← CORRIGÉ: was productBarcode
        unit: drift.unit,              // ← CORRIGÉ: was productUnit
        category: drift.category,      // ← CORRIGÉ: was productCategory
      ),
    );
  }

  factory InventoryItemModel.fromEntity(entity.InventoryItem e) {
    return InventoryItemModel(
      id: e.id,
      inventoryId: e.inventoryId,
      productId: e.productId,
      quantity: e.quantity,
      timestamp: e.timestamp,
      notes: e.notes,
      scannedBy: e.scannedBy,
      product: e.product != null ? ProductModel.fromEntity(e.product!) : null,
    );
  }

  entity.InventoryItem toEntity() {
    return entity.InventoryItem(
      id: id,
      inventoryId: inventoryId,
      productId: productId,
      quantity: quantity,
      timestamp: timestamp,
      notes: notes,
      scannedBy: scannedBy,
      product: product?.toEntity(),
    );
  }

  db.InventoryItemsCompanion toCompanion() {
    return db.InventoryItemsCompanion(
      id: id != null ? drift.Value(id!) : const drift.Value.absent(),
      inventoryId: drift.Value(inventoryId),
      productId: drift.Value(productId),
      quantity: drift.Value(quantity),
      timestamp: drift.Value(timestamp),
      notes: drift.Value(notes),
      scannedBy: drift.Value(scannedBy),
    );
  }

  InventoryItemModel copyWith({
    int? id,
    int? inventoryId,
    int? productId,
    double? quantity,
    DateTime? timestamp,
    String? notes,
    String? scannedBy,
    ProductModel? product,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      scannedBy: scannedBy ?? this.scannedBy,
      product: product ?? this.product,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'productId': productId,
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'scannedBy': scannedBy,
      'product': product?.toJson(),
    };
  }

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'],
      inventoryId: json['inventoryId'],
      productId: json['productId'],
      quantity: json['quantity'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
      scannedBy: json['scannedBy'],
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
    );
  }

  bool get isPositive => quantity > 0;
  bool get isNegative => quantity < 0;
  String get formattedQuantity => quantity == quantity.toInt() 
      ? quantity.toInt().toString() 
      : quantity.toStringAsFixed(2);

  @override
  String toString() => 'InventoryItemModel(id: $id, productId: $productId, qty: $quantity)';
}

// Extension séparée
extension ProductModelExtension on ProductModel {
  static ProductModel fromEntity(entity.Product e) {
    return ProductModel(
      id: e.id,
      code: e.code,
      designation: e.designation,
      barcode: e.barcode,
      category: e.category,
      unit: e.unit,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }
}