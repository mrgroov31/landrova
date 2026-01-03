import 'package:hive/hive.dart';
import 'tenant.dart';

class TenantAdapter extends TypeAdapter<Tenant> {
  @override
  final int typeId = 2;

  @override
  Tenant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tenant(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      email: fields[3] as String,
      roomNumber: fields[4] as String,
      moveInDate: DateTime.parse(fields[5] as String),
      monthlyRent: (fields[6] as num).toDouble(),
      type: fields[7] as String,
      isActive: fields[8] as bool? ?? true,
      aadharNumber: fields[9] as String?,
      emergencyContact: fields[10] as String?,
      occupation: fields[11] as String?,
      profileImage: fields[12] as String?,
      aadharFrontImage: fields[13] as String?,
      aadharBackImage: fields[14] as String?,
      panCardImage: fields[15] as String?,
      addressProofImage: fields[16] as String?,
      invitationToken: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Tenant obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.roomNumber)
      ..writeByte(5)
      ..write(obj.moveInDate.toIso8601String())
      ..writeByte(6)
      ..write(obj.monthlyRent)
      ..writeByte(7)
      ..write(obj.type)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.aadharNumber)
      ..writeByte(10)
      ..write(obj.emergencyContact)
      ..writeByte(11)
      ..write(obj.occupation)
      ..writeByte(12)
      ..write(obj.profileImage)
      ..writeByte(13)
      ..write(obj.aadharFrontImage)
      ..writeByte(14)
      ..write(obj.aadharBackImage)
      ..writeByte(15)
      ..write(obj.panCardImage)
      ..writeByte(16)
      ..write(obj.addressProofImage)
      ..writeByte(17)
      ..write(obj.invitationToken);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TenantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

