import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum QRType { url, vcard, wifi, text }

extension QRTypeHelpers on QRType {
  int get tabIndex {
    switch (this) {
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

  String get typeName {
    switch (this) {
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

  IconData get typeIcon {
    switch (this) {
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
}

class QRData {
  final String id;
  final QRType type;
  final String title;
  final String content;
  final DateTime createdAt;
  final int foregroundColor;
  final int backgroundColor;
  final double correctionLevel;
  final String? logoPath;
  final String? frameText;

  QRData({
    String? id,
    required this.type,
    required this.title,
    required this.content,
    DateTime? createdAt,
    this.foregroundColor = 0xFF212121,
    this.backgroundColor = 0xFFFFFFFF,
    this.correctionLevel = 0.15,
    this.logoPath,
    this.frameText,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'foregroundColor': foregroundColor,
      'backgroundColor': backgroundColor,
      'correctionLevel': correctionLevel,
      'logoPath': logoPath,
      'frameText': frameText,
    };
  }

  factory QRData.fromJson(Map<String, dynamic> json) {
    return QRData(
      id: json['id'] as String,
      type: QRType.values[json['type'] as int],
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      foregroundColor: json['foregroundColor'] as int,
      backgroundColor: json['backgroundColor'] as int,
      correctionLevel: (json['correctionLevel'] as num).toDouble(),
      logoPath: json['logoPath'] as String?,
      frameText: json['frameText'] as String?,
    );
  }

  QRData copyWith({
    String? title,
    String? content,
    int? foregroundColor,
    int? backgroundColor,
    double? correctionLevel,
    String? logoPath,
    String? frameText,
  }) {
    return QRData(
      id: id,
      type: type,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      correctionLevel: correctionLevel ?? this.correctionLevel,
      logoPath: logoPath ?? this.logoPath,
      frameText: frameText ?? this.frameText,
    );
  }

  static QRType? detectType(String content) {
    if (content.isEmpty) return null;

    if (content.toUpperCase().startsWith('BEGIN:VCARD')) return QRType.vcard;
    if (content.toUpperCase().startsWith('WIFI:')) return QRType.wifi;

    final urlPattern = RegExp(
      r'^(https?://|www\.)',
      caseSensitive: false,
    );
    if (urlPattern.hasMatch(content)) return QRType.url;

    return QRType.text;
  }
}

class URLQRData extends QRData {
  final String url;
  final bool isDynamicShortLink;

  URLQRData({
    required this.url,
    this.isDynamicShortLink = false,
    super.foregroundColor,
    super.backgroundColor,
    super.correctionLevel,
    super.logoPath,
    super.frameText,
  }) : super(
          type: QRType.url,
          title: 'URL',
          content: url,
        );

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()..addAll({
      'url': url,
      'isDynamicShortLink': isDynamicShortLink,
    });
  }
}

class VCardQRData extends QRData {
  final String fullName;
  final String phone;
  final String email;
  final String organization;
  final String website;

  VCardQRData({
    required this.fullName,
    this.phone = '',
    this.email = '',
    this.organization = '',
    this.website = '',
    super.foregroundColor,
    super.backgroundColor,
    super.correctionLevel,
    super.logoPath,
    super.frameText,
  }) : super(
          type: QRType.vcard,
          title: 'vCard',
          content: _generateVCard(fullName, phone, email, organization, website),
        );

  static String _generateVCard(
    String fullName,
    String phone,
    String email,
    String organization,
    String website,
  ) {
    final nameParts = fullName.split(' ');
    final lastName = nameParts.isNotEmpty ? nameParts.last : '';
    final firstName = nameParts.length > 1 ? nameParts.sublist(0, nameParts.length - 1).join(' ') : fullName;

    return '''BEGIN:VCARD
VERSION:3.0
N:$lastName;$firstName;;;
FN:$fullName
ORG:$organization
TEL:$phone
EMAIL:$email
URL:$website
END:VCARD''';
  }
}

class WiFiQRData extends QRData {
  final String ssid;
  final String password;
  final String encryptionType;
  final bool isHidden;

  WiFiQRData({
    required this.ssid,
    this.password = '',
    this.encryptionType = 'WPA',
    this.isHidden = false,
    super.foregroundColor,
    super.backgroundColor,
    super.correctionLevel,
    super.logoPath,
    super.frameText,
  }) : super(
          type: QRType.wifi,
          title: 'Wi-Fi',
          content: _generateWiFi(ssid, password, encryptionType, isHidden),
        );

  static String _generateWiFi(
    String ssid,
    String password,
    String encryptionType,
    bool isHidden,
  ) {
    final hiddenStr = isHidden ? 'H:true;' : '';
    return 'WIFI:T:$encryptionType;S:$ssid;P:$password;$hiddenStr';
  }
}

class TextQRData extends QRData {
  final String text;
  final int charCount;

  TextQRData({
    required this.text,
    super.foregroundColor,
    super.backgroundColor,
    super.correctionLevel,
    super.logoPath,
    super.frameText,
  })  : charCount = text.length,
        super(
          type: QRType.text,
          title: 'Text',
          content: text,
        );
}
