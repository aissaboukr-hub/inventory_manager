import 'package:flutter/material.dart';
import 'package:inventory_manager/features/home/presentation/screens/home_screen.dart';
import 'package:inventory_manager/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:inventory_manager/features/inventory/presentation/screens/product_scanner_screen.dart';
import 'package:inventory_manager/features/product_management/presentation/screens/add_product_screen.dart';
import 'package:inventory_manager/features/settings/presentation/screens/settings_screen.dart';  // ← AJOUTER
import 'package:inventory_manager/domain/entities/inventory.dart';

class AppRoutes {
  static const String home = '/';
  static const String inventoryDetail = '/inventory';
  static const String scanner = '/scanner';
  static const String addProduct = '/add-product';
  static const String importExport = '/import-export';
  static const String settings = '/settings';  // ← AJOUTER

  static Map<String, WidgetBuilder> get routes {
    return {
      home: (context) => const HomeScreen(),
      settings: (context) => const SettingsScreen(),  // ← AJOUTER
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case inventoryDetail:
        if (args is Inventory) {
          return MaterialPageRoute(
            builder: (context) => InventoryListScreen(inventory: args),
          );
        }
        return _errorRoute();

      case scanner:
        if (args is int) {
          return MaterialPageRoute(
            builder: (context) => ProductScannerScreen(inventoryId: args),
          );
        }
        return _errorRoute();

      case addProduct:
        final Map<String, dynamic>? params = args as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => AddProductScreen(
            barcode: params?['barcode'],
            onProductCreated: params?['onProductCreated'],
          ),
        );

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(
          child: Text('Page non trouvée ou arguments invalides'),
        ),
      ),
    );
  }
}