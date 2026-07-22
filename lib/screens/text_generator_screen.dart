import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/qr_preview_card.dart';
import '../../widgets/customization_panel.dart';
import 'generators/generator_resettable.dart';
import 'generators/text_generator_state.dart';

class TextGeneratorScreen extends StatefulWidget {
  const TextGeneratorScreen({super.key});

  @override
  State<TextGeneratorScreen> createState() => _TextGeneratorScreenState();
}

class _TextGeneratorScreenState extends State<TextGeneratorScreen>
    implements GeneratorResettable {
  final _state = TextGeneratorState();
  static const int _maxCharacters = 2500;

  @override
  bool get hasUnsavedChanges => _state.hasUnsavedChanges;

  @override
  void reset() {
    setState(() => _state.reset());
  }

  @override
  void loadFromData(QRData data) {
    setState(() => _state.loadFromData(data));
  }

  @override
  Future<void> saveToHistory() => _state.saveToHistory(context);

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() => _state.generateQR());
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
              controller: _state.textController,
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
                    child: Text('Clear'),
                  ),
              ],
            ),
            SizedBox(height: 24),
            CustomizationPanel(
              foregroundColor: _state.foregroundColor,
              backgroundColor: _state.backgroundColor,
              correctionLevel: _state.correctionLevel,
              frameText: _state.frameText,
              onForegroundColorChanged: (color) {
                setState(() => _state.foregroundColor = color);
                setState(() => _state.generateQR());
              },
              onBackgroundColorChanged: (color) {
                setState(() => _state.backgroundColor = color);
                setState(() => _state.generateQR());
              },
              onCorrectionLevelChanged: (level) {
                setState(() => _state.correctionLevel = level);
                setState(() => _state.generateQR());
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
                    QrPreviewCard(
                      currentQR: _state.currentQR,
                      emptyHint: 'Enter text to preview',
                      compact: true,
                    ),
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
                    Expanded(
                      flex: 1,
                      child: QrPreviewCard(
                        currentQR: _state.currentQR,
                        emptyHint: 'Enter text to preview',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
