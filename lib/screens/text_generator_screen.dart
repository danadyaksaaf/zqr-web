import 'dart:async';
import 'package:flutter/material.dart';
import '../models/qr_data.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/qr_export_service.dart';
import '../widgets/qr_preview.dart';
import '../widgets/customization_panel.dart';

class TextGeneratorScreen extends StatefulWidget {
  const TextGeneratorScreen({super.key});

  @override
  State<TextGeneratorScreen> createState() => _TextGeneratorScreenState();
}

class _TextGeneratorScreenState extends State<TextGeneratorScreen> {
  final _textController = TextEditingController();
  static const int _maxCharacters = 2500;
  Timer? _debounce;

  int _foregroundColor = 0xFF212121;
  int _backgroundColor = 0xFFFFFFFF;
  double _correctionLevel = 0.15;
  String? _frameText;

  TextQRData? _currentQR;
  bool _isSaved = false;

  bool get hasUnsavedChanges => _currentQR != null && !_isSaved;

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _generateQR);
  }

  void _generateQR() {
    if (_textController.text.isEmpty) return;
    setState(() {
      _isSaved = false;
      _currentQR = TextQRData(
        text: _textController.text,
        foregroundColor: _foregroundColor,
        backgroundColor: _backgroundColor,
        correctionLevel: _correctionLevel,
        frameText: _frameText,
      );
    });
  }

  void loadFromData(QRData data) {
    _textController.text = data.content;
    _foregroundColor = data.foregroundColor;
    _backgroundColor = data.backgroundColor;
    _correctionLevel = data.correctionLevel;
    _frameText = data.frameText;
    setState(() {
      _isSaved = true;
      _currentQR = TextQRData(
        text: data.content,
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
              'Enter Text',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Text Content *',
                hintText: 'Enter your text here...',
                prefixIcon: Icon(Icons.text_fields),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              maxLength: _maxCharacters,
              onChanged: (_) => _onFieldChanged(),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${_textController.text.length} / $_maxCharacters characters',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textController.text.length > _maxCharacters * 0.9
                          ? AppTheme.error
                          : AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_textController.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _textController.clear();
                      setState(() => _currentQR = null);
                    },
                    child: Text('Clear'),
                  ),
              ],
            ),
            SizedBox(height: 24),
            CustomizationPanel(
              foregroundColor: _foregroundColor,
              backgroundColor: _backgroundColor,
              correctionLevel: _correctionLevel,
              frameText: _frameText,
              onForegroundColorChanged: (color) {
                _foregroundColor = color;
                _generateQR();
              },
              onBackgroundColorChanged: (color) {
                _backgroundColor = color;
                _generateQR();
              },
              onCorrectionLevelChanged: (level) {
                _correctionLevel = level;
                _generateQR();
              },
              onFrameTextChanged: (text) {
                _frameText = text;
                _onFieldChanged();
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
                                  'Enter text to preview',
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
                'Text Generator',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create a QR code for raw text or notes',
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
