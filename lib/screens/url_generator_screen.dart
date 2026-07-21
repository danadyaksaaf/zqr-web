import 'package:flutter/material.dart';
import '../models/qr_data.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/qr_export_service.dart';
import '../widgets/qr_preview.dart';
import '../widgets/customization_panel.dart';

class URLGeneratorScreen extends StatefulWidget {
  const URLGeneratorScreen({super.key});

  @override
  State<URLGeneratorScreen> createState() => _URLGeneratorScreenState();
}

class _URLGeneratorScreenState extends State<URLGeneratorScreen> {
  final _urlController = TextEditingController();
  bool _isDynamicShortLink = false;
  int _foregroundColor = 0xFF212121;
  int _backgroundColor = 0xFFFFFFFF;
  double _correctionLevel = 0.15;
  String? _frameText;

  URLQRData? _currentQR;
  bool _isSaved = false;

  bool get hasUnsavedChanges => _currentQR != null && !_isSaved;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _generateQR() {
    if (_urlController.text.isEmpty) return;
    setState(() {
      _isSaved = false;
      _currentQR = URLQRData(
        url: _urlController.text,
        isDynamicShortLink: _isDynamicShortLink,
        foregroundColor: _foregroundColor,
        backgroundColor: _backgroundColor,
        correctionLevel: _correctionLevel,
        frameText: _frameText,
      );
    });
  }

  void loadFromData(QRData data) {
    _urlController.text = data.content;
    _foregroundColor = data.foregroundColor;
    _backgroundColor = data.backgroundColor;
    _correctionLevel = data.correctionLevel;
    _frameText = data.frameText;
    setState(() {
      _isSaved = true;
      _currentQR = URLQRData(
        url: data.content,
        foregroundColor: data.foregroundColor,
        backgroundColor: data.backgroundColor,
        correctionLevel: data.correctionLevel,
        frameText: data.frameText,
      );
    });
  }

  Future<void> saveToHistory() async {
    if (_currentQR == null) return;
    await HistoryService().addItem(_currentQR!);
    setState(() => _isSaved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR code saved to history'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter URL',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => _generateQR(),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Dynamic Short Link'),
              subtitle: Text(
                'Enable tracking and analytics',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              value: _isDynamicShortLink,
              onChanged: (value) {
                setState(() => _isDynamicShortLink = value);
                _generateQR();
              },
              activeThumbColor: AppTheme.primaryPurple,
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: 24),
            CustomizationPanel(
              foregroundColor: _foregroundColor,
              backgroundColor: _backgroundColor,
              correctionLevel: _correctionLevel,
              frameText: _frameText,
              onForegroundColorChanged: (color) {
                setState(() => _foregroundColor = color);
                _generateQR();
              },
              onBackgroundColorChanged: (color) {
                setState(() => _backgroundColor = color);
                _generateQR();
              },
              onCorrectionLevelChanged: (level) {
                setState(() => _correctionLevel = level);
                _generateQR();
              },
              onFrameTextChanged: (text) {
                setState(() => _frameText = text);
                _generateQR();
              },
              onSave: _currentQR != null ? saveToHistory : null,
              isSaved: _isSaved,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard({bool compact = false}) {
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
                width: compact ? 140 : null,
                height: compact ? 140 : null,
                child: _currentQR != null
                    ? QRPreviewWidget(qrData: _currentQR!)
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
                                  'Enter a URL to preview',
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
            if (_currentQR != null)
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
                              QrExportService.saveAsPng(context, _currentQR!);
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
                                _currentQR!,
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
                              QrExportService.saveAsPng(context, _currentQR!);
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
                                _currentQR!,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.all(stacked ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'URL Generator',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create a QR code for any URL or website',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              SizedBox(height: 24),
              if (stacked)
                Column(
                  children: [
                    _buildPreviewCard(compact: true),
                    SizedBox(height: 16),
                    _buildInputCard(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildInputCard()),
                    SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildPreviewCard()),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
