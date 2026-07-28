import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../models/qr_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_messages.dart';
import '../services/qr_decoder_service.dart';

enum _UploadState { empty, imageSelected, scanning, decoded, error }

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, required this.onNavigateToTab});

  final void Function(int tabIndex, QRData data, {bool markAsSaved}) onNavigateToTab;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  _UploadState _state = _UploadState.empty;
  Uint8List? _imageBytes;
  String? _fileName;
  String? _blobUrl;
  QRDecoderResult? _decodeResult;
  String? _errorMsg;

  static const int _maxFileSize = 10 * 1024 * 1024;
  static int _viewIdCounter = 0;
  late final int _viewId = _viewIdCounter++;
  late final String _viewType = 'qr-upload-$_viewId';

  static final Map<String, String> _blobUrlCache = {};

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _registerViewFactory();
    }
  }

  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int id) {
      final img = web.document.createElement('img') as web.HTMLImageElement;
      img.id = 'qr-img-$id';
      img.style
        ..width = '100%'
        ..height = '100%'
        ..objectFit = 'contain'
        ..borderRadius = '8px';
      final cachedUrl = _blobUrlCache[_viewType];
      if (cachedUrl != null) {
        img.src = cachedUrl;
      }
      return img;
    });
  }

  void _updatePreview() {
    if (_blobUrl != null) {
      _blobUrlCache[_viewType] = _blobUrl!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final img = web.document.getElementById('qr-img-$_viewId');
        if (img != null) {
          (img as web.HTMLImageElement).src = _blobUrl!;
        }
      });
    }
  }

  String? _createBlobUrl(Uint8List bytes) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/octet-stream'),
    );
    return web.URL.createObjectURL(blob);
  }

  void _disposeBlobUrl() {
    if (_blobUrl != null) {
      web.URL.revokeObjectURL(_blobUrl!);
      _blobUrlCache.remove(_viewType);
      _blobUrl = null;
    }
  }

  @override
  void dispose() {
    _disposeBlobUrl();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.size > _maxFileSize) {
      if (mounted) {
        AppMessages.showError(
          context,
          'Image too large. Maximum size is 10 MB.',
        );
      }
      return;
    }

    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        AppMessages.showError(context, 'Failed to read the image file.');
      }
      return;
    }

    _disposeBlobUrl();
    final url = _createBlobUrl(bytes);

    setState(() {
      _imageBytes = bytes;
      _fileName = file.name;
      _blobUrl = url;
      _state = _UploadState.imageSelected;
      _decodeResult = null;
      _errorMsg = null;
    });
    _updatePreview();
  }

  Future<void> _scanQR() async {
    if (_imageBytes == null) return;

    setState(() => _state = _UploadState.scanning);

    final result = await QRDecoderService.decodeFromBytes(_imageBytes!);

    if (!mounted) return;

    if (result.rawContent.isEmpty &&
        result.errorType == QRDecoderErrorType.noQrFound) {
      setState(() {
        _state = _UploadState.error;
        _errorMsg = 'No QR code detected in the image.';
        _imageBytes = null;
      });
      return;
    }

    if (result.errorType == QRDecoderErrorType.decodeFailed) {
      setState(() {
        _state = _UploadState.error;
        _errorMsg = 'Failed to decode QR code. Please try another image.';
        _imageBytes = null;
      });
      return;
    }

    if (!result.isSupported) {
      setState(() {
        _state = _UploadState.error;
        _errorMsg = 'QR Code format is unsupported.';
        _imageBytes = null;
      });
      return;
    }

    setState(() {
      _state = _UploadState.decoded;
      _decodeResult = result;
      _imageBytes = null;
    });
  }

  void _clearAll() {
    _disposeBlobUrl();
    setState(() {
      _state = _UploadState.empty;
      _imageBytes = null;
      _fileName = null;
      _decodeResult = null;
      _errorMsg = null;
    });
  }

  void _editQR() {
    final data = _decodeResult?.parsedData;
    if (data == null || !mounted) return;

    final tabIndex = _getTabIndex(data.type);
    if (tabIndex == null) {
      AppMessages.showError(context, 'QR Code format is unsupported.');
      return;
    }

    widget.onNavigateToTab(tabIndex, data, markAsSaved: false);
  }

  int? _getTabIndex(QRType type) {
    return type.tabIndex;
  }

  String _formatTypeName(QRType type) {
    return type.typeName;
  }

  IconData _formatIcon(QRType type) {
    return type.typeIcon;
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 200,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.divider,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: AppTheme.primaryPurple.withValues(alpha: 0.7),
            ),
            SizedBox(height: 12),
            Text(
              'Drop image here or click to browse',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 4),
            Text(
              'Supports PNG, JPG, GIF, WEBP',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            height: 200,
            color: AppTheme.backgroundLight,
            child: kIsWeb && _blobUrl != null
                ? HtmlElementView(viewType: _viewType)
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          _fileName ?? '',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildScanResult() {
    final result = _decodeResult!;
    final data = result.parsedData;
    if (data == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.success, size: 20),
              SizedBox(width: 8),
              Text(
                'QR Code Decoded',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _formatIcon(data.type),
                size: 16,
                color: AppTheme.primaryPurple,
              ),
              SizedBox(width: 8),
              Text(
                'Format: ${_formatTypeName(data.type)}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Content:',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Text(
              result.rawContent,
              style: TextStyle(fontSize: 13, fontFamily: 'monospace'),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _editQR,
              icon: Icon(Icons.edit, size: 18),
              label: Text('Edit This QR'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMsg ?? 'An unknown error occurred.',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasImage = _imageBytes != null;
    return Row(
      children: [
        if (_state != _UploadState.empty && _state != _UploadState.scanning)
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _clearAll,
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Clear'),
              ),
            ),
          ),
        if (_state != _UploadState.empty && _state != _UploadState.scanning)
          SizedBox(width: 12),
        if (_state != _UploadState.empty && _state != _UploadState.scanning)
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: hasImage ? _scanQR : null,
                icon: Icon(Icons.qr_code_scanner, size: 18),
                label: Text('Scan & Edit'),
              ),
            ),
          ),
      ],
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
                'Upload & Edit',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Upload a QR code image to decode and edit it',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              SizedBox(height: 24),
              if (stacked)
                Column(children: [_buildMainCard()])
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(flex: 2, child: _buildMainCard())],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload QR Code Image',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            if (_state == _UploadState.empty) _buildUploadZone(),
            if (_state == _UploadState.imageSelected ||
                _state == _UploadState.scanning) ...[
              _buildImagePreview(),
              if (_state == _UploadState.scanning) ...[
                SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      _ThreeDotLoader(),
                      SizedBox(height: 12),
                      Text(
                        'Scanning QR code...',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            if (_state == _UploadState.decoded) ...[
              _buildImagePreview(),
              SizedBox(height: 16),
              _buildScanResult(),
            ],
            if (_state == _UploadState.error) ...[
              _buildImagePreview(),
              SizedBox(height: 16),
              _buildErrorState(),
            ],
            if (_state != _UploadState.empty &&
                _state != _UploadState.scanning) ...[
              SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThreeDotLoader extends StatefulWidget {
  const _ThreeDotLoader();

  @override
  State<_ThreeDotLoader> createState() => _ThreeDotLoaderState();
}

class _ThreeDotLoaderState extends State<_ThreeDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final start = i * 0.2;
            final end = (start + 0.4).clamp(0.0, 1.0);
            final value = Tween<double>(begin: 0.4, end: 1.0).transform(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(start, end, curve: Curves.easeInOut),
              ).value,
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: value,
                child: const CircleAvatar(
                  radius: 5,
                  backgroundColor: AppTheme.primaryPurple,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
