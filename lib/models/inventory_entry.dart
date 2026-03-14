class InventoryEntry {
  final String id;
  final String inventoryId;
  final String productCode;
  final String designation;
  final String barcode;
  final double quantity;
  final DateTime date;

  const InventoryEntry({
    required this.id,
    required this.inventoryId,
    required this.productCode,
    required this.designation,
    required this.barcode,
    required this.quantity,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'inventory_id': inventoryId,
        'product_code': productCode,
        'designation': designation,
        'barcode': barcode,
        'quantity': quantity,
        'date': date.toIso8601String(),
      };

  factory InventoryEntry.fromMap(Map<String, dynamic> map) => InventoryEntry(
        id: map['id'] as String,
        inventoryId: map['inventory_id'] as String,
        productCode: map['product_code'] as String,
        designation: map['designation'] as String,
        barcode: map['barcode'] as String? ?? '',
        quantity: (map['quantity'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
      );

  InventoryEntry copyWith({
    String? id,
    String? inventoryId,
    String? productCode,
    String? designation,
    String? barcode,
    double? quantity,
    DateTime? date,
  }) =>
      InventoryEntry(
        id: id ?? this.id,
        inventoryId: inventoryId ?? this.inventoryId,
        productCode: productCode ?? this.productCode,
        designation: designation ?? this.designation,
        barcode: barcode ?? this.barcode,
        quantity: quantity ?? this.quantity,
        date: date ?? this.date,
      );
}
