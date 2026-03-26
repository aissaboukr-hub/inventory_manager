import 'package:drift/drift.dart';
import 'package:inventory_manager/database/app_database.dart'; // adapte le chemin
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleSheetsService {
  static const String _scopes = [
    sheets.SheetsApi.spreadsheetsScope,
    sheets.SheetsApi.driveFileScope,
  ].join(' ');

  final String _apiKey;
  final String _scriptUrl;
  AuthClient? _authClient;

  GoogleSheetsService({
    required String apiKey,
    required String scriptUrl,
  })  : _apiKey = apiKey,
        _scriptUrl = scriptUrl;

  /// Authentification via OAuth2 (pour accès complet)
  Future<void> authenticate() async {
    // Note: Dans une vraie app, utilisez secure storage pour les credentials
    final clientId = ClientId(
      'VOTRE_CLIENT_ID.apps.googleusercontent.com',
      'VOTRE_CLIENT_SECRET',
    );

    _authClient = await clientViaUserConsent(
      clientId,
      [sheets.SheetsApi.spreadsheetsScope],
      _prompt,
    );
  }

  void _prompt(String url) {
    launchUrl(Uri.parse(url));
  }

  /// Export via Apps Script (méthode recommandée pour Flutter)
  Future<ExportResult> exportToGoogleSheets({
    required String inventoryName,
    required List<Map<String, dynamic>> data,
    String? existingSheetId,
  }) async {
    try {
      final payload = {
        'action': 'export',
        'inventoryName': inventoryName,
        'sheetId': existingSheetId,
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
        'columns': ['Code', 'Désignation', 'Code-barres', 'Quantité', 'Unité', 'Date'],
      };

      final response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Export failed: ${response.body}');
      }

      final result = jsonDecode(response.body);
      
      return ExportResult(
        success: result['success'] == true,
        sheetUrl: result['url'],
        sheetId: result['sheetId'],
        rowCount: result['rowCount'] ?? data.length,
        message: result['message'],
      );
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'Erreur: $e',
      );
    }
  }

  /// Import depuis Google Sheets via Apps Script
  Future<ImportResult> importFromGoogleSheets(String sheetId, {String? range}) async {
    try {
      final payload = {
        'action': 'import',
        'sheetId': sheetId,
        'range': range ?? 'A:F',
      };

      final response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Import failed: ${response.body}');
      }

      final result = jsonDecode(response.body);
      
      return ImportResult(
        success: result['success'] == true,
        data: List<Map<String, dynamic>>.from(result['data'] ?? []),
        rowCount: result['rowCount'] ?? 0,
        message: result['message'],
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Erreur: $e',
      );
    }
  }

  /// Créer une nouvelle spreadsheet via API directe
  Future<String?> createSpreadsheet(String title) async {
    if (_authClient == null) {
      throw Exception('Not authenticated. Call authenticate() first.');
    }

    final api = sheets.SheetsApi(_authClient!);
    
    final spreadsheet = sheets.Spreadsheet(
      properties: sheets.SpreadsheetProperties(title: title),
      sheets: [
        sheets.Sheet(
          properties: sheets.SheetProperties(
            title: 'Inventaire',
            gridProperties: sheets.GridProperties(
              rowCount: 1000,
              columnCount: 10,
            ),
          ),
        ),
      ],
    );

    final result = await api.spreadsheets.create(spreadsheet);
    return result.spreadsheetId;
  }

  /// Écrire des données via API directe
  Future<void> writeData(String spreadsheetId, List<List<dynamic>> values) async {
    if (_authClient == null) {
      throw Exception('Not authenticated');
    }

    final api = sheets.SheetsApi(_authClient!);
    
    final valueRange = sheets.ValueRange(
      values: values,
    );

    await api.spreadsheets.values.append(
      valueRange,
      spreadsheetId,
      'A1',
      valueInputOption: 'USER_ENTERED',
    );
  }

  void dispose() {
    _authClient?.close();
  }
}

class ExportResult {
  final bool success;
  final String? sheetUrl;
  final String? sheetId;
  final int rowCount;
  final String? message;

  ExportResult({
    required this.success,
    this.sheetUrl,
    this.sheetId,
    this.rowCount = 0,
    this.message,
  });
}

class ImportResult {
  final bool success;
  final List<Map<String, dynamic>> data;
  final int rowCount;
  final String? message;

  ImportResult({
    required this.success,
    this.data = const [],
    this.rowCount = 0,
    this.message,
  });
}