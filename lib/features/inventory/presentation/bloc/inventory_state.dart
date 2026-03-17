part of 'inventory_bloc.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final int inventoryId;
  final List<InventoryItem> items;

  const InventoryLoaded({
    required this.inventoryId,
    required this.items,
  });

  @override
  List<Object?> get props => [inventoryId, items];
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError({required this.message});

  @override
  List<Object?> get props => [message];
}