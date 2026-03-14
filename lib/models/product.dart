class Product {
  final String code;
  final String designation;
  final String barcode;

  const Product({
    required this.code,
    required this.designation,
    required this.barcode,
  });

  Map<String, dynamic> toMap() => {
        'code': code,
        'designation': designation,
        'barcode': barcode,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        code: map['code'] as String? ?? '',
        designation: map['designation'] as String? ?? '',
        barcode: map['barcode'] as String? ?? '',
      );

  Product copyWith({String? code, String? designation, String? barcode}) =>
      Product(
        code: code ?? this.code,
        designation: designation ?? this.designation,
        barcode: barcode ?? this.barcode,
      );

  @override
  String toString() => 'Product(code: $code, designation: $designation)';
}
