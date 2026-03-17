import 'package:inventory_manager/data/datasources/local/database.dart';
import 'package:inventory_manager/domain/entities/inventory.dart';

class InventoryModel {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? description;
  final int? itemCount;

  InventoryModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.description,
    this.itemCount,
  });

  // From Drift entity
  factory InventoryModel.fromEntity(Inventory entity) {
    return InventoryModel(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
      description: entity.description,
      itemCount: entity.itemCount,
    );
  }

  // From database row
  factory InventoryModel.fromDrift(Inventory drift) {
    return InventoryModel(
      id: drift.id,
      name: drift.name,
      createdAt: drift.createdAt,
      updatedAt: drift.updatedAt,
      isActive: drift.isActive,
      description: drift.description,
    );
  }

  // To domain entity
  Inventory toEntity() {
    return Inventory(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      description: description,
      itemCount: itemCount,
    );
  }

  // To Drift companion
  InventoriesCompanion toCompanion() {
    return InventoriesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isActive: Value(isActive),
      description: Value(description),
    );
  }

  InventoryModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? description,
    int? itemCount,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'description': description,
      'itemCount': itemCount,
    };
  }

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'],
      description: json['description'],
      itemCount: json['itemCount'],
    );
  }

  @override
  String toString() {
    return 'InventoryModel(id: $id, name: $name, items: $itemCount)';
  }
}