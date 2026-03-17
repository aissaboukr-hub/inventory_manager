part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventoriesEvent extends HomeEvent {}

class RefreshInventoriesEvent extends HomeEvent {}

class CreateInventoryEvent extends HomeEvent {
  final String name;
  final String? description;

  const CreateInventoryEvent(this.name, {this.description});

  @override
  List<Object?> get props => [name, description];
}

class UpdateInventoryEvent extends HomeEvent {
  final Inventory inventory;

  const UpdateInventoryEvent(this.inventory);

  @override
  List<Object> get props => [inventory];
}

class DeleteInventoryEvent extends HomeEvent {
  final int id;

  const DeleteInventoryEvent(this.id);

  @override
  List<Object> get props => [id];
}