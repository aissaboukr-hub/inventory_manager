class Inventory {
  final String id;
  final String name;
  final DateTime createdAt;
  final bool isActive;
  final int? entryCount;

  const Inventory({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isActive = true,
    this.entryCount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'is_active': isActive ? 1 : 0,
      };

  factory Inventory.fromMap(Map<String, dynamic> map) => Inventory(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        isActive: (map['is_active'] as int?) == 1,
        entryCount: map['entry_count'] as int?,
      );

  Inventory copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isActive,
    int? entryCount,
  }) =>
      Inventory(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
        entryCount: entryCount ?? this.entryCount,
      );
}
