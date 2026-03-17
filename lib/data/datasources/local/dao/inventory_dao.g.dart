// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dao.dart';

// ignore_for_file: type=lint
mixin _$InventoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $InventoriesTable get inventories => attachedDatabase.inventories;
  $InventoryItemsTable get inventoryItems => attachedDatabase.inventoryItems;
  InventoryDaoManager get managers => InventoryDaoManager(this);
}

class InventoryDaoManager {
  final _$InventoryDaoMixin _db;
  InventoryDaoManager(this._db);
  $$InventoriesTableTableManager get inventories =>
      $$InventoriesTableTableManager(_db.attachedDatabase, _db.inventories);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(
          _db.attachedDatabase, _db.inventoryItems);
}
