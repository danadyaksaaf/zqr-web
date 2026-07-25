import 'dart:async';
import 'package:flutter/material.dart';
import '../models/qr_data.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/qr_export_service.dart';
import '../widgets/qr_preview.dart';

class HistoryScreen extends StatefulWidget {
  final void Function(int tabIndex, QRData data, {bool markAsSaved}) onNavigateToTab;

  const HistoryScreen({super.key, required this.onNavigateToTab});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<QRData> _history = [];
  String _filterType = 'all';
  StreamSubscription<List<QRData>>? _historySubscription;

  @override
  void initState() {
    super.initState();
    _history = _historyService.history;
    _historySubscription = _historyService.historyStream.listen((data) {
      if (mounted) {
        setState(() => _history = data);
      }
    });
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }

  List<QRData> get _filteredHistory {
    if (_filterType == 'all') return _history;
    return _history.where((item) => item.type.name == _filterType).toList();
  }

  int _tabIndexForType(QRType type) {
    switch (type) {
      case QRType.text:
        return 0;
      case QRType.url:
        return 1;
      case QRType.vcard:
        return 2;
      case QRType.wifi:
        return 3;
    }
  }

  void _navigateToGenerator(QRData item) {
    widget.onNavigateToTab(_tabIndexForType(item.type), item);
  }

  void _deleteItem(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete QR Code'),
        content: Text('Are you sure you want to delete this QR code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _historyService.removeItem(id);
              if (mounted) Navigator.pop(this.context);
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear History'),
        content: Text('Are you sure you want to clear all history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _historyService.clear();
              if (mounted) Navigator.pop(this.context);
            },
            child: Text('Clear All', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(QRData item) {
    switch (item.type) {
      case QRType.url:
        return item.content;
      case QRType.vcard:
        final fnMatch = RegExp(r'FN:(.+)').firstMatch(item.content);
        return fnMatch != null ? fnMatch.group(1)! : item.content;
      case QRType.wifi:
        final ssidMatch = RegExp(r'S:([^;]+)').firstMatch(item.content);
        return ssidMatch != null ? ssidMatch.group(1)! : item.content;
      case QRType.text:
        return item.content;
    }
  }

  String _getTypeName(QRType type) {
    switch (type) {
      case QRType.url:
        return 'URL';
      case QRType.vcard:
        return 'vCard';
      case QRType.wifi:
        return 'Wi-Fi';
      case QRType.text:
        return 'Text';
    }
  }

  IconData _getTypeIcon(QRType type) {
    switch (type) {
      case QRType.url:
        return Icons.link;
      case QRType.vcard:
        return Icons.badge;
      case QRType.wifi:
        return Icons.wifi;
      case QRType.text:
        return Icons.text_fields;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'History',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Manage your previously generated QR codes',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),
              if (_history.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All'),
                            _buildFilterChip('url', 'URL'),
                            _buildFilterChip('vcard', 'vCard'),
                            _buildFilterChip('wifi', 'Wi-Fi'),
                            _buildFilterChip('text', 'Text'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _clearAll,
                      icon: Icon(Icons.delete_sweep, size: 18),
                      label: Text('Clear All'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: _filteredHistory.isEmpty
              ? Card(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            _history.isEmpty
                                ? 'No QR codes generated yet'
                                : 'No items match the filter',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = (constraints.maxWidth / 200)
                        .floor()
                        .clamp(2, 10);
                    return GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.0,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      itemCount: _filteredHistory.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(_filteredHistory[index]);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterType == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterType = value);
        },
        selectedColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.primaryPurple,
      ),
    );
  }

  Widget _buildHistoryCard(QRData item) {
    return GestureDetector(
      onTap: () => _navigateToGenerator(item),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getTypeIcon(item.type),
                        size: 16,
                        color: AppTheme.primaryPurple,
                      ),
                      SizedBox(width: 6),
                      Text(
                        _getTypeName(item.type),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPurple,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: Icon(Icons.more_vert, size: 20),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'svg',
                        child: Row(
                          children: [
                            Icon(Icons.code, size: 20),
                            SizedBox(width: 8),
                            Text('Download as SVG'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'png',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 20),
                            SizedBox(width: 8),
                            Text('Download as PNG'),
                          ],
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppTheme.error, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppTheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'details':
                          _navigateToGenerator(item);
                          break;
                        case 'svg':
                          QrExportService.showSvgExportModal(context, item);
                          break;
                        case 'png':
                          QrExportService.saveAsPng(context, item);
                          break;
                        case 'delete':
                          _deleteItem(item.id);
                          break;
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: QRPreviewWidget(qrData: item, showFrame: false),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                _getDisplayName(item),
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                _formatDate(item.createdAt),
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
