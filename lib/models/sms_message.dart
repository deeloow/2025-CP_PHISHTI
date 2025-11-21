import 'package:json_annotation/json_annotation.dart';

part 'sms_message.g.dart';

@JsonSerializable()
class SmsMessage {
  final String id;
  final String sender;
  final String body;
  final DateTime timestamp;
  final bool isPhishing;
  final double phishingScore;
  final List<String> extractedUrls;
  final String? signature; // Hashed fingerprint for cloud sync
  final bool isArchived;
  final bool isWhitelisted;
  final DateTime? archivedAt;
  final String? reason; // Why it was flagged as phishing
  final String? threadId; // SMS thread/conversation ID
  final bool isRead; // Whether the message has been read
  final MessageType messageType; // SMS or MMS
  final String? contactName; // Contact name if available
  
  // User Analysis/Classification fields
  final UserClassification? userClassification; // User's manual classification
  final DateTime? analyzedAt; // When user analyzed the message
  final String? userNotes; // User's notes about the message
  final bool needsUserReview; // Whether message needs user analysis
  final List<String> userTags; // User-defined tags for categorization

  const SmsMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.timestamp,
    this.isPhishing = false,
    this.phishingScore = 0.0,
    this.extractedUrls = const [],
    this.signature,
    this.isArchived = false,
    this.isWhitelisted = false,
    this.archivedAt,
    this.reason,
    this.threadId,
    this.isRead = false,
    this.messageType = MessageType.sms,
    this.contactName,
    this.userClassification,
    this.analyzedAt,
    this.userNotes,
    this.needsUserReview = false,
    this.userTags = const [],
  });

  factory SmsMessage.fromJson(Map<String, dynamic> json) =>
      _$SmsMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SmsMessageToJson(this);

  SmsMessage copyWith({
    String? id,
    String? sender,
    String? body,
    DateTime? timestamp,
    bool? isPhishing,
    double? phishingScore,
    List<String>? extractedUrls,
    String? signature,
    bool? isArchived,
    bool? isWhitelisted,
    DateTime? archivedAt,
    String? reason,
    String? threadId,
    bool? isRead,
    MessageType? messageType,
    String? contactName,
    UserClassification? userClassification,
    DateTime? analyzedAt,
    String? userNotes,
    bool? needsUserReview,
    List<String>? userTags,
  }) {
    return SmsMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isPhishing: isPhishing ?? this.isPhishing,
      phishingScore: phishingScore ?? this.phishingScore,
      extractedUrls: extractedUrls ?? this.extractedUrls,
      signature: signature ?? this.signature,
      isArchived: isArchived ?? this.isArchived,
      isWhitelisted: isWhitelisted ?? this.isWhitelisted,
      archivedAt: archivedAt ?? this.archivedAt,
      reason: reason ?? this.reason,
      threadId: threadId ?? this.threadId,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      contactName: contactName ?? this.contactName,
      userClassification: userClassification ?? this.userClassification,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      userNotes: userNotes ?? this.userNotes,
      needsUserReview: needsUserReview ?? this.needsUserReview,
      userTags: userTags ?? this.userTags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SmsMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SmsMessage(id: $id, sender: $sender, body: $body, isPhishing: $isPhishing, userClassification: $userClassification)';
  }
}

/// Message type enum
enum MessageType {
  sms,
  mms,
}

/// User classification enum for manual message analysis
enum UserClassification {
  legitimate,    // User confirmed as legitimate
  phishing,      // User confirmed as phishing
  suspicious,    // User marked as suspicious but not confirmed phishing
  spam,          // User marked as spam
  unknown,       // User marked as unknown/needs more analysis
}
