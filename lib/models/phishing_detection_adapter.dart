import 'package:hive/hive.dart';
import 'phishing_detection.dart';

class PhishingDetectionAdapter extends TypeAdapter<PhishingDetection> {
  @override
  final int typeId = 1;

  @override
  PhishingDetection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhishingDetection(
      id: fields[0] as String,
      messageId: fields[1] as String,
      confidence: fields[2] as double,
      type: fields[3] as String,
      indicators: (fields[4] as List).cast<String>(),
      reason: fields[5] as String,
      detectedAt: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
      isFalsePositive: fields[7] as bool,
      isUserReported: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PhishingDetection obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.messageId)
      ..writeByte(2)
      ..write(obj.confidence)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.indicators)
      ..writeByte(5)
      ..write(obj.reason)
      ..writeByte(6)
      ..write(obj.detectedAt.millisecondsSinceEpoch)
      ..writeByte(7)
      ..write(obj.isFalsePositive)
      ..writeByte(8)
      ..write(obj.isUserReported);
  }
}
