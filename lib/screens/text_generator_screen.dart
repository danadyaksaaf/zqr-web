import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customization_panel.dart';
import 'generators/generator_resettable.dart';
import 'generators/text_generator_state.dart';
import 'generators/generator_screen_layout.dart';

class TextGeneratorScreen extends StatefulWidget {
  const TextGeneratorScreen({super.key});

  @override
  State<TextGeneratorScreen> createState() => _TextGeneratorScreenState();
}

class _TextGeneratorScreenState extends State<TextGeneratorScreen>
    implements GeneratorResettable {
  final _state = TextGeneratorState();
  Timer? _debounce;
  static const int _maxCharacters = 2500;

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
              'Enter Text',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _state.textController,
              decoration: const InputDecoration(
                labelText: 'Text Content *',
                hintText: 'Enter your text here...',
                prefixIcon: Icon(Icons.text_fields),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              maxLength: _maxCharacters,
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${_state.textController.text.length} / $_maxCharacters characters',
                    style: TextStyle(
                      fontSize: 12,
                      color: _state.textController.text.length >
                              _maxCharacters * 0.9
                          ? AppTheme.error
                          : AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_state.textController.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _state.textController.clear();
                      setState(() => _state.currentQR = null);
                    },
                    child: const Text('Clear'),
                  ),
              ],
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
      title: 'Text Generator',
      subtitle: 'Create a QR code for raw text or notes',
      emptyHint: 'Enter text to preview',
      currentQR: _state.currentQR,
      inputCard: _buildInputCard(),
    );
  }
}
