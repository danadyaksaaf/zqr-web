import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web/web.dart' as web;

import '../models/qr_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_messages.dart';

class QrExportService {
  static int _errorCorrectionForLevel(double level) {
    if (level <= 0.07) return QrErrorCorrectLevel.L;
    if (level <= 0.15) return QrErrorCorrectLevel.M;
    if (level <= 0.25) return QrErrorCorrectLevel.Q;
    return QrErrorCorrectLevel.H;
  }

  static QrPainter _buildPainter(QRData qrData) {
    return QrPainter(
      data: qrData.content,
      version: QrVersions.auto,
      errorCorrectionLevel: _errorCorrectionForLevel(qrData.correctionLevel),
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(qrData.foregroundColor),
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(qrData.foregroundColor),
      ),
      gapless: true,
    );
  }

  static void _downloadBytes(Uint8List bytes, String fileName, String mimeType) {
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..setAttribute('download', fileName);
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  static void _downloadString(String content, String fileName, String mimeType) {
    final blob = web.Blob([content.toJS].toJS, web.BlobPropertyBag(type: mimeType));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..setAttribute('download', fileName);
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  static Future<void> saveAsPng(BuildContext context, QRData qrData) async {
    try {
      final painter = _buildPainter(qrData);
      const size = 900.0;
      final hasFrameText =
          qrData.frameText != null && qrData.frameText!.isNotEmpty;
      final canvasHeight = hasFrameText ? 1000.0 : size;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(Color(qrData.backgroundColor), BlendMode.src);
      painter.paint(canvas, const Size(size, size));

      if (hasFrameText) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: qrData.frameText,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
              letterSpacing: 1.5,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: 1,
          ellipsis: '...',
        );
        textPainter.layout(maxWidth: size);
        final textY = size + (canvasHeight - size - textPainter.height) / 2;
        textPainter.paint(
          canvas,
          Offset((size - textPainter.width) / 2, textY),
        );
      }

      final picture = recorder.endRecording();
      final image =
          await picture.toImage(size.toInt(), canvasHeight.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (context.mounted) {
          AppMessages.showError(context, 'Download failed. Something went wrong. Please try again.');
        }
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      _downloadBytes(pngBytes, 'qr_code.png', 'image/png');

      if (context.mounted) {
        AppMessages.showSuccess(context, 'QR code downloaded as PNG.');
      }
    } catch (e) {
      if (context.mounted) {
        AppMessages.showError(context, 'Download failed. Something went wrong. Please try again.');
      }
    }
  }

  static String _buildSvgString(QRData qrData) {
    final ecLevel = _errorCorrectionForLevel(qrData.correctionLevel);
    final qr = QrCode.fromData(
      data: qrData.content,
      errorCorrectLevel: ecLevel,
    );
    final qrImage = QrImage(qr);
    final moduleCount = qrImage.moduleCount;
    const viewBoxSize = 400;
    final moduleSize = viewBoxSize / moduleCount;
    final hasFrameText =
        qrData.frameText != null && qrData.frameText!.isNotEmpty;
    final viewBoxHeight = hasFrameText ? 460 : viewBoxSize;

    final fg = _colorToHex(Color(qrData.foregroundColor));
    final bg = _colorToHex(Color(qrData.backgroundColor));

    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 $viewBoxSize $viewBoxHeight" '
        'shape-rendering="crispEdges">',
      )
      ..writeln(
        '  <rect width="$viewBoxSize" height="$viewBoxHeight" fill="$bg"/>',
      );

    for (var row = 0; row < moduleCount; row++) {
      for (var col = 0; col < moduleCount; col++) {
        if (qrImage.isDark(row, col)) {
          final x = (col * moduleSize).toStringAsFixed(2);
          final y = (row * moduleSize).toStringAsFixed(2);
          final s = moduleSize.toStringAsFixed(2);
          buffer.writeln(
            '  <rect x="$x" y="$y" width="$s" height="$s" fill="$fg"/>',
          );
        }
      }
    }

    if (hasFrameText) {
      const textY = viewBoxSize + 40;
      buffer.writeln(
        '  <text x="${viewBoxSize / 2}" y="$textY" '
        'text-anchor="middle" font-family="sans-serif" '
        'font-size="22" font-weight="600" '
        'letter-spacing="1" fill="$fg">'
        '${_escapeXml(qrData.frameText!)}</text>',
      );
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static Future<void> showSvgExportModal(
    BuildContext context,
    QRData qrData,
  ) async {
    try {
      final svgString = _buildSvgString(qrData);

      if (!context.mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => _SvgExportSheet(svgString: svgString),
      );
    } catch (e) {
      if (context.mounted) {
        AppMessages.showError(context, 'Download failed. Something went wrong. Please try again.');
      }
    }
  }
}

class _SvgExportSheet extends StatelessWidget {
  const _SvgExportSheet({required this.svgString});

  final String svgString;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Export SVG',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 180,
            width: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: SvgPicture.string(svgString),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  final dataUri =
                      'data:image/svg+xml;base64,${base64Encode(utf8.encode(svgString))}';
                  await Clipboard.setData(ClipboardData(text: dataUri));
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppMessages.showSuccess(context, 'SVG copied to clipboard.');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppMessages.showError(context, 'Failed to copy. Please try again.');
                  }
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy SVG Data URI'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  QrExportService._downloadString(
                    svgString,
                    'qr_code.svg',
                    'image/svg+xml',
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppMessages.showSuccess(context, 'SVG file saved.');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppMessages.showError(context, 'Download failed. Something went wrong. Please try again.');
                  }
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Save as SVG File'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}
