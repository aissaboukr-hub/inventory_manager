part of 'inventory_bloc.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventoryItemsEvent extends InventoryEvent {
  final int inventoryId;

  const LoadInventoryItemsEvent(this.inventoryId);

  @override
  List<Object> get props => [inventoryId];
}

class RefreshInventoryItemsEvent extends InventoryEvent {
  final int inventoryId;

  const RefreshInventoryItemsEvent(this.inventoryId);

  @override
  List<Object> get props => [inventoryId];
}

class AddInventoryItemEvent extends InventoryEvent {
  final int productId;
  final double quantity;
  final String? notes;

  const AddInventoryItemEvent({
    required this.productId,
    required this.quantity,
    this.notes,
  });

  @override
  List<Object?> get props => [productId, quantity, notes];
}

class UpdateInventoryItemEvent extends InventoryEvent {
  final InventoryItem item;

  const UpdateInventoryItemEvent(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteInventoryItemEvent extends InventoryEvent {
  final int itemId;

  const DeleteInventoryItemEvent(this.itemId);

  @override
  List<Object> get props => [itemId];
}