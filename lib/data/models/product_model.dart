import 'package:drift/drift.dart';
import 'package:inventory_manager/data/datasources/local/database.dart' as db;
import 'package:inventory_manager/domain/entities/product.dart' as entity;

class ProductModel {
  final int? id;
  final String code;
  final String designation;
  final String? barcode;
  final String? category;
  final String unit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    this.id,
    required this.code,
    required this.designation,
    this.barcode,
    this.category,
    this.unit = 'U',
    this.createdAt,
    this.updatedAt,
  });

  // From Drift entity (db.Product)
  factory ProductModel.fromDrift(db.Product drift) {
    return ProductModel(
      id: drift.id,
      code: drift.code,
      designation: drift.designation,
      barcode: drift.barcode,
      category: drift.category,
      unit: drift.unit,
      createdAt: drift.createdAt,
      updatedAt: drift.updatedAt,
    );
  }

  // To Drift entity (db.Product)
  db.Product toDrift() {
    return db.Product(
      id: id ?? 0,
      code: code,
      designation: designation,
      barcode: barcode,
      category: category,
      unit: unit,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // From domain entity
  factory ProductModel.fromEntity(entity.Product entity) {
    return ProductModel(
      id: entity.id,
      code: entity.code,
      designation: entity.designation,
      barcode: entity.barcode,
      category: entity.category,
      unit: entity.unit,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // To domain entity
  entity.Product toEntity() {
    return entity.Product(
      id: id,
      code: code,
      designation: designation,
      barcode: barcode,
      category: category,
      unit: unit,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // To Drift companion
  db.ProductsCompanion toCompanion() {
    return db.ProductsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      code: Value(code),
      designation: Value(designation),
      barcode: Value(barcode),
      category: Value(category),
      unit: Value(unit),
      createdAt: Value(createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
  }

  ProductModel copyWith({
    int? id,
    String? code,
    String? designation,
    String? barcode,
    String? category,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      code: code ?? this.code,
      designation: designation ?? this.designation,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'designation': designation,
      'barcode': barcode,
      'category': category,
      'unit': unit,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      code: json['code'],
      designation: json['designation'],
      barcode: json['barcode'],
      category: json['category'],
      unit: json['unit'] ?? 'U',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  bool get isValid {
    return code.isNotEmpty && 
           code.length <= 50 &&
           designation.isNotEmpty && 
           designation.length <= 200;
  }

  String? get validationError {
    if (code.isEmpty) return 'Le code est obligatoire';
    if (code.length > 50) return 'Le code ne doit pas dépasser 50 caractères';
    if (designation.isEmpty) return 'La désignation est obligatoire';
    if (designation.length > 200) return 'La désignation ne doit pas dépasser 200 caractères';
    if (barcode != null && barcode!.length > 50) return 'Le code-barres ne doit pas dépasser 50 caractères';
    return null;
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, code: $code, designation: $designation)';
  }
}