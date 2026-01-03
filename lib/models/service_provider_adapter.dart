import 'package:hive/hive.dart';
import 'service_provider.dart';

class ServiceProviderAdapter extends TypeAdapter<ServiceProvider> {
  @override
  final int typeId = 0;

  @override
  ServiceProvider read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceProvider(
      id: fields[0] as String,
      name: fields[1] as String,
      serviceType: fields[2] as String,
      phone: fields[3] as String,
      email: fields[4] as String?,
      rating: fields[5] as double? ?? 0.0,
      totalJobs: fields[6] as int? ?? 0,
      address: fields[7] as String?,
      specialties: (fields[8] as List?)?.cast<String>() ?? [],
      isAvailable: fields[9] as bool? ?? true,
      image: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceProvider obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.serviceType)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.rating)
      ..writeByte(6)
      ..write(obj.totalJobs)
      ..writeByte(7)
      ..write(obj.address)
      ..writeByte(8)
      ..write(obj.specialties)
      ..writeByte(9)
      ..write(obj.isAvailable)
      ..writeByte(10)
      ..write(obj.image);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceProviderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

