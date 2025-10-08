import 'package:hive/hive.dart';
import 'sms_message.dart';

class SmsMessageAdapter extends TypeAdapter<SmsMessage> {
  @override
  final int typeId = 0;

  @override
  SmsMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmsMessage(
      id: fields[0] as String,
      sender: fields[1] as String,
      body: fields[2] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      isPhishing: fields[4] as bool,
      phishingScore: fields[5] as double,
      extractedUrls: (fields[6] as List).cast<String>(),
      signature: fields[7] as String?,
      isArchived: fields[8] as bool,
      isWhitelisted: fields[9] as bool,
      archivedAt: fields[10] != null ? DateTime.fromMillisecondsSinceEpoch(fields[10] as int) : null,
      reason: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SmsMessage obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sender)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.timestamp.millisecondsSinceEpoch)
      ..writeByte(4)
      ..write(obj.isPhishing)
      ..writeByte(5)
      ..write(obj.phishingScore)
      ..writeByte(6)
      ..write(obj.extractedUrls)
      ..writeByte(7)
      ..write(obj.signature)
      ..writeByte(8)
      ..write(obj.isArchived)
      ..writeByte(9)
      ..write(obj.isWhitelisted)
      ..writeByte(10)
      ..write(obj.archivedAt?.millisecondsSinceEpoch)
      ..writeByte(11)
      ..write(obj.reason);
  }
}
