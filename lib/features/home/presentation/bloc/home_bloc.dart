import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:inventory_manager/core/errors/failures.dart';
import 'package:inventory_manager/domain/entities/inventory.dart';
import 'package:inventory_manager/domain/repositories/inventory_repository.dart';

// ← IMPORTANT: Ces lignes doivent être exactement comme ceci
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final InventoryRepository repository;

  HomeBloc({required this.repository}) : super(HomeInitial()) {
    on<LoadInventoriesEvent>(_onLoadInventories);
    on<CreateInventoryEvent>(_onCreateInventory);
    on<DeleteInventoryEvent>(_onDeleteInventory);
    on<RefreshInventoriesEvent>(_onRefreshInventories);
  }

  Future<void> _onLoadInventories(
    LoadInventoriesEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    
    try {
      final inventories = await repository.getAllInventories();
      emit(HomeLoaded(inventories: inventories));
    } on DatabaseFailure catch (e) {
      emit(HomeError(message: e.message));
    } catch (e) {
      emit(HomeError(message: 'Erreur inattendue: $e'));
    }
  }

  Future<void> _onCreateInventory(
    CreateInventoryEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      emit(HomeLoading());
      
      try {
        await repository.createInventory(
          event.name,
          description: event.description,
        );
        final inventories = await repository.getAllInventories();
        emit(HomeLoaded(inventories: inventories));
      } on DatabaseFailure catch (e) {
        emit(HomeError(message: e.message));
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteInventory(
    DeleteInventoryEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      try {
        await repository.deleteInventory(event.id);
        final updatedList = currentState.inventories
            .where((i) => i.id != event.id)
            .toList();
        emit(HomeLoaded(inventories: updatedList));
      } on DatabaseFailure catch (e) {
        emit(HomeError(message: e.message));
        emit(currentState);
      }
    }
  }

  Future<void> _onRefreshInventories(
    RefreshInventoriesEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      add(LoadInventoriesEvent());
    }
  }
}