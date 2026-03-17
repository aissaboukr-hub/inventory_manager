import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'sound_player.dart';

class BarcodeScannerService {
  final SoundPlayer _soundPlayer = SoundPlayer();
  final StreamController<String> _barcodeController = 
      StreamController<String>.broadcast();
  
  bool _isProcessing = false;
  DateTime _lastScanTime = DateTime.now();

  Stream<String> get barcodeStream => _barcodeController.stream;

  void handleBarcode(
    BarcodeCapture capture, {
    required Function(String barcode) onBarcode,
    required Function(String error) onError,
  }) async {
    if (_isProcessing) return;
    
    // Debounce check
    final now = DateTime.now();
    if (now.difference(_lastScanTime).inMilliseconds < 1500) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _isProcessing = true;
    _lastScanTime = now;

    try {
      // Validation du format code-barres
      if (_isValidBarcode(code)) {
        await _soundPlayer.playBeep();
        _barcodeController.add(code);
        onBarcode(code);
      } else {
        throw Exception('Format code-barres invalide');
      }
    } catch (e) {
      await _soundPlayer.playError();
      onError(e.toString());
    } finally {
      await Future.delayed(const Duration(seconds: 1));
      _isProcessing = false;
    }
  }

   // ← AJOUTER CETTE MÉTHODE PUBLIQUE
  Future<void> playBeep() async {
    await _soundPlayer.playBeep();
  }

  Future<void> playError() async {
    await _soundPlayer.playError();
  }

  bool _isValidBarcode(String code) {
    // EAN-8, EAN-13, UPC-A, Code 128, Code 39
    final validPatterns = [
      RegExp(r'^\d{8}$'),      // EAN-8
      RegExp(r'^\d{13}$'),     // EAN-13
      RegExp(r'^\d{12}$'),     // UPC-A
      RegExp(r'^[A-Z0-9\-\.\$\/\+\%\s]+$'), // Code 128/39
    ];
    
    return validPatterns.any((pattern) => pattern.hasMatch(code)) || 
           code.length >= 4;
  }

  void dispose() {
    _soundPlayer.dispose();
    _barcodeController.close();
  }
}