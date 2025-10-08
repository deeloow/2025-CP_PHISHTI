// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SmsMessage _$SmsMessageFromJson(Map<String, dynamic> json) => SmsMessage(
  id: json['id'] as String,
  sender: json['sender'] as String,
  body: json['body'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  isPhishing: json['isPhishing'] as bool? ?? false,
  phishingScore: (json['phishingScore'] as num?)?.toDouble() ?? 0.0,
  extractedUrls:
      (json['extractedUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  signature: json['signature'] as String?,
  isArchived: json['isArchived'] as bool? ?? false,
  isWhitelisted: json['isWhitelisted'] as bool? ?? false,
  archivedAt: json['archivedAt'] == null
      ? null
      : DateTime.parse(json['archivedAt'] as String),
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$SmsMessageToJson(SmsMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender': instance.sender,
      'body': instance.body,
      'timestamp': instance.timestamp.toIso8601String(),
      'isPhishing': instance.isPhishing,
      'phishingScore': instance.phishingScore,
      'extractedUrls': instance.extractedUrls,
      'signature': instance.signature,
      'isArchived': instance.isArchived,
      'isWhitelisted': instance.isWhitelisted,
      'archivedAt': instance.archivedAt?.toIso8601String(),
      'reason': instance.reason,
    };
