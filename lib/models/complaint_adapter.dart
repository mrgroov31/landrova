import 'package:hive/hive.dart';
import 'complaint.dart';

class ComplaintAdapter extends TypeAdapter<Complaint> {
  @override
  final int typeId = 1;

  @override
  Complaint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Complaint(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      roomNumber: fields[3] as String,
      tenantId: fields[4] as String,
      tenantName: fields[5] as String,
      status: fields[6] as String,
      createdAt: DateTime.parse(fields[7] as String),
      updatedAt: DateTime.parse(fields[8] as String),
      resolvedAt: fields[9] != null ? DateTime.parse(fields[9] as String) : null,
      priority: fields[10] as String,
      category: fields[11] as String?,
      assignedTo: fields[12] as String?,
      serviceProviderId: fields[13] as String?,
      images: (fields[14] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Complaint obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.roomNumber)
      ..writeByte(4)
      ..write(obj.tenantId)
      ..writeByte(5)
      ..write(obj.tenantName)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(8)
      ..write(obj.updatedAt.toIso8601String())
      ..writeByte(9)
      ..write(obj.resolvedAt?.toIso8601String())
      ..writeByte(10)
      ..write(obj.priority)
      ..writeByte(11)
      ..write(obj.category)
      ..writeByte(12)
      ..write(obj.assignedTo)
      ..writeByte(13)
      ..write(obj.serviceProviderId)
      ..writeByte(14)
      ..write(obj.images);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplaintAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

