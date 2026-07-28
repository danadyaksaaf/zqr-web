import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'dart:async';

import 'package:web/web.dart' as web;

import '../models/qr_data.dart';

@JS('BarcodeDetector')
extension type _BarcodeDetector._(JSObject _) implements JSObject {
  external factory _BarcodeDetector();
  external JSPromise<JSArray> detect(JSObject image);
}

enum QRDecoderErrorType { noQrFound, unsupported, decodeFailed }

class QRDecoderResult {
  QRDecoderResult._({
    required this.rawContent,
    this.parsedData,
    this.detectedType,
    required this.isSupported,
    this.errorType,
  });

  factory QRDecoderResult.success(String content, QRData parsed) {
    return QRDecoderResult._(
      rawContent: content,
      parsedData: parsed,
      detectedType: parsed.type,
      isSupported: true,
    );
  }

  factory QRDecoderResult.noQrFound() {
    return QRDecoderResult._(
      rawContent: '',
      isSupported: false,
      errorType: QRDecoderErrorType.noQrFound,
    );
  }

  factory QRDecoderResult.unsupported(String content) {
    return QRDecoderResult._(
      rawContent: content,
      isSupported: false,
      errorType: QRDecoderErrorType.unsupported,
    );
  }

  factory QRDecoderResult.error() {
    return QRDecoderResult._(
      rawContent: '',
      isSupported: false,
      errorType: QRDecoderErrorType.decodeFailed,
    );
  }

  final String rawContent;
  final QRData? parsedData;
  final QRType? detectedType;
  final bool isSupported;
  final QRDecoderErrorType? errorType;
}

String _detectMimeType(Uint8List bytes) {
  if (bytes.length >= 4) {
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      return 'image/webp';
    }
  }
  return 'image/png';
}

class QRDecoderService {
  static Future<QRDecoderResult> decodeFromBytes(Uint8List imageBytes) async {
    try {
      final barcodeDetectorSupported =
          web.window.hasProperty('BarcodeDetector'.toJS).toDart;
      developer.log('BarcodeDetector available: $barcodeDetectorSupported');
      if (!barcodeDetectorSupported) {
        return QRDecoderResult.error();
      }

      final detector = _BarcodeDetector();

      final mimeType = _detectMimeType(imageBytes);
      developer.log('Detected MIME type: $mimeType');

      final blob = web.Blob(
        [imageBytes.toJS].toJS,
        web.BlobPropertyBag(type: mimeType),
      );
      final blobUrl = web.URL.createObjectURL(blob);

      try {
        final img = web.document.createElement('img') as web.HTMLImageElement;

        final completer = Completer<void>();
        img.onLoad.listen((_) {
          if (!completer.isCompleted) completer.complete();
        });
        img.onError.listen((_) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Failed to load image'));
          }
        });

        img.src = blobUrl;
        await completer.future;

        developer.log('Image loaded, running BarcodeDetector.detect()');

        final results = await detector.detect(img as JSObject).toDart;
        developer.log('BarcodeDetector results length: ${results.length}');

        if (results.length == 0) {
          return QRDecoderResult.noQrFound();
        }

        final barcode = results[0] as JSObject?;
        if (barcode == null) {
          return QRDecoderResult.noQrFound();
        }

        final rawValue = barcode.getProperty('rawValue'.toJS).dartify() as String?;
        developer.log('Decoded rawValue: $rawValue');

        if (rawValue == null || rawValue.isEmpty) {
          return QRDecoderResult.noQrFound();
        }

        final parsed = _parseToQRData(rawValue);
        if (parsed == null) {
          return QRDecoderResult.unsupported(rawValue);
        }

        return QRDecoderResult.success(rawValue, parsed);
      } finally {
        web.URL.revokeObjectURL(blobUrl);
      }
    } catch (e, stack) {
      developer.log('QR decode error: $e', stackTrace: stack);
      return QRDecoderResult.error();
    }
  }

  static QRData? _parseToQRData(String decoded) {
    final type = QRData.detectType(decoded);
    if (type == null) return null;

    switch (type) {
      case QRType.url:
        return URLQRData(url: decoded);
      case QRType.vcard:
        return _parseVCard(decoded);
      case QRType.wifi:
        return _parseWiFi(decoded);
      case QRType.text:
        return TextQRData(text: decoded);
    }
  }

  static VCardQRData _parseVCard(String content) {
    String extract(String field) {
      final regex = RegExp('$field:(.*)', caseSensitive: false);
      final match = regex.firstMatch(content);
      return match != null ? match.group(1)?.trim() ?? '' : '';
    }

    final fullName = extract('FN');
    if (fullName.isEmpty) return VCardQRData(fullName: content);

    return VCardQRData(
      fullName: fullName,
      phone: extract('TEL'),
      email: extract('EMAIL'),
      organization: extract('ORG'),
      website: extract('URL'),
    );
  }

  static WiFiQRData _parseWiFi(String content) {
    String extract(String field) {
      final regex = RegExp('$field:([^;]*)', caseSensitive: false);
      final match = regex.firstMatch(content);
      return match != null ? match.group(1)?.trim() ?? '' : '';
    }

    final ssid = extract('S');
    if (ssid.isEmpty) return WiFiQRData(ssid: content);

    final encType = extract('T');
    final isHidden = content.toUpperCase().contains('H:true');

    return WiFiQRData(
      ssid: ssid,
      password: extract('P'),
      encryptionType: encType.isEmpty ? 'WPA' : encType,
      isHidden: isHidden,
    );
  }
}
