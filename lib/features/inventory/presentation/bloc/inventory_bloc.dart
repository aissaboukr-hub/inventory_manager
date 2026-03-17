import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:inventory_manager/core/errors/failures.dart';
import 'package:inventory_manager/domain/entities/inventory_item.dart';
import 'package:inventory_manager/domain/repositories/inventory_repository.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository repository;

  InventoryBloc({required this.repository}) : super(InventoryInitial()) {
    on<LoadInventoryItemsEvent>(_onLoadItems);
    on<RefreshInventoryItemsEvent>(_onRefreshItems);
    on<AddInventoryItemEvent>(_onAddItem);
    on<UpdateInventoryItemEvent>(_onUpdateItem);
    on<DeleteInventoryItemEvent>(_onDeleteItem);
  }

  Future<void> _onLoadItems(
    LoadInventoryItemsEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    
    try {
      final items = await repository.getInventoryItems(
        event.inventoryId,
        limit: 50,
        offset: 0,
      );
      emit(InventoryLoaded(
        inventoryId: event.inventoryId,
        items: items,
      ));
    } on DatabaseFailure catch (e) {
      emit(InventoryError(message: e.message));
    } catch (e) {
      emit(InventoryError(message: 'Erreur: $e'));
    }
  }

  Future<void> _onRefreshItems(
    RefreshInventoryItemsEvent event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      emit(InventoryLoading());
      
      try {
        final items = await repository.getInventoryItems(
          currentState.inventoryId,
          limit: 50,
          offset: 0,
        );
        emit(InventoryLoaded(
          inventoryId: currentState.inventoryId,
          items: items,
        ));
      } on DatabaseFailure catch (e) {
        emit(InventoryError(message: e.message));
        emit(currentState);
      }
    }
  }

  Future<void> _onAddItem(
    AddInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      
      try {
        await repository.addInventoryItem(
          inventoryId: currentState.inventoryId,
          productId: event.productId,
          quantity: event.quantity,
          notes: event.notes,
        );
        
        final items = await repository.getInventoryItems(
          currentState.inventoryId,
          limit: 50,
          offset: 0,
        );
        
        emit(InventoryLoaded(
          inventoryId: currentState.inventoryId,
          items: items,
        ));
      } on DatabaseFailure catch (e) {
        emit(InventoryError(message: e.message));
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateItem(
    UpdateInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      
      try {
        await repository.updateInventoryItem(event.item);
        
        final updatedItems = currentState.items.map((item) {
          return item.id == event.item.id ? event.item : item;
        }).toList();
        
        emit(InventoryLoaded(
          inventoryId: currentState.inventoryId,
          items: updatedItems,
        ));
      } on DatabaseFailure catch (e) {
        emit(InventoryError(message: e.message));
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteItem(
    DeleteInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      
      try {
        await repository.deleteInventoryItem(event.itemId);
        
        final updatedItems = currentState.items
            .where((item) => item.id != event.itemId)
            .toList();
        
        emit(InventoryLoaded(
          inventoryId: currentState.inventoryId,
          items: updatedItems,
        ));
      } on DatabaseFailure catch (e) {
        emit(InventoryError(message: e.message));
        emit(currentState);
      }
    }
  }
}