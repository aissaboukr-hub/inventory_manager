import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_manager/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration des orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Material 3: Configuration moderne de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  // Material 3: Edge-to-edge display pour Android
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  runApp(const InventoryApp());
}