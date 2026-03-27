import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/domain/entities/inventory.dart';
import 'package:inventory_manager/domain/repositories/inventory_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final InventoryRepository repository;

  HomeBloc({required this.repository}) : super(HomeInitial()) {
    on<LoadInventoriesEvent>(_onLoadInventories);
    on<RefreshInventoriesEvent>(_onRefreshInventories);
    on<CreateInventoryEvent>(_onCreateInventory);
    on<UpdateInventoryEvent>(_onUpdateInventory);
    on<DeleteInventoryEvent>(_onDeleteInventory);
  }

  Future<void> _onLoadInventories(
    LoadInventoriesEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    try {
      final inventories = await repository.getAllInventories();
      emit(HomeLoaded(inventories));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> _onRefreshInventories(
    RefreshInventoriesEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final inventories = await repository.getAllInventories();
      emit(HomeLoaded(inventories));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> _onCreateInventory(
    CreateInventoryEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // ✅ CORRIGÉ : name est positionnel, description est nommé
      await repository.createInventory(
        event.name,                           // ← positionnel (requis)
        description: event.description,       // ← nommé (optionnel)
      );
      final inventories = await repository.getAllInventories();
      emit(HomeLoaded(inventories));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> _onUpdateInventory(
    UpdateInventoryEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // ✅ CORRIGÉ : updateInventory prend un objet Inventory complet
      await repository.updateInventory(
        Inventory(
          id: event.inventoryId,
          name: event.name,
          description: event.description,
          createdAt: DateTime.now(),    // sera ignoré par le DAO
          updatedAt: DateTime.now(),    // sera utilisé pour la mise à jour
        ),
      );
      final inventories = await repository.getAllInventories();
      emit(HomeLoaded(inventories));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> _onDeleteInventory(
    DeleteInventoryEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await repository.deleteInventory(event.inventoryId);
      final inventories = await repository.getAllInventories();
      emit(HomeLoaded(inventories));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }
}