import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customization_panel.dart';
import '../../widgets/qr_preview_card.dart';
import 'generators/generator_resettable.dart';
import 'generators/vcard_generator_state.dart';

class VCardGeneratorScreen extends StatefulWidget {
  const VCardGeneratorScreen({super.key});

  @override
  State<VCardGeneratorScreen> createState() => _VCardGeneratorScreenState();
}

class _VCardGeneratorScreenState extends State<VCardGeneratorScreen>
    implements GeneratorResettable {
  final _state = VCardGeneratorState();
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
              'Contact Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _state.fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'John Doe',
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _state.phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                hintText: '+1 234 567 890',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _state.emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'john@example.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _state.organizationController,
              decoration: const InputDecoration(
                labelText: 'Organization',
                hintText: 'Company Name',
                prefixIcon: Icon(Icons.business),
              ),
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _state.websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => _onFieldChanged(),
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

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_state.fullNameController.text.isNotEmpty)
            Text(
              _state.fullNameController.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          if (_state.organizationController.text.isNotEmpty)
            Text(
              _state.organizationController.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          const Divider(height: 24),
          if (_state.phoneController.text.isNotEmpty)
            _buildContactRow(Icons.phone, _state.phoneController.text),
          if (_state.emailController.text.isNotEmpty)
            _buildContactRow(Icons.email, _state.emailController.text),
          if (_state.websiteController.text.isNotEmpty)
            _buildContactRow(Icons.language, _state.websiteController.text),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
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
                'vCard Generator',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a QR code for your contact information',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              if (stacked)
                Column(
                  children: [
                    QrPreviewCard(
                      currentQR: _state.currentQR,
                      emptyHint: 'Enter name to preview',
                      compact: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputCard(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildInputCard()),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          QrPreviewCard(
                            currentQR: _state.currentQR,
                            emptyHint: 'Enter name to preview',
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Contact Card Preview',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_state.fullNameController.text.isNotEmpty)
                                    _buildContactCard()
                                  else
                                    const Text(
                                      'Enter contact details to see preview',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
