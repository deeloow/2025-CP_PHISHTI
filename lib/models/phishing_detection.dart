import 'package:json_annotation/json_annotation.dart';

part 'phishing_detection.g.dart';

@JsonSerializable()
class PhishingDetection {
  final String id;
  final String messageId;
  final double confidence;
  final PhishingType type;
  final List<String> indicators;
  final String reason;
  final DateTime detectedAt;
  final bool isFalsePositive;
  final bool isUserReported;

  const PhishingDetection({
    required this.id,
    required this.messageId,
    required this.confidence,
    required this.type,
    required this.indicators,
    required this.reason,
    required this.detectedAt,
    this.isFalsePositive = false,
    this.isUserReported = false,
  });

  factory PhishingDetection.fromJson(Map<String, dynamic> json) =>
      _$PhishingDetectionFromJson(json);

  Map<String, dynamic> toJson() => _$PhishingDetectionToJson(this);

  /// Check if this detection indicates phishing/spam
  bool get isPhishing => confidence > 0.5;

  PhishingDetection copyWith({
    String? id,
    String? messageId,
    double? confidence,
    PhishingType? type,
    List<String>? indicators,
    String? reason,
    DateTime? detectedAt,
    bool? isFalsePositive,
    bool? isUserReported,
  }) {
    return PhishingDetection(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      confidence: confidence ?? this.confidence,
      type: type ?? this.type,
      indicators: indicators ?? this.indicators,
      reason: reason ?? this.reason,
      detectedAt: detectedAt ?? this.detectedAt,
      isFalsePositive: isFalsePositive ?? this.isFalsePositive,
      isUserReported: isUserReported ?? this.isUserReported,
    );
  }
}

enum PhishingType {
  @JsonValue('sms')
  sms,
  @JsonValue('url')
  url,
  @JsonValue('sender')
  sender,
  @JsonValue('content')
  content,
  @JsonValue('urgent')
  urgent,
  @JsonValue('suspicious_keywords')
  suspiciousKeywords,
}

@JsonSerializable()
class ThreatMeter {
  final int totalDetections;
  final int weeklyDetections;
  final int monthlyDetections;
  final DateTime lastUpdated;
  final List<ThreatLevel> threatLevels;

  const ThreatMeter({
    required this.totalDetections,
    required this.weeklyDetections,
    required this.monthlyDetections,
    required this.lastUpdated,
    required this.threatLevels,
  });

  factory ThreatMeter.fromJson(Map<String, dynamic> json) =>
      _$ThreatMeterFromJson(json);

  Map<String, dynamic> toJson() => _$ThreatMeterToJson(this);

  ThreatLevel get currentLevel {
    if (weeklyDetections >= 10) return ThreatLevel.critical;
    if (weeklyDetections >= 5) return ThreatLevel.high;
    if (weeklyDetections >= 2) return ThreatLevel.medium;
    return ThreatLevel.low;
  }
}

enum ThreatLevel {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

@JsonSerializable()
class PhishingSignature {
  final String hash;
  final String messageId;
  final DateTime createdAt;
  final bool isConfirmed;
  final int reportCount;

  const PhishingSignature({
    required this.hash,
    required this.messageId,
    required this.createdAt,
    this.isConfirmed = false,
    this.reportCount = 1,
  });

  factory PhishingSignature.fromJson(Map<String, dynamic> json) =>
      _$PhishingSignatureFromJson(json);

  Map<String, dynamic> toJson() => _$PhishingSignatureToJson(this);

  PhishingSignature copyWith({
    String? hash,
    String? messageId,
    DateTime? createdAt,
    bool? isConfirmed,
    int? reportCount,
  }) {
    return PhishingSignature(
      hash: hash ?? this.hash,
      messageId: messageId ?? this.messageId,
      createdAt: createdAt ?? this.createdAt,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      reportCount: reportCount ?? this.reportCount,
    );
  }
}
