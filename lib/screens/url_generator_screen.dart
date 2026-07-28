import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customization_panel.dart';
import 'generators/generator_resettable.dart';
import 'generators/url_generator_state.dart';
import 'generators/generator_screen_layout.dart';

class URLGeneratorScreen extends StatefulWidget {
  const URLGeneratorScreen({super.key});

  @override
  State<URLGeneratorScreen> createState() => _URLGeneratorScreenState();
}

class _URLGeneratorScreenState extends State<URLGeneratorScreen>
    implements GeneratorResettable {
  final _state = URLGeneratorState();
  Timer? _debounce;

  @override
  bool get hasUnsavedChanges => _state.hasUnsavedChanges;

  @override
  void reset() => setState(_state.reset);

  @override
  void loadFromData(QRData data, {bool markAsSaved = true}) {
    setState(() => _state.loadFromData(data, markAsSaved: markAsSaved));
  }

  @override
  Future<void> saveToHistory() async {
    await _state.saveToHistory(context);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _state.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    _debounce?.cancel();
    _state.isSaved = false;
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setState(_state.generateQR),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter URL',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _state.urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Dynamic Short Link'),
              subtitle: const Text(
                'Enable tracking and analytics',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              value: _state.isDynamicShortLink,
              onChanged: (value) {
                setState(() {
                  _state.isDynamicShortLink = value;
                  _state.generateQR();
                });
              },
              activeThumbColor: AppTheme.primaryPurple,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            CustomizationPanel(
              foregroundColor: _state.foregroundColor,
              backgroundColor: _state.backgroundColor,
              correctionLevel: _state.correctionLevel,
              frameText: _state.frameText,
              onForegroundColorChanged: (color) {
                setState(() {
                  _state.foregroundColor = color;
                  _state.generateQR();
                });
              },
              onBackgroundColorChanged: (color) {
                setState(() {
                  _state.backgroundColor = color;
                  _state.generateQR();
                });
              },
              onCorrectionLevelChanged: (level) {
                setState(() {
                  _state.correctionLevel = level;
                  _state.generateQR();
                });
              },
              onFrameTextChanged: (text) {
                setState(() => _state.frameText = text);
                _onFieldChanged();
              },
              onSave: _state.currentQR != null ? saveToHistory : null,
              isSaved: _state.isSaved,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GeneratorScreenLayout(
      title: 'URL Generator',
      subtitle: 'Create a QR code for any URL or website',
      emptyHint: 'Enter a URL to preview',
      currentQR: _state.currentQR,
      inputCard: _buildInputCard(),
    );
  }
}
