part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventoriesEvent extends HomeEvent {
  const LoadInventoriesEvent();
}

class RefreshInventoriesEvent extends HomeEvent {
  const RefreshInventoriesEvent();
}

class CreateInventoryEvent extends HomeEvent {
  final String name;
  final String? description;

  const CreateInventoryEvent(this.name, {this.description});

  @override
  List<Object?> get props => [name, description];
}

class UpdateInventoryEvent extends HomeEvent {
  final int inventoryId;
  final String name;
  final String? description;

  const UpdateInventoryEvent({
    required this.inventoryId,
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [inventoryId, name, description];
}

class DeleteInventoryEvent extends HomeEvent {
  final int inventoryId;

  const DeleteInventoryEvent(this.inventoryId);

  @override
  List<Object> get props => [inventoryId];
}