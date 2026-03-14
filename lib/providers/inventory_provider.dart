import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory.dart';
import '../models/inventory_entry.dart';
import '../core/database/database_service.dart';

class InventoryProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  final _uuid = const Uuid();

  List<Inventory> _inventories = [];
  Inventory? _activeInventory;
  List<InventoryEntry> _activeEntries = [];
  bool _loading = false;

  List<Inventory> get inventories => _inventories;
  Inventory? get activeInventory => _activeInventory;
  List<InventoryEntry> get activeEntries => _activeEntries;
  bool get loading => _loading;

  Future<void> loadInventories() async {
    _loading = true;
    notifyListeners();
    _inventories = await _db.getAllInventories();
    _loading = false;
    notifyListeners();
  }

  Future<Inventory> createInventory(String name) async {
    final inv = Inventory(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _db.insertInventory(inv);
    await loadInventories();
    return inv;
  }

  Future<void> renameInventory(String id, String name) async {
    await _db.updateInventoryName(id, name);
    await loadInventories();
  }

  Future<void> deleteInventory(String id) async {
    await _db.deleteInventory(id);
    if (_activeInventory?.id == id) {
      _activeInventory = null;
      _activeEntries = [];
    }
    await loadInventories();
  }

  Future<void> setActiveInventory(Inventory inv) async {
    _activeInventory = inv;
    _activeEntries = await _db.getEntriesByInventory(inv.id);
    notifyListeners();
  }

  Future<InventoryEntry> addEntry({
    required String productCode,
    required String designation,
    required String barcode,
    required double quantity,
  }) async {
    if (_activeInventory == null) throw Exception('Aucun inventaire actif');

    final entry = InventoryEntry(
      id: _uuid.v4(),
      inventoryId: _activeInventory!.id,
      productCode: productCode,
      designation: designation,
      barcode: barcode,
      quantity: quantity,
      date: DateTime.now(),
    );

    await _db.insertEntry(entry);
    _activeEntries.insert(0, entry);
    notifyListeners();
    return entry;
  }

  Future<void> updateEntryQuantity(String entryId, double quantity) async {
    await _db.updateEntryQuantity(entryId, quantity);
    final idx = _activeEntries.indexWhere((e) => e.id == entryId);
    if (idx >= 0) {
      _activeEntries[idx] = _activeEntries[idx].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String entryId) async {
    await _db.deleteEntry(entryId);
    _activeEntries.removeWhere((e) => e.id == entryId);
    notifyListeners();
  }

  Future<void> refreshActiveEntries() async {
    if (_activeInventory == null) return;
    _activeEntries =
        await _db.getEntriesByInventory(_activeInventory!.id);
    notifyListeners();
  }
}
