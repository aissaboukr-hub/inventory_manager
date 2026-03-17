import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int? id;
  final String code;
  final String designation;
  final String? barcode;
  final String? category;
  final String unit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    this.id,
    required this.code,
    required this.designation,
    this.barcode,
    this.category,
    this.unit = 'U',
    this.createdAt,
    this.updatedAt,
  });

  Product copyWith({
    int? id,
    String? code,
    String? designation,
    String? barcode,
    String? category,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
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

  @override
  List<Object?> get props => [
        id, code, designation, barcode, category, unit, createdAt, updatedAt
      ];
}