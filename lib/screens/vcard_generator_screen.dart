import 'package:flutter/material.dart';
import '../models/qr_data.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/qr_export_service.dart';
import '../widgets/qr_preview.dart';
import '../widgets/customization_panel.dart';

class VCardGeneratorScreen extends StatefulWidget {
  const VCardGeneratorScreen({super.key});

  @override
  State<VCardGeneratorScreen> createState() => _VCardGeneratorScreenState();
}

class _VCardGeneratorScreenState extends State<VCardGeneratorScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _organizationController = TextEditingController();
  final _websiteController = TextEditingController();

  int _foregroundColor = 0xFF212121;
  int _backgroundColor = 0xFFFFFFFF;
  double _correctionLevel = 0.15;
  String? _frameText;

  VCardQRData? _currentQR;
  bool _isSaved = false;

  bool get hasUnsavedChanges => _currentQR != null && !_isSaved;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _organizationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _generateQR() {
    if (_fullNameController.text.isEmpty) return;
    setState(() {
      _isSaved = false;
      _currentQR = VCardQRData(
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        organization: _organizationController.text,
        website: _websiteController.text,
        foregroundColor: _foregroundColor,
        backgroundColor: _backgroundColor,
        correctionLevel: _correctionLevel,
        frameText: _frameText,
      );
    });
  }

  void loadFromData(QRData data) {
    final fnMatch = RegExp(r'FN:(.+)').firstMatch(data.content);
    final telMatch = RegExp(r'TEL:(.+)').firstMatch(data.content);
    final emailMatch = RegExp(r'EMAIL:(.+)').firstMatch(data.content);
    final orgMatch = RegExp(r'ORG:(.+)').firstMatch(data.content);
    final urlMatch = RegExp(r'URL:(.+)').firstMatch(data.content);

    _fullNameController.text = fnMatch?.group(1) ?? '';
    _phoneController.text = telMatch?.group(1) ?? '';
    _emailController.text = emailMatch?.group(1) ?? '';
    _organizationController.text = orgMatch?.group(1) ?? '';
    _websiteController.text = urlMatch?.group(1) ?? '';
    _foregroundColor = data.foregroundColor;
    _backgroundColor = data.backgroundColor;
    _correctionLevel = data.correctionLevel;
    _frameText = data.frameText;
    setState(() {
      _isSaved = true;
      _currentQR = VCardQRData(
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        organization: _organizationController.text,
        website: _websiteController.text,
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'vCard Generator',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Create a QR code for your contact information',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Details',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            hintText: 'John Doe',
                            prefixIcon: Icon(Icons.person),
                          ),
                          onChanged: (_) => _generateQR(),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            hintText: '+1 234 567 890',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => _generateQR(),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'john@example.com',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => _generateQR(),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _organizationController,
                          decoration: InputDecoration(
                            labelText: 'Organization',
                            hintText: 'Company Name',
                            prefixIcon: Icon(Icons.business),
                          ),
                          onChanged: (_) => _generateQR(),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _websiteController,
                          decoration: InputDecoration(
                            labelText: 'Website',
                            hintText: 'https://example.com',
                            prefixIcon: Icon(Icons.language),
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (_) => _generateQR(),
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
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              'Preview',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 16),
                            _currentQR != null
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
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.qr_code_2,
                                            size: 64,
                                            color: AppTheme.textSecondary
                                                .withValues(alpha: 0.5),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Enter name to preview',
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            SizedBox(height: 16),
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
                                              QrExportService.showSvgExportModal(context, _currentQR!);
                                            },
                                            icon: Icon(Icons.code),
                                            label: Text('SVG'),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          QrExportService.saveAsPng(context, _currentQR!);
                                        },
                                        icon: Icon(Icons.download),
                                        label: Text('PNG'),
                                      ),
                                      SizedBox(width: 12),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          QrExportService.showSvgExportModal(context, _currentQR!);
                                        },
                                        icon: Icon(Icons.code),
                                        label: Text('SVG'),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Card Preview',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 12),
                            if (_fullNameController.text.isNotEmpty)
                              _buildContactCard()
                            else
                              Text(
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
  }

  Widget _buildContactCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_fullNameController.text.isNotEmpty)
            Text(
              _fullNameController.text,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          if (_organizationController.text.isNotEmpty)
            Text(
              _organizationController.text,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          Divider(height: 24),
          if (_phoneController.text.isNotEmpty)
            _buildContactRow(Icons.phone, _phoneController.text),
          if (_emailController.text.isNotEmpty)
            _buildContactRow(Icons.email, _emailController.text),
          if (_websiteController.text.isNotEmpty)
            _buildContactRow(Icons.language, _websiteController.text),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryPurple),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
