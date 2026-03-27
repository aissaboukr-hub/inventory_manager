import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'sound_player.dart';

class BarcodeScannerService {
  final SoundPlayer? _externalSoundPlayer;
  late final SoundPlayer _internalSoundPlayer;
  final StreamController<String> _barcodeController = 
      StreamController<String>.broadcast();
  
  bool _isProcessing = false;
  DateTime _lastScanTime = DateTime.now();

  BarcodeScannerService({SoundPlayer? soundPlayer}) 
      : _externalSoundPlayer = soundPlayer {
    _internalSoundPlayer = soundPlayer ?? SoundPlayer();
  }
  
  SoundPlayer get _soundPlayer => _externalSoundPlayer ?? _internalSoundPlayer;

  Stream<String> get barcodeStream => _barcodeController.stream;

  StreamSubscription<String> listen(
    void Function(String barcode) onBarcode, {
    void Function(Object error)? onError,
  }) {
    return _barcodeController.stream.listen(onBarcode, onError: onError);
  }

  Future<void> handleBarcode(
    BarcodeCapture capture, {
    required Function(String barcode) onBarcode,
    required Function(String error) onError,
  }) async {
    if (_isProcessing) return;
    
    final now = DateTime.now();
    if (now.difference(_lastScanTime).inMilliseconds < 1500) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    final trimmedCode = code.trim();
    _isProcessing = true;
    _lastScanTime = now;

    try {
      if (_isValidBarcode(trimmedCode)) {
        await _soundPlayer.playBeep();
        _barcodeController.add(trimmedCode);
        onBarcode(trimmedCode);
      } else {
        throw Exception('Format code-barres invalide: $trimmedCode');
      }
    } catch (e) {
      await _soundPlayer.playError();
      final errorMsg = e is Exception ? e.toString() : 'Erreur scan: ${e.runtimeType}';
      onError(errorMsg);
    } finally {
      await Future.delayed(const Duration(milliseconds: 800));
      _isProcessing = false;
    }
  }

  Future<void> playBeep() => _soundPlayer.playBeep();
  
  Future<void> playError() => _soundPlayer.playError();

  bool _isValidBarcode(String code) {
    if (code.isEmpty) return false;
    if (code.length < 4 || code.length > 50) return false;
    
    final validPatterns = [
      RegExp(r'^\d{8}$'),      // EAN-8
      RegExp(r'^\d{13}$'),     // EAN-13
      RegExp(r'^\d{12}$'),     // UPC-A
      RegExp(r'^[A-Z0-9\-\.\$\/\+\%\s]+$'), // Code 128/39
    ];
    
    return validPatterns.any((pattern) => pattern.hasMatch(code));
  }

  void dispose() {
    if (_externalSoundPlayer == null) {
      _internalSoundPlayer.dispose();
    }
    _barcodeController.close();
  }
}