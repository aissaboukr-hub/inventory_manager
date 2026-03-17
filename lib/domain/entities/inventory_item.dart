import 'package:equatable/equatable.dart';
import 'package:inventory_manager/domain/entities/product.dart';

class InventoryItem extends Equatable {
  final int? id;
  final int inventoryId;
  final int productId;
  final double quantity;
  final DateTime timestamp;
  final String? notes;
  final String? scannedBy;
  final Product? product;

  const InventoryItem({
    this.id,
    required this.inventoryId,
    required this.productId,
    required this.quantity,
    required this.timestamp,
    this.notes,
    this.scannedBy,
    this.product,
  });

  InventoryItem copyWith({
    int? id,
    int? inventoryId,
    int? productId,
    double? quantity,
    DateTime? timestamp,
    String? notes,
    String? scannedBy,
    Product? product,
  }) {
    return InventoryItem(
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

  @override
  List<Object?> get props => [
        id, inventoryId, productId, quantity, timestamp, notes, scannedBy, product
      ];
}