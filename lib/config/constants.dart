class AppConstants {
  // Database
  static const String databaseName = 'inventory_db';
  static const int databaseVersion = 1;
  
  // Pagination
  static const int defaultPageSize = 50;
  static const int maxPageSize = 100;
  static const int prefetchDistance = 200;
  
  // UI
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Scanner
  static const Duration scannerDebounce = Duration(milliseconds: 1500);
  static const Duration scannerCooldown = Duration(seconds: 1);
  
  // Export
  static const String excelMimeType = 
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const List<String> supportedImportFormats = ['.xlsx', '.xls', '.csv'];
  
  // Google Sheets
  static const String googleAppsScriptUrl = 
      'https://script.google.com/macros/s/VOTRE_ID/exec';
  
  // Audio
  static const String beepSound = 'sounds/beep.mp3';
  static const String errorSound = 'sounds/error.mp3';
  
  // Validation
  static const int maxProductCodeLength = 50;
  static const int maxProductNameLength = 200;
  static const int maxBarcodeLength = 50;
  static const int maxInventoryNameLength = 100;
  
  // Limits
  static const int maxExportRows = 100000;
  static const int batchInsertSize = 500;
}