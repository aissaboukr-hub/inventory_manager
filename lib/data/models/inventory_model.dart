import 'package:drift/drift.dart';
import 'package:inventory_manager/data/datasources/local/database.dart' as db;
import 'package:inventory_manager/domain/entities/inventory.dart' as entity;

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
  factory InventoryModel.fromDrift(db.Inventory drift) {
    return InventoryModel(
      id: drift.id,
      name: drift.name,
      createdAt: drift.createdAt,
      updatedAt: drift.updatedAt,
      isActive: drift.isActive,
      description: drift.description,
    );
  }

  // To Drift entity
  db.Inventory toDrift() {
    return db.Inventory(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      description: description,
    );
  }

  // To domain entity
  entity.Inventory toEntity() {
    return entity.Inventory(
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
  db.InventoriesCompanion toCompanion() {
    return db.InventoriesCompanion(
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