// ← IMPORTANT: Doit être exactement comme ceci
part of 'home_bloc.dart';

import 'package:equatable/equatable.dart';
import 'package:inventory_manager/domain/entities/inventory.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Inventory> inventories;

  const HomeLoaded({required this.inventories});

  @override
  List<Object?> get props => [inventories];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}