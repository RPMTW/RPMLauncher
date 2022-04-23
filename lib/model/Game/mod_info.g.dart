// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mod_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ModInfoAdapter extends TypeAdapter<ModInfo> {
  @override
  final int typeId = 3;

  @override
  ModInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModInfo(
      loader: fields[0] as ModLoader,
      name: fields[1] as String,
      description: fields[2] as String?,
      version: fields[3] as String?,
      curseID: fields[4] as int?,
      conflicts: (fields[5] as List).cast<ConflictMod>(),
      namespace: fields[6] as String,
      murmur2Hash: fields[7] as int,
      md5Hash: fields[8] as String,
      lastUpdate: fields[9] as DateTime?,
      needsUpdate: fields[10] as bool,
      lastUpdateData: (fields[11] as Map?)?.cast<dynamic, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ModInfo obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.loader)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.version)
      ..writeByte(4)
      ..write(obj.curseID)
      ..writeByte(5)
      ..write(obj.conflicts)
      ..writeByte(6)
      ..write(obj.namespace)
      ..writeByte(7)
      ..write(obj.murmur2Hash)
      ..writeByte(8)
      ..write(obj.md5Hash)
      ..writeByte(9)
      ..write(obj.lastUpdate)
      ..writeByte(10)
      ..write(obj.needsUpdate)
      ..writeByte(11)
      ..write(obj.lastUpdateData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConflictModAdapter extends TypeAdapter<ConflictMod> {
  @override
  final int typeId = 2;

  @override
  ConflictMod read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConflictMod(
      namespace: fields[0] as String,
      versionID: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ConflictMod obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.namespace)
      ..writeByte(1)
      ..write(obj.versionID);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConflictModAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
