part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();  // ← AJOUTER const

  @override
  List<Object?> get props => [];
}

class LoadInventoriesEvent extends HomeEvent {
  const LoadInventoriesEvent();  // ← AJOUTER const constructeur
}

class RefreshInventoriesEvent extends HomeEvent {
  const RefreshInventoriesEvent();  // ← AJOUTER const constructeur
}

class CreateInventoryEvent extends HomeEvent {
  final String name;
  final String? description;

  const CreateInventoryEvent(this.name, {this.description});  // ← const déjà présent

  @override
  List<Object?> get props => [name, description];
}

class UpdateInventoryEvent extends HomeEvent {
  final Inventory inventory;

  const UpdateInventoryEvent(this.inventory);  // ← const déjà présent

  @override
  List<Object> get props => [inventory];
}

class DeleteInventoryEvent extends HomeEvent {
  final int id;

  const DeleteInventoryEvent(this.id);  // ← const déjà présent

  @override
  List<Object> get props => [id];
}