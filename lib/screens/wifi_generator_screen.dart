import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customization_panel.dart';
import 'generators/generator_resettable.dart';
import 'generators/wifi_generator_state.dart';
import 'generators/generator_screen_layout.dart';

class WiFiGeneratorScreen extends StatefulWidget {
  const WiFiGeneratorScreen({super.key});

  @override
  State<WiFiGeneratorScreen> createState() => _WiFiGeneratorScreenState();
}

class _WiFiGeneratorScreenState extends State<WiFiGeneratorScreen>
    implements GeneratorResettable {
  final _state = WiFiGeneratorState();
  Timer? _debounce;

  @override
  bool get hasUnsavedChanges => _state.hasUnsavedChanges;

  @override
  void reset() {
    setState(() => _state.reset());
  }

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
      () => setState(() => _state.generateQR()),
    );
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
              controller: _state.ssidController,
              decoration: InputDecoration(
                labelText: 'Network Name (SSID) *',
                hintText: 'My WiFi Network',
                prefixIcon: Icon(Icons.wifi),
              ),
              onChanged: (_) => _onFieldChanged(),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _state.passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _state.obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _state.obscurePassword = !_state.obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _state.obscurePassword,
              onChanged: (_) => _onFieldChanged(),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _state.encryptionType,
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
                  setState(() {
                    _state.encryptionType = value;
                    _state.generateQR();
                  });
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
              value: _state.isHidden,
              onChanged: (value) {
                setState(() {
                  _state.isHidden = value;
                  _state.generateQR();
                });
              },
              activeThumbColor: AppTheme.primaryPurple,
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: 24),
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
      title: 'Wi-Fi Generator',
      subtitle: 'Create a QR code for Wi-Fi network access',
      emptyHint: 'Enter SSID to preview',
      currentQR: _state.currentQR,
      inputCard: _buildInputCard(),
    );
  }
}
