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
    return 'SmsMessage(id: $id, sender: $sender, body: $body, isPhishing: $isPhishing)';
  }
}
