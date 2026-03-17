import 'package:inventory_manager/data/datasources/local/database.dart';
import 'package:inventory_manager/domain/entities/inventory_item.dart';
import 'package:inventory_manager/domain/entities/product.dart';

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

  // From Drift with product join
  factory InventoryItemModel.fromDriftWithProduct(
    InventoryItemWithProduct drift,
  ) {
    return InventoryItemModel(
      id: drift.itemId,
      inventoryId: 0, // Set from context
      productId: drift.productId,
      quantity: drift.quantity,
      timestamp: drift.timestamp,
      notes: drift.notes,
      scannedBy: drift.scannedBy,
      product: ProductModel(
        id: drift.productId,
        code: drift.productCode,
        designation: drift.productDesignation,
        barcode: drift.productBarcode,
        unit: drift.productUnit,
        category: drift.productCategory,
      ),
    );
  }

  // From domain entity
  factory InventoryItemModel.fromEntity(InventoryItem entity) {
    return InventoryItemModel(
      id: entity.id,
      inventoryId: entity.inventoryId,
      productId: entity.productId,
      quantity: entity.quantity,
      timestamp: entity.timestamp,
      notes: entity.notes,
      scannedBy: entity.scannedBy,
      product: entity.product != null ? ProductModel.fromEntity(entity.product!) : null,
    );
  }

  // To domain entity
  InventoryItem toEntity() {
    return InventoryItem(
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

  // To Drift companion
  InventoryItemsCompanion toCompanion() {
    return InventoryItemsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      inventoryId: Value(inventoryId),
      productId: Value(productId),
      quantity: Value(quantity),
      timestamp: Value(timestamp),
      notes: Value(notes),
      scannedBy: Value(scannedBy),
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

  // Helper methods
  bool get isPositive => quantity > 0;
  bool get isNegative => quantity < 0;
  bool get isCorrection => quantity < 0;

  String get formattedQuantity {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    return quantity.toStringAsFixed(2);
  }

  @override
  String toString() {
    return 'InventoryItemModel(id: $id, productId: $productId, qty: $quantity)';
  }
}

// Extension pour ProductModel
extension ProductModelExtension on ProductModel {
  static ProductModel fromEntity(Product entity) {
    return ProductModel(
      id: entity.id,
      code: entity.code,
      designation: entity.designation,
      barcode: entity.barcode,
      category: entity.category,
      unit: entity.unit,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}