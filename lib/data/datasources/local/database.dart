import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';  // ← API changée dans v0.1.0
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ============== TABLES ==============

class Inventories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get description => text().nullable()();
  
  @override
  List<String> get customConstraints => [
    'UNIQUE(name)'
  ];
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 1, max: 50)();
  TextColumn get designation => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('U'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  List<String> get customConstraints => [
    'UNIQUE(code)',
    'UNIQUE(barcode)'
  ];
}

class InventoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get inventoryId => integer().references(Inventories, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  RealColumn get quantity => real()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  TextColumn get scannedBy => text().nullable()();
  
  @override
  List<String> get customConstraints => [
    'CHECK(quantity != 0)'
  ];
}

// ============== INDEXES ==============

@DriftDatabase(
  tables: [Inventories, Products, InventoryItems],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Création d'index pour performances
      await customStatement('CREATE INDEX