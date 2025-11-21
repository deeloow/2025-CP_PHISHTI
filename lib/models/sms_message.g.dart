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
  threadId: json['threadId'] as String?,
  isRead: json['isRead'] as bool? ?? false,
  messageType:
      $enumDecodeNullable(_$MessageTypeEnumMap, json['messageType']) ??
      MessageType.sms,
  contactName: json['contactName'] as String?,
  userClassification: $enumDecodeNullable(
    _$UserClassificationEnumMap,
    json['userClassification'],
  ),
  analyzedAt: json['analyzedAt'] == null
      ? null
      : DateTime.parse(json['analyzedAt'] as String),
  userNotes: json['userNotes'] as String?,
  needsUserReview: json['needsUserReview'] as bool? ?? false,
  userTags:
      (json['userTags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
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
      'threadId': instance.threadId,
      'isRead': instance.isRead,
      'messageType': _$MessageTypeEnumMap[instance.messageType]!,
      'contactName': instance.contactName,
      'userClassification':
          _$UserClassificationEnumMap[instance.userClassification],
      'analyzedAt': instance.analyzedAt?.toIso8601String(),
      'userNotes': instance.userNotes,
      'needsUserReview': instance.needsUserReview,
      'userTags': instance.userTags,
    };

const _$MessageTypeEnumMap = {MessageType.sms: 'sms', MessageType.mms: 'mms'};

const _$UserClassificationEnumMap = {
  UserClassification.legitimate: 'legitimate',
  UserClassification.phishing: 'phishing',
  UserClassification.suspicious: 'suspicious',
  UserClassification.spam: 'spam',
  UserClassification.unknown: 'unknown',
};
