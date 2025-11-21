// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phishing_detection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhishingDetection _$PhishingDetectionFromJson(Map<String, dynamic> json) =>
    PhishingDetection(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      type: $enumDecode(_$PhishingTypeEnumMap, json['type']),
      indicators: (json['indicators'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      reason: json['reason'] as String,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      isFalsePositive: json['isFalsePositive'] as bool? ?? false,
      isUserReported: json['isUserReported'] as bool? ?? false,
    );

Map<String, dynamic> _$PhishingDetectionToJson(PhishingDetection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'messageId': instance.messageId,
      'confidence': instance.confidence,
      'type': _$PhishingTypeEnumMap[instance.type]!,
      'indicators': instance.indicators,
      'reason': instance.reason,
      'detectedAt': instance.detectedAt.toIso8601String(),
      'isFalsePositive': instance.isFalsePositive,
      'isUserReported': instance.isUserReported,
    };

const _$PhishingTypeEnumMap = {
  PhishingType.sms: 'sms',
  PhishingType.url: 'url',
  PhishingType.sender: 'sender',
  PhishingType.content: 'content',
  PhishingType.urgent: 'urgent',
  PhishingType.suspiciousKeywords: 'suspicious_keywords',
};

ThreatMeter _$ThreatMeterFromJson(Map<String, dynamic> json) => ThreatMeter(
  totalDetections: (json['totalDetections'] as num).toInt(),
  weeklyDetections: (json['weeklyDetections'] as num).toInt(),
  monthlyDetections: (json['monthlyDetections'] as num).toInt(),
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  threatLevels: (json['threatLevels'] as List<dynamic>)
      .map((e) => $enumDecode(_$ThreatLevelEnumMap, e))
      .toList(),
);

Map<String, dynamic> _$ThreatMeterToJson(ThreatMeter instance) =>
    <String, dynamic>{
      'totalDetections': instance.totalDetections,
      'weeklyDetections': instance.weeklyDetections,
      'monthlyDetections': instance.monthlyDetections,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'threatLevels': instance.threatLevels
          .map((e) => _$ThreatLevelEnumMap[e]!)
          .toList(),
    };

const _$ThreatLevelEnumMap = {
  ThreatLevel.low: 'low',
  ThreatLevel.medium: 'medium',
  ThreatLevel.high: 'high',
  ThreatLevel.critical: 'critical',
};

PhishingSignature _$PhishingSignatureFromJson(Map<String, dynamic> json) =>
    PhishingSignature(
      hash: json['hash'] as String,
      messageId: json['messageId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isConfirmed: json['isConfirmed'] as bool? ?? false,
      reportCount: (json['reportCount'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$PhishingSignatureToJson(PhishingSignature instance) =>
    <String, dynamic>{
      'hash': instance.hash,
      'messageId': instance.messageId,
      'createdAt': instance.createdAt.toIso8601String(),
      'isConfirmed': instance.isConfirmed,
      'reportCount': instance.reportCount,
    };
