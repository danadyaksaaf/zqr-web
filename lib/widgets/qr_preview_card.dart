import 'package:flutter/material.dart';
import '../models/qr_data.dart';
import '../theme/app_theme.dart';
import '../services/qr_export_service.dart';
import 'qr_preview.dart';

class QrPreviewCard extends StatelessWidget {
  final QRData? currentQR;
  final String emptyHint;
  final bool compact;

  const QrPreviewCard({
    super.key,
    this.currentQR,
    required this.emptyHint,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 24),
        child: Column(
          children: [
            Text(
              'Preview',
              style:
                  (compact
                          ? Theme.of(context).textTheme.titleSmall
                          : Theme.of(context).textTheme.titleMedium)
                      ?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: compact ? 8 : 16),
            Center(
              child: SizedBox(
                width: compact ? 154 : null,
                height: compact ? 154 : null,
                child: currentQR != null
                    ? QRPreviewWidget(qrData: currentQR!)
                    : AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.divider,
                              width: 2,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code_2,
                                  size: 64,
                                  color: AppTheme.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                Text(
                                  emptyHint,
                                  style: TextStyle(
                                    fontSize: 5,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(height: compact ? 8 : 16),
            if (currentQR != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 200;
                  if (stacked) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              QrExportService.saveAsPng(context, currentQR!);
                            },
                            icon: Icon(Icons.download),
                            label: Text('PNG'),
                          ),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              QrExportService.showSvgExportModal(
                                context,
                                currentQR!,
                              );
                            },
                            icon: Icon(Icons.code),
                            label: Text('SVG'),
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Flexible(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              QrExportService.saveAsPng(context, currentQR!);
                            },
                            icon: Icon(Icons.download),
                            label: Text('PNG'),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              QrExportService.showSvgExportModal(
                                context,
                                currentQR!,
                              );
                            },
                            icon: Icon(Icons.code),
                            label: Text('SVG'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
