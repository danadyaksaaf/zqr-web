import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/qr_data.dart';

class QRPreviewWidget extends StatelessWidget {
  final QRData qrData;
  final bool showFrame;

  const QRPreviewWidget({
    super.key,
    required this.qrData,
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = Color(qrData.foregroundColor);
    final backgroundColor = Color(qrData.backgroundColor);
    final hasFrameText =
        qrData.frameText != null && qrData.frameText!.isNotEmpty;

    return FractionallySizedBox(
      widthFactor: 0.88,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
        padding: showFrame ? EdgeInsets.all(24) : null,
        decoration: showFrame
            ? BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: foregroundColor.withValues(alpha: 0.1),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: foregroundColor.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              )
            : null,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: qrData.content,
                version: QrVersions.auto,
                size: 100,
                backgroundColor: backgroundColor,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: foregroundColor,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: foregroundColor,
                ),
                embeddedImage: qrData.logoPath != null
                    ? NetworkImage(qrData.logoPath!)
                    : null,
                embeddedImageStyle: qrData.logoPath != null
                    ? QrEmbeddedImageStyle(size: Size(40, 40))
                    : null,
              ),
              if (hasFrameText) ...[
                SizedBox(height: 8),
                SizedBox(
                  width: 100,
                  child: Text(
                    qrData.frameText!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }
}
