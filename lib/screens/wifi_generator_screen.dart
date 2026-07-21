import 'dart:async';
import 'package:flutter/material.dart';
import '../models/qr_data.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/qr_export_service.dart';
import '../widgets/qr_preview.dart';
import '../widgets/customization_panel.dart';

class WiFiGeneratorScreen extends StatefulWidget {
  const WiFiGeneratorScreen({super.key});

  @override
  State<WiFiGeneratorScreen> createState() => _WiFiGeneratorScreenState();
}

class _WiFiGeneratorScreenState extends State<WiFiGeneratorScreen> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  String _encryptionType = 'WPA';
  bool _isHidden = false;
  bool _obscurePassword = true;

  int _foregroundColor = 0xFF212121;
  int _backgroundColor = 0xFFFFFFFF;
  double _correctionLevel = 0.15;
  String? _frameText;
  Timer? _debounce;

  WiFiQRData? _currentQR;
  bool _isSaved = false;

  bool get hasUnsavedChanges => _currentQR != null && !_isSaved;

  @override
  void dispose() {
    _debounce?.cancel();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _generateQR);
  }

  void _generateQR() {
    if (_ssidController.text.isEmpty) return;
    setState(() {
      _isSaved = false;
      _currentQR = WiFiQRData(
        ssid: _ssidController.text,
        password: _passwordController.text,
        encryptionType: _encryptionType,
        isHidden: _isHidden,
        foregroundColor: _foregroundColor,
        backgroundColor: _backgroundColor,
        correctionLevel: _correctionLevel,
        frameText: _frameText,
      );
    });
  }

  void loadFromData(QRData data) {
    final ssidMatch = RegExp(r'S:([^;]+)').firstMatch(data.content);
    final passMatch = RegExp(r'P:([^;]+)').firstMatch(data.content);
    final typeMatch = RegExp(r'T:([^;]+)').firstMatch(data.content);
    final hiddenMatch = RegExp(r'H:true').firstMatch(data.content);

    _ssidController.text = ssidMatch?.group(1) ?? '';
    _passwordController.text = passMatch?.group(1) ?? '';
    _encryptionType = typeMatch?.group(1) ?? 'WPA';
    _isHidden = hiddenMatch != null;
    _foregroundColor = data.foregroundColor;
    _backgroundColor = data.backgroundColor;
    _correctionLevel = data.correctionLevel;
    _frameText = data.frameText;
    setState(() {
      _isSaved = true;
      _currentQR = WiFiQRData(
        ssid: _ssidController.text,
        password: _passwordController.text,
        encryptionType: _encryptionType,
        isHidden: _isHidden,
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
              'Network Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: 'Network Name (SSID) *',
                hintText: 'My WiFi Network',
                prefixIcon: Icon(Icons.wifi),
              ),
              onChanged: (_) => _onFieldChanged(),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              onChanged: (_) => _onFieldChanged(),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _encryptionType,
              decoration: InputDecoration(
                labelText: 'Encryption Type',
                prefixIcon: Icon(Icons.security),
              ),
              items: [
                DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
                DropdownMenuItem(value: 'WEP', child: Text('WEP')),
                DropdownMenuItem(value: '', child: Text('None')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _encryptionType = value;
                  _generateQR();
                }
              },
            ),
            SizedBox(height: 12),
            SwitchListTile(
              title: Text('Hidden Network'),
              subtitle: Text(
                'Enable if network SSID is hidden',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              value: _isHidden,
              onChanged: (value) {
                _isHidden = value;
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
                                  'Enter SSID to preview',
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
                'Wi-Fi Generator',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create a QR code for Wi-Fi network access',
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
