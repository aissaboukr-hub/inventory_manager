import 'package:equatable/equatable.dart';

class Inventory extends Equatable {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? description;
  final int? itemCount;

  const Inventory({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.description,
    this.itemCount,
  });

  Inventory copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? description,
    int? itemCount,
  }) {
    return Inventory(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  @override
  List<Object?> get props => [
        id, name, createdAt, updatedAt, isActive, description, itemCount
      ];
}