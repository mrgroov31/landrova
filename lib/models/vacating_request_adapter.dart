import 'package:hive/hive.dart';
import 'vacating_request.dart';

class VacatingRequestAdapter extends TypeAdapter<VacatingRequest> {
  @override
  final int typeId = 4;

  @override
  VacatingRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VacatingRequest(
      id: fields[0] as String,
      tenantId: fields[1] as String,
      tenantName: fields[2] as String,
      roomNumber: fields[3] as String,
      vacatingDate: DateTime.parse(fields[4] as String),
      reason: fields[5] as String,
      status: fields[6] as String,
      createdAt: DateTime.parse(fields[7] as String),
      updatedAt: fields[8] != null ? DateTime.parse(fields[8] as String) : null,
      approvedAt: fields[9] != null ? DateTime.parse(fields[9] as String) : null,
      approvedBy: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VacatingRequest obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tenantId)
      ..writeByte(2)
      ..write(obj.tenantName)
      ..writeByte(3)
      ..write(obj.roomNumber)
      ..writeByte(4)
      ..write(obj.vacatingDate.toIso8601String())
      ..writeByte(5)
      ..write(obj.reason)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(8)
      ..write(obj.updatedAt?.toIso8601String())
      ..writeByte(9)
      ..write(obj.approvedAt?.toIso8601String())
      ..writeByte(10)
      ..write(obj.approvedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VacatingRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

